import pandas as pd
import numpy as np
import yfinance as yf
from datetime import datetime, timedelta
import warnings
warnings.filterwarnings('ignore')

class BSEStockAnalyzer:
    def __init__(self, csv_path):
       
        self.csv_path = csv_path
        self.bse500_list = None
        self.stock_industry_map = {}
        
    def load_stock_data(self):
      
        try:
            # Read the CSV file
            df = pd.read_csv(self.csv_path)
            
            # Clean and prepare the data
            df = df[df['Status'] == 'Active']  # for active stocks only
            
            self.bse500_list = pd.DataFrame({
                'Symbol': df['Security Id'],
                'Company': df['Security Name'],
                'Industry': df['Industry New Name'].fillna(df['Industry']),  
                'Sector': df['Sector Name'],
                'ISIN': df['ISIN No'],
                'Security_Code': df['Security Code']
            })
            
            # Create industry mapping
            self.stock_industry_map = dict(zip(self.bse500_list['Symbol'], 
                                             self.bse500_list['Industry']))
            
            print(f"Loaded {len(self.bse500_list)} stocks from CSV")
            return self.bse500_list
            
        except Exception as e:
            print(f"Error loading stock data from CSV: {e}")
            return None

    def get_stock_data(self, symbols, start_date, end_date):
        data = pd.DataFrame()
        total_symbols = len(symbols)
        
        for idx, symbol in enumerate(symbols, 1):
            try:
                # Add .BO suffix if missing (except for BSE500 index)
                if not symbol.endswith('.BO') and symbol != 'BSE500':
                    symbol_yf = f"{symbol}.BO"
                else:
                    symbol_yf = symbol
                    
                # Download full data
                downloaded_data = yf.download(symbol_yf, start=start_date, end=end_date, progress=False)
                
                # Skip if no data
                if downloaded_data.empty:
                    print(f"No data available for {symbol}")
                    continue
                    
                # Verify Close price exists
                if 'Close' not in downloaded_data.columns:
                    print(f"'Close' price not found for {symbol}")
                    continue
                    
                # Extract Close prices
                close_prices = downloaded_data['Close']
                
                if not close_prices.empty:
                    data[symbol] = close_prices
                    print(f"Fetched data for {symbol} ({idx}/{total_symbols})")
                else:
                    print(f"No Close prices available for {symbol}")
                    
            except Exception as e:
                print(f"Error fetching data for {symbol}: {str(e)}")
                continue
                
        return data

    def calculate_relative_strength(self, data, window=63):
        if data.empty:
            return pd.Series()
        
        # Calculate total return over the lookback period for each stock
        returns = data.pct_change(periods=window).iloc[-1]  # Get the latest return
        market_return = returns.mean()
        
        # Calculate relative strength
        rs_scores = returns - market_return
        return rs_scores.sort_values(ascending=False)

    def calculate_industry_momentum(self, data, lookback_period=63):
        if data.empty:
            return pd.Series()
            
        industry_returns = {}
        
        # Calculate returns
        returns = data.pct_change()
        
        # Group stocks by industry and calculate total returns over the lookback period
        for symbol in returns.columns:
            if symbol in self.stock_industry_map:
                industry = self.stock_industry_map[symbol]
                if industry not in industry_returns:
                    industry_returns[industry] = []
                industry_returns[industry].append(returns[symbol])
        
        # Calculate industry momentum
        industry_momentum = {}
        for industry, stock_returns in industry_returns.items():
            if stock_returns:
                try:
                    # Average returns for the industry
                    industry_avg = pd.concat(stock_returns, axis=1).mean(axis=1)
                    # Calculate total return over the lookback period
                    if len(industry_avg) >= lookback_period:
                        momentum = (industry_avg.iloc[-1] / industry_avg.iloc[-lookback_period] - 1)
                        industry_momentum[industry] = momentum
                    else:
                        industry_momentum[industry] = np.nan  # Not enough data
                except Exception as e:
                    print(f"Error calculating momentum for {industry}: {e}")
        
        return pd.Series(industry_momentum).sort_values(ascending=False)

    def analyze_market(self, lookback_days=365):
        """
        Main analysis function
        """
        # Set date range
        end_date = datetime.now()
        start_date = end_date - timedelta(days=lookback_days)
        
        # Load stock list if not already loaded
        if self.bse500_list is None:
            print("Loading stocks from CSV...")
            self.load_stock_data()
        
        if self.bse500_list is None:
            return None
        
        print("Fetching stock data...")
        # Get symbols
        symbols = self.bse500_list['Symbol'].tolist()
        
        # Get stock data
        data = self.get_stock_data(symbols, start_date, end_date)
        
        print("Calculating metrics...")
        # Calculate Relative Strength
        rs_scores = self.calculate_relative_strength(data)
        top_rs_stocks = rs_scores  # No need for .iloc[-1]
        
        # Calculate Industry Momentum
        industry_momentum = self.calculate_industry_momentum(data)
        
        # Add additional information to results
        rs_with_info = pd.DataFrame({
            'Relative_Strength': rs_scores,
            'Industry': rs_scores.index.map(self.stock_industry_map),
            'Company': rs_scores.index.map(dict(zip(self.bse500_list['Symbol'], 
                                                self.bse500_list['Company'])))
        })
        
        return {
            'relative_strength': rs_with_info,
            'industry_momentum': industry_momentum,
            'raw_data': data
        }

# def main():
    
#     csv_path = "best_stock.py/Equity (1).csv"  ## this is where you give the base list of your stock which i have shared 
    
#     # Initialize analyzer
#     analyzer = BSEStockAnalyzer(csv_path)
    
#     # Run analysis
#     print("Starting BSE market analysis...")
#     results = analyzer.analyze_market()
    
#     if results:
#         print("\nTop 10 Stocks by Relative Strength:")
#         print(results['relative_strength'].head(10))
        
#         print("\nIndustry Momentum Rankings:")
#         print(results['industry_momentum'])
        
#         # Save results to CSV
#         timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
#         results['relative_strength'].to_csv(f'bse_relative_strength_rankings_{timestamp}.csv')
#         results['industry_momentum'].to_csv(f'bse_industry_momentum_rankings_{timestamp}.csv')
#         results['raw_data'].to_csv(f'bse_stock_data_{timestamp}.csv')
#         print(f"\nResults have been saved to CSV files with timestamp {timestamp}")

# if __name__ == "__main__":
#     main()