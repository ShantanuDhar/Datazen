import requests
from bs4 import BeautifulSoup
import pandas as pd
from datetime import datetime
import time

def fetch_google_stock_news(company_name, num_results=10):
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.5',
        'Connection': 'keep-alive',
    }
    
    # Improved search query with more financial news sources
    search_query = (f"{company_name} stock news "
                   "site:finance.yahoo.com OR "
                   "site:moneycontrol.com OR "
                   "site:livemint.com OR "
                   "site:economictimes.indiatimes.com OR "
                   "site:reuters.com OR "
                   "site:bloomberg.com")
    
    url = f"https://www.google.com/search?q={search_query}&tbm=nws&num={num_results}"
    
    try:
        # Add delay to avoid rate limiting
        time.sleep(2)
        response = requests.get(url, headers=headers, timeout=10)
        response.raise_for_status()
        
        soup = BeautifulSoup(response.text, 'html.parser')
        news_items = soup.find_all('div', {'class': ['SoaBEf', 'WlydOe']})
        
        news_data = []
        
        for item in news_items:
            try:
                # Extract title and link
                title_elem = item.find('div', class_=['n0jPhd', 'mCBkyc'])
                link_elem = item.find('a')
                source_elem = item.find('div', class_=['MgUUmf', 'NUnG9d'])
                date_elem = item.find('div', class_=['OSrXXb', 'ZE0LJd'])
                
                if all([title_elem, link_elem, source_elem, date_elem]):
                    title = title_elem.text.strip()
                    link = link_elem['href']
                    source = source_elem.text.strip()
                    date = date_elem.text.strip()
                    
                    # Extract snippet if available
                    snippet_elem = item.find('div', class_=['VwiC3b', 'yXK7lf'])
                    snippet = snippet_elem.text.strip() if snippet_elem else ""
                    
                    news_entry = {
                        'title': title,
                        'source': source,
                        'url': link,
                        'published': date,
                        'snippet': snippet
                    }
                    news_data.append(news_entry)
            
            except AttributeError:
                continue
        
        df = pd.DataFrame(news_data)
        # Remove duplicates based on title
        df = df.drop_duplicates(subset=['title'])
        return df
    
    except Exception as e:
        print(f"Error fetching news: {e}")
        return pd.DataFrame()

if __name__ == "__main__":
    company_name = input("Enter company name or stock symbol: ")
    news_df = fetch_google_stock_news(company_name)
    
    if not news_df.empty:
        print("\nLatest News Headlines:")
        pd.set_option('display.max_colwidth', None)
        print(news_df[['title', 'source', 'published', 'snippet']])
        
        # Save to CSV with timestamp
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"stock_news_{company_name}_{timestamp}.csv"
        news_df.to_csv(filename, index=False, encoding='utf-8')
        print(f"\nNews data saved to {filename}")
    else:
        print("No news found for this company.")