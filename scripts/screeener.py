import requests
from bs4 import BeautifulSoup
import pandas as pd

def get_financial_data(ticker, metric):
        
    # Create session and set headers
    session = requests.Session()
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.5',
    }
    
    # Get company page
    url = f'https://www.screener.in/company/{ticker}/'
    try:
        response = session.get(url, headers=headers)
        response.raise_for_status()
        
        # Parse HTML
        soup = BeautifulSoup(response.content, 'html.parser')
        
        # Find all tables
        tables = soup.find_all('table', {'class': 'data-table'})
        
        if not tables:
            print("No data found")
            return None
            
        # Dictionary to store DataFrames
        dfs = {}
        
        # Process each table
        for table in tables:
            section = table.find_previous(['h2', 'h3'])
            if section:
                section_name = section.text.strip()
                from io import StringIO
                df = pd.read_html(StringIO(str(table)))[0]
                
                # Clean up the DataFrame
                df = df.set_index(df.columns[0])
                df.index.name = 'Metric'
                
                # Store in dictionary
                dfs[section_name] = df
        
        # Return based on metric parameter
        if metric.lower() == 'pl':
            return dfs.get('Profit & Loss')
        elif metric.lower() == 'bs':
            return dfs.get('Balance Sheet')
        elif metric.lower() == 'q':
            return dfs.get('Quarterly Results')
        elif metric.lower() == 'r':
            return dfs.get('Ratios')
        elif metric.lower() == 'all':
            # Combine all DataFrames
            combined_df = pd.concat(dfs.values(), keys=dfs.keys(), axis=0)
            combined_df.index.names = ['Section', 'Metric']
            return combined_df
        else:
            print("Invalid metric specified")
            return None
            
    except requests.exceptions.RequestException as e:
        print(f"Error fetching data: {e}")
        return None
    except Exception as e:
        print(f"Error processing data: {e}")


def get_financial_json(ticker):
    
    # Get just the quarterly results
    quarterly_df = get_financial_data(ticker, 'q')

    # Get just the profit and loss statement
    pl_df = get_financial_data(ticker, 'pl')

    bs_df=pl_df = get_financial_data(ticker, 'bs')
    
    f_df=pl_df = get_financial_data(ticker, 'r')
    
    return {
        'quarterly': quarterly_df.to_json(),
        'profit_loss': pl_df.to_json(),
        'balance_sheet': bs_df.to_json(),
        'ratio': f_df.to_json()
    }

if __name__ == "__main__":
    print(get_financial_json('TCS'))