import asyncio
import aiohttp
import ssl
import os
import time
import random
from datetime import datetime
import pdfplumber
import re
from typing import Dict, List, Optional
import logging
import torch
import numpy as np
import nest_asyncio
import warnings
import nltk
from nltk.tokenize import sent_tokenize
from playwright.async_api import async_playwright
from transformers import AutoTokenizer, AutoModelForSequenceClassification

# Configuration setup
nest_asyncio.apply()
warnings.filterwarnings("ignore", category=RuntimeWarning)

logging.basicConfig(
    level=print,  # Using "print" as level to mimic the desired output
    format="%(asctime)s - %(levelname)s - %(message)s"
)

class FinBERTAnalyzer:
    def __init__(self):
        """
        Initialize the FinBERT model and tokenizer.
        This class handles loading the model for sentiment analysis
        and providing a function to analyze text using FinBERT.
        """
        try:
            self.tokenizer = AutoTokenizer.from_pretrained("ProsusAI/finbert")
            self.model = AutoModelForSequenceClassification.from_pretrained("ProsusAI/finbert")
            self.device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
            self.model.to(self.device)
            print(f"FinBERT model loaded successfully (using {self.device})")
        except Exception as e:
            print(f"Error loading FinBERT model: {str(e)}")
            raise

        # Ensure NLTK punkt tokenizer is available
        try:
            nltk.data.find("tokenizers/punkt")
        except LookupError:
            nltk.download("punkt")

    def analyze_sentiment(self, text: str, chunk_size: int = 512) -> Dict[str, float or List[str]]:
        """
        Analyze sentiment of text using FinBERT.
        Splits the text into sentences, and for each sentence, uses the FinBERT
        model to predict the sentiment. Returns a dictionary that contains
        sentiment percentages and sample statements for each sentiment category.
        """
        try:
            sentences = sent_tokenize(text)
            sentiments = {"positive": 0, "negative": 0, "neutral": 0}
            insights = {"positive": [], "negative": [], "neutral": []}

            for sentence in sentences:
                inputs = self.tokenizer(
                    sentence, return_tensors="pt", truncation=True, max_length=chunk_size, padding=True
                )
                inputs = {key: val.to(self.device) for key, val in inputs.items()}

                with torch.no_grad():
                    outputs = self.model(**inputs)
                    predictions = torch.nn.functional.softmax(outputs.logits, dim=-1)
                    sentiment_scores = predictions[0].cpu().numpy()

                sentiment_idx = np.argmax(sentiment_scores)
                # Updated mapping for FinBERT to use the desired order; modify as needed
                sentiment_label = ["positive", "negative", "neutral"][sentiment_idx]
                sentiments[sentiment_label] += 1
                insights[sentiment_label].append(sentence)

            total = sum(sentiments.values())
            sentiment_percentages = (
                {k: round((v / total) * 100, 2) for k, v in sentiments.items()}
                if total > 0
                else {k: 0 for k in sentiments.keys()}
            )

            return {"percentages": sentiment_percentages, "insights": insights}
        except Exception as e:
            print(f"Error in sentiment analysis: {str(e)}")
            return {"percentages": {"positive": 0, "negative": 0, "neutral": 0}, "insights": {}}

class BuySellAnalyzer:
    def __init__(self):
        """
        Initialize the BuySell model and tokenizer.
        This class is responsible for loading the fine-tuned model that predicts
        whether to Buy, remain Neutral, or Sell based on a given text.
        """
        try:
            self.tokenizer = AutoTokenizer.from_pretrained("incredible45/News-Sentimental-model-Buy-Neutral-Sell")
            self.model = AutoModelForSequenceClassification.from_pretrained("incredible45/News-Sentimental-model-Buy-Neutral-Sell")
            self.device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
            self.model.to(self.device)
            print(f"BuySell model loaded successfully (using {self.device})")
        except Exception as e:
            print(f"Error loading BuySell model: {str(e)}")
            raise

    def predict_action(self, text: str, chunk_size: int = 512) -> str:
        """
        Predict the market action (Buy, Neutral, or Sell) based on the given text.
        """
        try:
            inputs = self.tokenizer(text, return_tensors="pt", truncation=True, max_length=chunk_size, padding=True)
            inputs = {k: v.to(self.device) for k, v in inputs.items()}
            with torch.no_grad():
                outputs = self.model(**inputs)
                predictions = torch.nn.functional.softmax(outputs.logits, dim=-1)
            pred_idx = int(torch.argmax(predictions, dim=-1).item())
            # Mapping index to action: adjust the order if needed.
            mapping = {0: "Buy", 1: "Neutral", 2: "Sell"}
            return mapping.get(pred_idx, "Neutral")
        except Exception as e:
            print(f"Error in BuySell prediction: {str(e)}")
            return "Neutral"

class PDFAnalyzer:
    def __init__(self, base_url: str, output_dir: str = "pdfs"):
        """
        Responsible for scraping PDF links from a given base URL, downloading the PDFs,
        extracting key sections, performing sentiment analysis with FinBERT, and
        predicting market actions with the BuySell model.
        """
        self.base_url = base_url
        self.output_dir = output_dir
        self.results: List[Dict] = []
        self.finbert = FinBERTAnalyzer()
        self.buy_sell_analyzer = BuySellAnalyzer()  # Instantiate the BuySell model
        self.session: Optional[aiohttp.ClientSession] = None
        os.makedirs(output_dir, exist_ok=True)

    async def create_session(self):
        """
        Create the aiohttp.ClientSession with a custom SSL context (disabling certificate checks)
        and setting common request headers.
        """
        if not self.session:
            ssl_context = ssl.create_default_context()
            ssl_context.check_hostname = False
            ssl_context.verify_mode = ssl.CERT_NONE

            connector = aiohttp.TCPConnector(ssl=ssl_context)
            self.session = aiohttp.ClientSession(
                connector=connector,
                headers={
                    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
                    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
                    "Accept-Language": "en-US,en;q=0.5",
                    "Connection": "keep-alive",
                }
            )

    async def close_session(self):
        """
        Close the aiohttp session if it has been created.
        """
        if self.session:
            await self.session.close()
            self.session = None

    async def scrape_names(self) -> List[str]:
        """
        Dynamically scrape company names from the annual reports list at self.base_url.
        """
        names = []
        async with async_playwright() as p:
            browser = await p.chromium.launch()
            page = await browser.new_page()
            await page.goto(self.base_url)

            # Wait for the annual reports list to load
            await page.wait_for_selector('#annual-reports-list')

            names = await page.evaluate('''() => {
                const elements = document.querySelectorAll('#annual-reports-list ul.items li strong');
                return Array.from(elements).map(el => el.textContent.trim());
            }''')

            await browser.close()

        return names

    async def scrape_links(self) -> List[str]:
        """
        Use Playwright to navigate to self.base_url and scrape the first few PDF links
        within a specific section of the page.
        """
        pdf_links = []
        async with async_playwright() as p:
            browser = await p.chromium.launch(headless=True)
            context = await browser.new_context()
            page = await context.new_page()

            await page.goto(self.base_url)
            await page.wait_for_selector("body > main > div:nth-of-type(2)")

            outer_body = await page.query_selector("body > main > div:nth-of-type(2)")
            if outer_body:
                inner_section = await outer_body.query_selector("div:nth-of-type(2)")
                if inner_section:
                    # Grab PDFs from a certain slice, e.g. indices 5 to 9 (5:10)
                    links = await inner_section.query_selector_all("ul a[href$='.pdf']")
                    for link in links[5:10]:
                        url = await link.get_attribute("href")
                        if url:
                            pdf_links.append(url)

            await browser.close()

        return pdf_links

    async def download_pdf(self, url: str, retries: int = 3) -> Optional[str]:
        """
        Download a PDF from the specified URL and save it to the output directory.
        Includes retry logic and simple rate limiting.
        """
        if not self.session:
            await self.create_session()

        filename = f"{datetime.now().strftime('%Y%m%d_%H%M%S')}_{url.split('/')[-1]}"
        filepath = os.path.join(self.output_dir, filename)

        for attempt in range(retries):
            try:
                async with self.session.get(url) as response:
                    if response.status == 200:
                        with open(filepath, "wb") as f:
                            while True:
                                chunk = await response.content.read(8192)
                                if not chunk:
                                    break
                                f.write(chunk)
                        print(f"Successfully downloaded: {filename}")
                        return filepath
                    elif response.status == 503 and attempt < retries - 1:
                        wait_time = 2 ** attempt + random.uniform(1, 2)
                        logging.warning(f"Received 503 for {filename}. Retrying in {wait_time:.1f}s")
                        await asyncio.sleep(wait_time)
                    else:
                        print(f"Failed to download {url}: Status {response.status}")
                        return None
            except Exception as e:
                if attempt < retries - 1:
                    wait_time = 2 ** attempt + random.uniform(1, 2)
                    print(f"Error downloading {url}. Retrying in {wait_time:.1f}s: {str(e)}")
                    await asyncio.sleep(wait_time)
                else:
                    print(f"Failed to download {url} after {retries} attempts: {str(e)}")
                    return None

    def extract_sections(self, pdf_path: str) -> Optional[Dict]:
        """
        Extract key sections and financial metrics from a given PDF using pdfplumber.
        """
        try:
            with pdfplumber.open(pdf_path) as pdf:
                text = "\n".join([page.extract_text() for page in pdf.pages if page.extract_text()])

            sections = {
                "report_date": self._extract_report_date(text),
                "MD&A": self._extract_section(
                    text,
                    r"(?:Management['’]?s?\s+(?:Discussion\s+)?&\s+(?:Analysis|Review)|"
                    r"MD&A|Operational Review|Directors['’]?\s+Report|"
                    r"Management Commentary)\s*(.*?)(?=Financial Statements|"
                    r"Notes to Accounts|Auditors['’]?\s+Report|\Z)",
                    default="Not Found"
                ),
                "Auditor_Opinion": self._extract_section(
                    text,
                    r"(?:Independent )?Auditor'?s (?:Report|Opinion)\s*(.*?)(?=Notes|\Z)",
                    default="Not Found"
                ),
                "Risk_Factors": self._extract_section(
                    text,
                    r"Risk Factors\s*(.*?)(?=Management|\Z)",
                    default="Not Found"
                ),
                "Revenue": self._extract_financial_metric(text, [
                    r"Revenue\s+(?:from\s+(?:operations|sales)\s+)?(?:of\s+)?(?:₹|Rs\.|INR|₨|₦|\$)?[\s]*([\d,]+(?:\.\d+)?(?:/-)?)",
                    r"Total\s+Revenue\s+(?:\(consolidated\)\s+)?(?:\(standalone\)\s+)?(?:₹|Rs\.|INR|₨|₦|\$)?[\s]*([\d,]+(?:\.\d+)?(?:/-)?)",
                    r"Operating\s+Revenue\s+(?:₹|Rs\.|INR|₨|₦|\$)?[\s]*([\d,]+(?:\.\d+)?(?:/-)?)",
                ]),
                "Net_Profit": self._extract_financial_metric(text, [
                    r"(?:Net\s+(?:Profit|Income)|Profit\s+After\s+Tax|Loss\s+After\s+Tax).*?(?:₹|Rs\.|INR|₨|₦|\$)?[\s]*([\d,]+(?:\.\d+)?(?:/-)?)",
                    r"Profit\s+After\s+Tax[:\s]+(?:₹|Rs\.|INR|₨|₦|\$)\s*([\d,]+(?:\.\d+)?(?:/-)?)",
                    r"Net\s+Income\s+(?:₹|Rs\.|INR|₨|₦|\$)?[\s]*([\d,]+(?:\.\d+)?(?:/-)?)"
                ]),
                "EBITDA": self._extract_financial_metric(text, [
                    r"\bEBITDA\b\s*\(?(?:consolidated|standalone)?\)?[:\s]+(?:₹|Rs\.|INR|₨|₦|\$)?\s*([\d,]+(?:\.\d+)?(?:/-)?)",
                    r"(?:Earnings\s+Before\s+Interest.*?Tax.*?Depreciation.*?Amortization)\s*[:\s]+(?:₹|Rs\.|INR|₨|₦|\$)?\s*([\d,]+(?:\.\d+)?(?:/-)?)",
                    r"EBITDA\s+for\s+the\s+period\s+(?:₹|Rs\.|INR|₨|₦|\$)?([\d,]+(?:\.\d+)?(?:/-)?)",
                    r"Adjusted\s+EBITDA\s+(?:₹|Rs\.|INR|₨|₦|\$)?[\s]*([\d,]+(?:\.\d+)?(?:/-)?)"
                ]),
                "Total_Assets": self._extract_financial_metric(text, [
                    r"Total\s+Assets[:\s]+(?:\(consolidated\)\s+)?(?:\(standalone\)\s+)?(?:₹|Rs\.|INR|₨|₦|\$)?[\s]*([\d,]+(?:\.\d+)?(?:/-)?)",
                    r"Net\s+worth\s+of\s+the\s+Company\s+(?:₹|Rs\.|INR|₨|₦|\$)?[\s]*([\d,]+(?:\.\d+)?(?:/-)?)",
                    r"Gross\s+Assets\s+(?:₹|Rs\.|INR|₨|₦|\$)?([\d,]+(?:\.\d+)?(?:/-)?)",
                    r"Total\s+Non-Current\s+Assets\s+(?:₹|Rs\.|INR|₨|₦|\$)?[\s]*([\d,]+(?:\.\d+)?(?:/-)?)"
                ]),
                "Total_Liabilities": self._extract_financial_metric(text, [
                    r"Total\s+Liabilities[:\s]+(?:\(consolidated\)\s+)?(?:\(standalone\)\s+)?(?:₹|Rs\.|INR|₨|₦|\$)?[\s]*([\d,]+(?:\.\d+)?(?:/-)?)",
                    r"Liabilities\s+and\s+Provisions\s+(?:₹|Rs\.|INR|₨|₦|\$)?([\d,]+(?:\.\d+)?(?:/-)?)",
                    r"Total\s+Non-Current\s+Liabilities\s+(?:₹|Rs\.|INR|₨|₦|\$)?[\s]*([\d,]+(?:\.\d+)?(?:/-)?)"
                ]),
                "EPS": self._extract_financial_metric(text, [
                    r"EPS[:\s]+([\d,]+(?:\.\d+)?(?:/-)?)",
                    r"Earnings\s+Per\s+Share[:\s]+([\d,]+(?:\.\d+)?(?:/-)?)",
                    r"Diluted\s+EPS[:\s]+(?:₹|Rs\.|INR|₨|₦|\$)?([\d,]+(?:\.\d+)?(?:/-)?)"
                ]),
                "PDF_URL": pdf_path,
            }
            return sections
        except Exception as e:
            print(f"Error processing {pdf_path}: {str(e)}")
            return None

    @staticmethod
    def _extract_section(text: str, pattern: str, default: str = "Not Found") -> str:
        match = re.search(pattern, text, re.DOTALL | re.IGNORECASE)
        return match.group(1).strip() if match else default

    @staticmethod
    def _extract_financial_metric(text: str, patterns: List[str]) -> str:
        for pattern in patterns:
            match = re.search(pattern, text, re.IGNORECASE | re.MULTILINE)
            if match:
                return match.group(1)
        return "Not Found"

    def _extract_company_name(self, text: str) -> str:
        """
        Fallback method to extract the company name directly from PDF content.
        We'll still override this with the dynamically scraped name.
        """
        patterns = [
            r"(?:(?:Company|Name of Entity|Entity Name|To,|Dear Sir/Madam,)\s*:\s*([A-Za-z0-9\s.,&-]+))",
            r"(?:For\s+([A-Za-z0-9\s.,&-]+))",
            r"(?:@.+\n([A-Za-z0-9\s.,&-]+)\s+LEASING AND FINANCE LIMITED)",
            r"(?:([A-Za-z0-9\s.,&-]+)\s+Annual Report)"
        ]
        for pattern in patterns:
            matches = re.findall(pattern, text, re.IGNORECASE)
            if matches:
                return matches[0].strip()
        return "Not Found"

    def _extract_report_date(self, text: str) -> str:
        date_patterns = [
            r"Annual Report\s*(\d{1,2}\s\w+\s\d{4})",
            r"Report Date:\s*(\d{1,2}/\d{1,2}/\d{4})",
            r"Year Ended\s*(\w+\s\d{4})"
        ]
        for pattern in date_patterns:
            match = re.search(pattern, text, re.IGNORECASE)
            if match:
                return match.group(1)
        return "Not Found"

    async def process_pdf(self, pdf_path: str, company_name: str) -> Optional[Dict]:
        """
        Process a single PDF file by extracting relevant text sections, performing
        sentiment analysis on those sections using FinBERT, and predicting market action
        (Buy/Neutral/Sell) using the BuySell model.
        """
        sections = self.extract_sections(pdf_path)
        if sections:
            # Override with the dynamically scraped company name.
            sections["company_name"] = company_name

            # Perform sentiment analysis on key textual sections using FinBERT.
            analysis = {
                "MD&A": self.finbert.analyze_sentiment(sections["MD&A"]),
                "Auditor_Opinion": self.finbert.analyze_sentiment(sections["Auditor_Opinion"]),
                "Risk_Factors": self.finbert.analyze_sentiment(sections["Risk_Factors"]),
            }
            sections["Analysis"] = analysis

            # Also perform BuySell analysis on these sections.
            buy_sell_analysis = {
                "MD&A": self.buy_sell_analyzer.predict_action(sections["MD&A"]),
                "Auditor_Opinion": self.buy_sell_analyzer.predict_action(sections["Auditor_Opinion"]),
                "Risk_Factors": self.buy_sell_analyzer.predict_action(sections["Risk_Factors"]),
            }
            sections["BuySellAnalysis"] = buy_sell_analysis

            return sections
        return None

    async def process_pdfs(self, pdf_urls: List[str], company_names: List[str], max_concurrent: int = 3):
        """
        Process multiple PDFs concurrently while respecting a concurrency limit,
        matching PDF URLs to the corresponding company names (by index).
        The tasks are gathered using asyncio.gather so that the results remain in order.
        """
        semaphore = asyncio.Semaphore(max_concurrent)

        async def process_with_semaphore(url: str, c_name: str):
            async with semaphore:
                pdf_path = await self.download_pdf(url)
                if pdf_path:
                    await asyncio.sleep(random.uniform(1, 2))  # Simple rate limiting
                    return await self.process_pdf(pdf_path, c_name)
            return None

        tasks = []
        for i, url in enumerate(pdf_urls):
            # Safely handle cases where company_names might have fewer items than pdf_urls.
            c_name = company_names[i] if i < len(company_names) else "Unknown Company"
            tasks.append(process_with_semaphore(url, c_name))

        # Gather tasks in order
        results = await asyncio.gather(*tasks)
        # Filter out any None results
        self.results = [result for result in results if result]

    async def _print_results(self) -> None:
        """
        Print the extracted sections, sentiment analysis results, and BuySell predictions
        for each processed PDF.
        """
        for result in self.results:
            print("\n" + "=" * 80)
            print(f"Analysis Report for {result['company_name']}")
            if result['report_date'] != "Not Found":
                print(f" {result['report_date']}")
            
            print(f"PDF Source: {result['PDF_URL']}")
            print("=" * 80)

            # Print financial metrics.
            print("\nKey Financial Metrics:")
            metrics = [
                ("Revenue", "Revenue"),
                ("Net Profit", "Net_Profit"),
                ("EBITDA", "EBITDA"),
                ("Total Assets", "Total_Assets"),
                ("Total Liabilities", "Total_Liabilities"),
                ("EPS", "EPS"),
            ]
            for label, key in metrics:
                print(f"- {label}: {result[key]}")

            # Display FinBERT sentiment analysis results.
            print("\nFinBERT Sentiment Analysis:")
            self._print_section_analysis(
                result["Analysis"]["MD&A"],
                "Management Discussion & Analysis"
            )
            self._print_section_analysis(
                result["Analysis"]["Auditor_Opinion"],
                "Auditor's Opinion"
            )
            self._print_section_analysis(
                result["Analysis"]["Risk_Factors"],
                "Risk Factors Analysis"
            )

            # Display BuySell model predictions.
            print("\nBuy/Neutral/Sell Predictions:")
            for section, prediction in result["BuySellAnalysis"].items():
                print(f"- {section}: {prediction}")

    def _print_section_analysis(self, analysis: Dict, heading: str) -> None:
        """
        Helper to print the sentiment distribution and sample statements for a section.
        """
        print(f"\n{heading}:")
        print(f"Sentiment Distribution: {analysis['percentages']}")
        print("Key Insights:")
        for sentiment in ["positive", "neutral", "negative"]:
            if analysis["insights"].get(sentiment):
                print(f"- {sentiment.capitalize()} Statements:")
                # Show a few sample statements.
                for sentence in analysis["insights"][sentiment][3:7]:
                    print(f"  • {sentence}")

    async def run(self):
        """
        Orchestrate the pipeline: scraping company names, scraping PDF links,
        processing PDFs, and printing results.
        """
        try:
            # First, get the PDF download links.
            pdf_urls = await self.scrape_links()
            print(f"Found {len(pdf_urls)} PDF files to process")

            # Next, scrape the company names and then slice the list to match indices 5 to 10.
            company_names_full = await self.scrape_names()
            company_names = company_names_full[5:10]
            print(f"Scraped {len(company_names)} company names (dynamically matched to PDF links)")
            print(company_names)

            # Process PDFs and map them to scraped company names one-to-one.
            await self.process_pdfs(pdf_urls, company_names)
            await self._print_results()
        finally:
            await self.close_session()

async def main():
    url = "https://www.screener.in/annual-reports/"
    analyzer = PDFAnalyzer(url)
    await analyzer.run()

if __name__ == "__main__":
    asyncio.run(main())