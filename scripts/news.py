import requests
from bs4 import BeautifulSoup
from datetime import datetime
import time
import random
from lxml import html
import pandas as pd
import os
import dotenv

dotenv.load_dotenv()

huggingface_api_key=os.getenv("HUGGINGFACE_API_KEY")

API_URL = "https://api-inference.huggingface.co/models/ProsusAI/finbert"
headers = {"Authorization": huggingface_api_key}

def scrape_yahoo_finance_news(stock_symbol):
    """
    Scrape news from Yahoo Finance for a given stock symbol.
    Returns a list of news items.
    """
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
    }
    
    base_url = f'https://finance.yahoo.com/quote/{stock_symbol}/news/'
    
    try:
        response = requests.get(base_url, headers=headers)
        response.raise_for_status()
        soup = BeautifulSoup(response.content, 'html.parser')
        
        news_items = soup.find_all('li', class_='stream-item')
        
        news_data = []
        
        for item in news_items[:15]:  # Limit to top 15 news
            try:
                news_link = item.find('a', class_='titles')['href']
                if not news_link.startswith('http'):
                    news_link = 'https://finance.yahoo.com' + news_link
                
                detailed_news = scrape_detailed_news(news_link, headers)
                
                publishing_div = item.find('div', class_='publishing')
                if publishing_div:
                    publisher = publishing_div.get_text().split('•')[0].strip()
                    detailed_time = detailed_news['time']
                else:
                    publisher = "Unknown"
                    detailed_time = "Unknown"
                
                news_item = {
                    'title': detailed_news['title'],
                    'link': news_link,
                    'publisher': publisher,
                    'detailed_time': detailed_time,
                    'content': detailed_news['content'],
                }
                
                news_data.append(news_item)
                
                time.sleep(random.uniform(1, 3))  # Random delay between requests
                
            except Exception as e:
                print(f"Error processing news item: {str(e)}")
                continue

        return news_data
        
    except Exception as e:
        print(f"Error scraping news: {str(e)}")
        return None

def scrape_detailed_news(url, headers):
    """
    Scrape detailed news content from individual news pages using specific XPaths.
    """
    try:
        response = requests.get(url, headers=headers)
        response.raise_for_status()
        
        tree = html.fromstring(response.content)
        
        title_element = tree.xpath('/html/body/div[2]/main/section/section/section/article/div/div[1]/div[1]/h1')
        title_text = title_element[0].text_content().strip() if title_element else ""
        
        time_element = tree.xpath('/html/body/div[2]/main/section/section/section/article/div/div[1]/div[2]/div[1]/div/div[2]/time')
        time_text = time_element[0].text_content().strip() if time_element else ""
        
        content_element = tree.xpath('/html/body/div[2]/main/section/section/section/article/div/div[1]/div[3]/div[2]/p[2]')
        content_text = content_element[0].text_content().strip() if content_element else ""
        
        if not content_text:  # Fallback to all paragraphs if content is empty
            content_elements = tree.xpath('//div[contains(@class, "caas-body")]//p')
            content_text = ' '.join([p.text_content().strip() for p in content_elements])
        
        return {
            'title': title_text,
            'time': time_text,
            'content': content_text
        }
        
    except Exception as e:
        print(f"Error scraping detailed news: {str(e)}")
        return {
            'title': "",
            'time': "",
            'content': ""
        }

def query(payload):
    response = requests.post(API_URL, headers=headers, json=payload)
    return response.json()

def get_highest_score_label(output):
    scores = output[0]
    highest_score_dict = max(scores, key=lambda x: x['score'])
    return highest_score_dict['label']


def get_news_df(ticker):
    output_df = pd.DataFrame(scrape_yahoo_finance_news(ticker))
    
    if output_df.empty:
        print("No data available.")
        return output_df
    
    output_df['sentiment'] = output_df['content'].apply(lambda x: get_highest_score_label(query({'inputs': x})))
    
    # Convert detailed_time to datetime and extract only the date part
    output_df['detailed_time'] = pd.to_datetime(output_df['detailed_time'], errors='coerce').dt.date
    
    return output_df

# stock_symbol = "INFY.NS"
# output=get_news_df(stock_symbol)
# output