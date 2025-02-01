import os
import time
import json
import requests
import logging
import traceback
from datetime import datetime
from flask import Flask
import threading
import sys
import tempfile

# Selenium and WebDriver imports
from selenium import webdriver
from selenium.webdriver.chrome.service import Service as ChromeService
from webdriver_manager.chrome import ChromeDriverManager
## write a code to import load_env
from dotenv import load_dotenv

# Playwright imports
from playwright.sync_api import sync_playwright

load_dotenv()
# Hugging Face Transformers imports
try:
    from transformers import AutoModelForSequenceClassification, AutoTokenizer
    import torch
    SENTIMENT_AVAILABLE = True
except ImportError:
    SENTIMENT_AVAILABLE = False
    logging.warning("Sentiment analysis dependencies not installed.")

# Flask App for Health Checks
app = Flask(__name__)

@app.route('/health')
def health_check():
    return "OK", 200

# Load environment variables
TELEGRAM_BOT_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN")
TELEGRAM_CHAT_ID = os.getenv("TELEGRAM_CHAT_ID")

# Ensure that TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID are set
if not TELEGRAM_BOT_TOKEN or not TELEGRAM_CHAT_ID:
    raise ValueError("TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID must be set")

# Sentiment Analysis Class
class SentimentAnalyzer:
    def __init__(self):
        self.model = None
        self.tokenizer = None
        self.setup_model()

    def setup_model(self):
        """Initialize FinancialBERT sentiment analysis model."""
        if not SENTIMENT_AVAILABLE:
            logging.error("Cannot setup sentiment model - dependencies missing")
            return

        try:
            model_name = "ahmedrachid/FinancialBERT-Sentiment-Analysis"
            self.tokenizer = AutoTokenizer.from_pretrained(model_name)
            self.model = AutoModelForSequenceClassification.from_pretrained(model_name)
            logging.info("Sentiment analysis model loaded successfully.")
        except Exception as e:
            logging.error(f"Failed to load sentiment model: {e}")
            self.model = None

    def analyze_sentiment(self, text):
        """
        Perform sentiment analysis on the given text with detailed insights.
        Returns a string describing the sentiment result.
        """
        if not SENTIMENT_AVAILABLE or not self.model:
            return "Sentiment analysis unavailable"

        try:
            # Prepare input
            inputs = self.tokenizer(text, return_tensors="pt", truncation=True, padding=True, max_length=512)

            # Perform inference
            with torch.no_grad():
                outputs = self.model(**inputs)
                predictions = torch.nn.functional.softmax(outputs.logits, dim=-1)
                sentiment_scores = predictions.numpy()[0]
                sentiment_label = torch.argmax(predictions, dim=1).item()

            # Detailed sentiment mapping
            sentiment_details = {
                0: {
                    "label": "Negative 📉",
                    "description": "Potentially unfavorable or concerning announcement",
                    "score": sentiment_scores[0]
                },
                1: {
                    "label": "Neutral 🔄",
                    "description": "Balanced or informative announcement",
                    "score": sentiment_scores[1]
                },
                2: {
                    "label": "Positive 📈",
                    "description": "Promising or optimistic announcement",
                    "score": sentiment_scores[2]
                }
            }

            # Get the most likely sentiment
            result = sentiment_details[sentiment_label]

            # Format a detailed sentiment string
            detailed_sentiment = (
                f"{result['label']} "
                f"(Confidence: {result['score'] * 100:.2f}%) - "
                f"{result['description']}"
            )

            return detailed_sentiment

        except Exception as e:
            logging.error(f"Sentiment analysis error: {e}")
            return "Sentiment analysis failed"

class BSEUpdateMonitor:
    def __init__(self, telegram_bot_token, telegram_chat_id):
        # Telegram Configuration
        self.TELEGRAM_BOT_TOKEN = telegram_bot_token
        self.TELEGRAM_CHAT_ID = telegram_chat_id

        # Logging Configuration
        self.setup_logging()

        # State Tracking
        self.previous_announcements = set()
        self.error_count = 0
        self.max_errors = 5
        self.monitoring_iteration = 0

        # Sentiment Analysis Setup
        self.sentiment_analyzer = SentimentAnalyzer()

    def setup_logging(self):
        """Configure logging for the application using the temp directory."""
        temp_dir = tempfile.gettempdir()
        log_directory = os.path.join(temp_dir, 'bse_monitor_logs')
        os.makedirs(log_directory, exist_ok=True)

        log_file = os.path.join(
            log_directory, f'bse_monitor_{datetime.now().strftime("%Y%m%d")}.log'
        )

        logging.basicConfig(
            level=logging.INFO,  # Correct logging level
            format='%(asctime)s - %(levelname)s: %(message)s',
            handlers=[
                logging.FileHandler(log_file),
                logging.StreamHandler(sys.stdout)
            ]
        )

        logging.info(f"Logging to directory: {log_directory}")

    def send_telegram_message(self, message):
        """
        Send a message to Telegram with robust error handling.
        Uses HTML parse_mode for better message formatting.
        """
        try:
            url = f"https://api.telegram.org/bot{self.TELEGRAM_BOT_TOKEN}/sendMessage"

            def sanitize_text(text):
                # Remove non-printable characters
                return ''.join(char for char in text if 32 <= ord(char) <= 126)

            sanitized_message = sanitize_text(message)

            payload = {
                "chat_id": self.TELEGRAM_CHAT_ID,
                "text": sanitized_message,
                "parse_mode": "HTML"  # Use HTML parse mode for nicer formatting
            }

            response = requests.post(url, json=payload, timeout=10)
            response.raise_for_status()
            logging.info("Telegram message sent successfully.")
            return True
        except Exception as e:
            logging.error(f"Telegram message send failed: {e}")
            return False

    def extract_table_data(self, page):
        """Extract data from BSE announcement table with robust error handling."""
        extracted_data = []
        try:
            table_selectors = page.query_selector_all("//table[@ng-repeat='cann in CorpannData.Table']")
            for table_elem in table_selectors:
                row_elems = table_elem.query_selector_all("tr")
                for row in row_elems:
                    columns = row.query_selector_all("td")
                    if len(columns) > 3:
                        try:
                            announcement_key = f"{columns[0].inner_text().strip()}|{columns[1].inner_text().strip()}"
                            pdf_link_elems = columns[3].query_selector_all("a") if columns[3] else []
                            pdf_link = pdf_link_elems[0].get_attribute("href") if pdf_link_elems else "N/A"

                            data = {
                                "key": announcement_key,
                                "news_sub": columns[0].inner_text().strip(),
                                "category": columns[1].inner_text().strip(),
                                "pdf_link": pdf_link,
                                "headline": columns[0].inner_text().strip(),
                                "exchange_time": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                            }
                            extracted_data.append(data)
                        except Exception as row_error:
                            logging.warning(f"Error extracting row data: {row_error}")

        except Exception as e:
            logging.error(f"No data found or extraction failed: {e}")
        return extracted_data

    def prepare_browser_and_extract(self):
        """Use Playwright to open browser, extract data, and handle potential errors."""
        data = []
        with sync_playwright() as p:
            try:
                browser = p.chromium.launch(
                    headless=True,
                    args=[
                        '--no-sandbox',
                        '--disable-setuid-sandbox',
                        '--disable-infobars',
                        '--disable-dev-shm-usage',
                        '--disable-gpu'
                    ]
                )
                context = browser.new_context()
                page = context.new_page()
                page.set_default_timeout(30000)

                # Navigate to BSE announcements
                page.goto("https://www.bseindia.com/corporates/ann.html")

                # Wait for the page to load fully
                page.wait_for_load_state('networkidle')

                # Select Period
                page.evaluate("""() => {
                    const periodSelect = document.getElementById('ddlPeriod');
                    if (periodSelect) {
                        for (let i = 0; i < periodSelect.options.length; i++) {
                            if (periodSelect.options[i].text.includes('Company Update')) {
                                periodSelect.selectedIndex = i;
                                periodSelect.dispatchEvent(new Event('change'));
                                break;
                            }
                        }
                    }
                }""")

                # Wait for changes
                page.wait_for_timeout(1000)

                # Select Subcategory
                page.evaluate("""() => {
                    const subcatSelect = document.getElementById('ddlsubcat');
                    if (subcatSelect) {
                        for (let i = 0; i < subcatSelect.options.length; i++) {
                            if (subcatSelect.options[i].text.includes('Award of Order')) {
                                subcatSelect.selectedIndex = i;
                                subcatSelect.dispatchEvent(new Event('change'));
                                break;
                            }
                        }
                    }
                }""")

                # Wait for changes
                page.wait_for_timeout(1000)

                # Submit the form
                page.evaluate("""() => {
                    const submitButton = document.getElementById('btnSubmit');
                    if (submitButton) {
                        submitButton.click();
                    }
                }""")

                # Wait for results to load
                page.wait_for_timeout(2000)

                # Extract data
                data = self.extract_table_data(page)

            except Exception as e:
                logging.error(f"Error in prepare_browser_and_extract: {e}")
                logging.error(traceback.format_exc())
            finally:
                if 'browser' in locals():
                    browser.close()

        return data

    def format_message(self, entry):
        """
        Advanced formatting for Telegram message with enhanced readability
        
        Args:
            entry (dict): Announcement details dictionary
        
        Returns:
            str: Formatted Telegram message
        """
        try:
            # Extract company name and BSE code
            full_company_info = entry.get('news_sub', 'N/A')
            company_parts = full_company_info.split(' - ')
            company_name = company_parts[0] if company_parts else 'Unknown Company'
            bse_code = company_parts[1] if len(company_parts) > 1 else 'N/A'
    
            # Prepare PDF link
            pdf_link = entry.get('pdf_link', 'N/A')
            pdf_display_link = f"https://www.bseindia.com{pdf_link}" if pdf_link and pdf_link != 'N/A' else 'N/A'
    
            # Sentiment color coding
            sentiment = entry.get('sentiment', 'Not Available')
            sentiment_emoji = {
                'Negative': '🔴',
                'Neutral': '🟡',
                'Positive': '🟢'
            }
            current_sentiment_emoji = next((emoji for key, emoji in sentiment_emoji.items() if key.lower() in sentiment.lower()), '⚪')
    
            # Construct detailed message
            message = f"""
    🚨 <b>BSE Market Announcement</b> 🚨
    
    📌 <b>Company:</b> {company_name}
    🔢 <b>BSE Code:</b> {bse_code}
    
    📋 <b>Category:</b> {entry.get('category', 'N/A')}
    
    📣 <b>Headline:</b>
    {entry.get('headline', 'No headline available')}
    
    📊 <b>Sentiment Analysis:</b> {current_sentiment_emoji} {sentiment}
    
    ⏰ <b>Timestamp:</b> {entry.get('exchange_time', 'N/A')}
    
    🔗 <b>Official Document:</b> 
    {f'<a href="{pdf_display_link}">View BSE Attachment</a>' if pdf_display_link != 'N/A' else 'No attachment available'}
    
    #BSEAnnouncement #MarketUpdate #{company_name.replace(' ', '')}
    """
            return message
    
        except Exception as e:
            logging.error(f"Error in message formatting: {e}")
            return f"Unable to format message for {entry.get('news_sub', 'Unknown Company')}"

    def monitor_updates(self):
        """Continuously monitor BSE for updates."""
        while True:
            try:
                self.monitoring_iteration += 1
                logging.info(f"🕵️ Monitoring Iteration {self.monitoring_iteration}: Checking for BSE Announcements...")

                current_data = self.prepare_browser_and_extract()
                if not current_data:
                    logging.info(f"Iteration {self.monitoring_iteration}: No new announcements found. Continuing monitoring...")
                    time.sleep(5)
                    continue

                new_announcements = []
                for entry in current_data:
                    if entry['key'] not in self.previous_announcements:
                        # Perform detailed sentiment analysis
                        sentiment = self.sentiment_analyzer.analyze_sentiment(entry['headline'])

                        # Log sentiment details
                        logging.info(f"Sentiment Analysis for '{entry['headline']}': {sentiment}")

                        # Attach sentiment to the entry for reporting
                        entry['sentiment'] = sentiment
                        new_announcements.append(entry)
                        self.previous_announcements.add(entry['key'])

                if new_announcements:
                    logging.info(f"🚨 Found {len(new_announcements)} new announcements!")

                    # Send notifications for each new announcement
                    for entry in new_announcements:
                        # Enhanced message with sentiment details
                        message = self.format_message(entry)

                        try:
                            notification_result = self.send_telegram_message(message)
                            if notification_result:
                                logging.info(f"Telegram message sent successfully.\nNotification sent for announcement: {entry['key']}")
                            else:
                                logging.warning(f"Failed to send notification for announcement: {entry['key']}")
                        except Exception as notification_error:
                            logging.error(f"Error sending notification: {notification_error}")

                    # Limit the size of previous_announcements
                    if len(self.previous_announcements) > 1000:
                        self.previous_announcements = set(list(self.previous_announcements)[-1000:])

                time.sleep(5)

            except Exception as e:
                logging.error(f"Unexpected error in monitoring: {e}")
                logging.error(traceback.format_exc())

                self.error_count += 1
                backoff_time = min(5 * self.error_count, 300)
                logging.warning(f"Waiting {backoff_time} seconds before retry due to error.")
                time.sleep(backoff_time)

                if self.error_count > self.max_errors:
                    logging.error("Max error count reached. Resetting error tracking.")
                    self.error_count = 0

def main():
    """Main application entry point with robust error handling."""
    logging.basicConfig(
        level=logging.INFO,  # Correct logging level
        format='%(asctime)s - %(levelname)s: %(message)s',
        handlers=[
            logging.StreamHandler(sys.stdout)
        ]
    )

    logging.info("🚀 BSE Announcement Monitor - Starting Up")

    try:
        TELEGRAM_BOT_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN")
        TELEGRAM_CHAT_ID = os.getenv("TELEGRAM_CHAT_ID")

        if not TELEGRAM_BOT_TOKEN or not TELEGRAM_CHAT_ID:
            logging.error("Telegram credentials not provided. Exiting.")
            return

        monitor = BSEUpdateMonitor(TELEGRAM_BOT_TOKEN, TELEGRAM_CHAT_ID)

        # Send startup message to Telegram
        try:
            startup_url = f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}/sendMessage"
            startup_payload = {
                "chat_id": TELEGRAM_CHAT_ID,
                "text": (
                    "🚀 BSE Announcement Monitor Started Successfully!\n"
                    "Continuous monitoring is now active."
                ),
                "parse_mode": "HTML"  # Ensure consistent formatting in startup message
            }
            requests.post(startup_url, json=startup_payload, timeout=10)
        except Exception as startup_error:
            logging.error(f"Failed to send startup message: {startup_error}")

        # Start monitoring in a separate thread
        monitoring_thread = threading.Thread(target=monitor.monitor_updates, daemon=True)
        monitoring_thread.start()

        # Start Flask health check server
        port = int(os.getenv('PORT', 20000))
        app.run(host='0.0.0.0', port=port)

    except Exception as e:
        logging.error(f"Critical error in main: {str(e)}")
        logging.error(traceback.format_exc())
        sys.exit(1)

if __name__ == "__main__":
    while True:
        try:
            main()
        except Exception as critical_error:
            logging.error(f"Critical error occurred: {str(critical_error)}")
            logging.error(traceback.format_exc())
            time.sleep(60)  # Wait before restarting the main process