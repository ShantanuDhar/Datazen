import yfinance as yf
import pandas as pd
from datetime import datetime, timedelta

def get_stock_info(ticker_symbol):
    """
    Get stock information for Indian stocks from NSE
    
    Parameters:
    ticker_symbol (str): Stock ticker symbol (e.g., 'RELIANCE', 'TCS')
    
    Returns:
    pandas.DataFrame: Processed stock data for the last 10 days
    """
    try:
        # Append .NS for NSE stocks
        nse_symbol = f"{ticker_symbol}"
        stock = yf.Ticker(nse_symbol)
        
        # Get end date (today) and start date (10 days ago)
        end_date = datetime.now()
        start_date = end_date - timedelta(days=10)
        
        # Get historical data
        hist = stock.history(start=start_date, end=end_date)
        
        if hist.empty:
            # Try BSE if NSE data is not available
            bse_symbol = f"{ticker_symbol}.BO"
            stock = yf.Ticker(bse_symbol)
            hist = stock.history(start=start_date, end=end_date)
        
        # Reset index to make Date a column
        hist = hist.reset_index()
        
        # Calculate daily price change and change indication
        hist['Price_Change'] = hist['Close'].diff()
        hist['Change_Direction'] = hist['Price_Change'].apply(
            lambda x: 'Positive' if x > 0 else 'Negative' if x < 0 else 'No Change'
        )
        
        # Format Date column
        hist['Date'] = hist['Date'].dt.strftime('%Y-%m-%d')
        
        # Round numerical columns to 2 decimal places
        numeric_columns = ['Open', 'High', 'Close', 'Price_Change']
        hist[numeric_columns] = hist[numeric_columns].round(2)
        
        # Select and rename columns
        result = hist[[
            'Date', 'Open', 'High', 'Close', 'Volume', 
            'Price_Change', 'Change_Direction'
        ]]
        
        return result
    
    except Exception as e:
        print(f"Error occurred: {str(e)}")
        return None

def display_stock_data(ticker_symbol):
    """
    Display formatted stock data for a given Indian stock ticker symbol.
    
    Parameters:
    ticker_symbol (str): Stock ticker symbol
    """
    data = get_stock_info(ticker_symbol)
    
    if data is not None:
        print(f"\nStock Analysis for {ticker_symbol}")
        print("=" * 80)
        
        for _, row in data.iterrows():
            print(f"\nDate: {row['Date']}")
            print(f"Open: ₹{row['Open']}")
            print(f"High: ₹{row['High']}")
            print(f"Close: ₹{row['Close']}")
            print(f"Volume: {row['Volume']:,}")
            print(f"Price Change: ₹{row['Price_Change']}")
            print(f"Change Direction: {row['Change_Direction']}")
            print("-" * 40)

# # Example usage
# if __name__ == "__main__":
#     print("Enter Indian stock symbol (e.g., RELIANCE, TCS, INFY)")
#     stock_symbol = input("Stock symbol: ").upper()
#     display_stock_data(stock_symbol)