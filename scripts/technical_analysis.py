import base64
import io
import numpy as np
import pandas as pd
import yfinance as yf
from datetime import datetime, timedelta
import matplotlib.pyplot as plt
from matplotlib.dates import DateFormatter
import matplotlib.ticker as ticker
from typing import List, Dict, Tuple
from neo4j import GraphDatabase
from dataclasses import dataclass


@dataclass
class NewsItem:
    title: str
    publisher: str
    published_date: str
    url: str
    content: str
    sentiment: str

class Neo4jNewsRetriever:
    def __init__(self, uri="neo4j+s://9a89da2e.databases.neo4j.io",
                 user="neo4j",
                 password="6KaR1gdJgJpZDJBrpvGU4G3TpRzunffbYcCU3-v8Aeg"):
        self.driver = GraphDatabase.driver(uri, auth=(user, password))

    def close(self):
        self.driver.close()

    def get_stock_news(self, symbol: str) -> List[NewsItem]:
        with self.driver.session() as session:
            clean_symbol = symbol.replace('.NS', '.NS')

            query = """
            MATCH (na:NewsArticle)-[:MENTIONS]->(c:Company {ticker: $symbol})
            RETURN na.title AS title,
                   na.link AS link,
                   na.publisher AS publisher,
                   na.detailed_time AS published_date,
                   na.content AS content,
                   na.sentiment AS sentiment
            ORDER BY na.detailed_time DESC
            LIMIT 2
            """

            results = session.run(query, symbol=clean_symbol)
            news_items = []

            for record in results:
                news_item = NewsItem(
                    title=record['title'],
                    publisher=record['publisher'],
                    published_date=record['published_date'],
                    url=record['link'],
                    content=record['content'][:200] + '...' if record['content'] else 'No content available',
                    sentiment=record['sentiment']
                )
                news_items.append(news_item)

            return news_items

class UniversalStockAnalyzer:
    def __init__(self):
        self.benchmarks = {
            'US': '^GSPC',    # S&P 500
            'IN': '^NSEI',    # NIFTY 50
            'UK': '^FTSE',    # FTSE 100
            'JP': '^N225',    # Nikkei 225
            'HK': '^HSI'      # Hang Seng
        }
        self.news_retriever = Neo4jNewsRetriever()

    def detect_market(self, ticker: str) -> str:
        if ticker.endswith('.NS'):
            return 'IN'
        elif ticker.endswith('.L'):
            return 'UK'
        elif ticker.endswith('.T'):
            return 'JP'
        elif ticker.endswith('.HK'):
            return 'HK'
        else:
            return 'US'

    def format_currency(self, value: float, market: str) -> str:
        currency_symbols = {
            'US': '$',
            'IN': '₹',
            'UK': '£',
            'JP': '¥',
            'HK': 'HK$'
        }
        symbol = currency_symbols.get(market, '$')
        return f"{symbol}{value:,.2f}"

    def create_price_chart(self, stock_data: pd.DataFrame, technical_data: pd.DataFrame) -> str:
        plt.style.use('bmh')
        fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(15, 10), height_ratios=[3, 1], gridspec_kw={'hspace': 0.3})

        # Price and MA plot
        ax1.plot(stock_data.index, stock_data['Close'], label='Close Price', color='black', alpha=0.7)
        ax1.plot(technical_data.index, technical_data['SMA_50'], label='50-day MA', color='orange')
        ax1.plot(technical_data.index, technical_data['SMA_200'], label='200-day MA', color='blue')
        
        # Customize price plot
        ax1.set_title('Price and Volume Analysis', fontsize=12, pad=10)
        ax1.set_ylabel('Price')
        ax1.grid(True, alpha=0.3)
        ax1.legend()

        # Volume plot
        ax2.bar(stock_data.index, stock_data['Volume'], color='gray', alpha=0.5)
        ax2.set_ylabel('Volume')
        ax2.grid(True, alpha=0.3)

        # Format dates
        date_formatter = DateFormatter('%Y-%m-%d')
        ax2.xaxis.set_major_formatter(date_formatter)
        plt.xticks(rotation=45)

        # Convert plot to base64 string
        buffer = io.BytesIO()
        plt.savefig(buffer, format='png', bbox_inches='tight', dpi=300)
        buffer.seek(0)
        image_png = buffer.getvalue()
        buffer.close()
        plt.close()

        return base64.b64encode(image_png).decode('utf-8')

    def create_technical_chart(self, technical_data: pd.DataFrame) -> str:
        plt.style.use('bmh')
        fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(15, 10), height_ratios=[1, 1], gridspec_kw={'hspace': 0.3})

        # RSI Plot
        ax1.plot(technical_data.index, technical_data['RSI'], label='RSI', color='purple')
        ax1.axhline(y=70, color='r', linestyle='--', alpha=0.5)
        ax1.axhline(y=30, color='g', linestyle='--', alpha=0.5)
        ax1.set_ylabel('RSI')
        ax1.set_title('Technical Indicators', fontsize=12, pad=10)
        ax1.grid(True, alpha=0.3)
        ax1.legend()

        # MACD Plot
        ax2.plot(technical_data.index, technical_data['MACD'], label='MACD', color='blue')
        ax2.plot(technical_data.index, technical_data['Signal_Line'], label='Signal Line', color='red')
        ax2.set_ylabel('MACD')
        ax2.grid(True, alpha=0.3)
        ax2.legend()

        # Format dates
        date_formatter = DateFormatter('%Y-%m-%d')
        ax2.xaxis.set_major_formatter(date_formatter)
        plt.xticks(rotation=45)

        # Convert plot to base64 string
        buffer = io.BytesIO()
        plt.savefig(buffer, format='png', bbox_inches='tight', dpi=300)
        buffer.seek(0)
        image_png = buffer.getvalue()
        buffer.close()
        plt.close()

        return base64.b64encode(image_png).decode('utf-8')

    # def fetch_data(self, ticker: str, lookback_years: int = 2) -> Dict:
    #     end_date = datetime.now()
    #     start_date = end_date - timedelta(days=365 * lookback_years)

    #     try:
    #         stock = yf.Ticker(ticker)
    #         market = self.detect_market(ticker)
    #         benchmark_ticker = self.benchmarks[market]

    #         stock_data = stock.history(start=start_date, end=end_date)
    #         benchmark_data = yf.download(benchmark_ticker, start=start_date, end=end_date)

    #         if stock_data.empty:
    #             raise ValueError(f"No data found for {ticker}")

    #         info = stock.info

    #         # Fetch news data
    #         news_items = self.news_retriever.get_stock_news(ticker)

    #         return {
    #             'stock_data': stock_data,
    #             'benchmark_data': benchmark_data,
    #             'info': info,
    #             'market': market,
    #             'news': news_items
    #         }
    #     except Exception as e:
    #         print(f"Error fetching data: {str(e)}")
    #         return None
    def fetch_data(self, ticker: str, lookback_years: int = 2) -> Dict:
        end_date = datetime.now()
        start_date = end_date - timedelta(days=365 * lookback_years)

        try:
            stock = yf.Ticker(ticker)
            market = self.detect_market(ticker)
            benchmark_ticker = self.benchmarks[market]

            # Fetch data with explicit timezone handling
            stock_data = stock.history(start=start_date, end=end_date)
            benchmark_data = yf.download(benchmark_ticker, start=start_date, end=end_date)

            # Convert both indexes to timezone-naive
            stock_data.index = stock_data.index.tz_localize(None)
            benchmark_data.index = benchmark_data.index.tz_localize(None)

            if stock_data.empty:
                raise ValueError(f"No data found for {ticker}")

            info = stock.info

            # Fetch news data
            news_items = self.news_retriever.get_stock_news(ticker)

            return {
                'stock_data': stock_data,
                'benchmark_data': benchmark_data,
                'info': info,
                'market': market,
                'news': news_items
            }
        except Exception as e:
            print(f"Error fetching data: {str(e)}")
            return None

    def calculate_technical_indicators(self, data: pd.DataFrame) -> pd.DataFrame:
        df = data.copy()

        # Moving averages
        df['SMA_50'] = df['Close'].rolling(window=50).mean()
        df['SMA_200'] = df['Close'].rolling(window=200).mean()

        # RSI
        delta = df['Close'].diff()
        gain = (delta.where(delta > 0, 0)).rolling(window=14).mean()
        loss = (-delta.where(delta < 0, 0)).rolling(window=14).mean()
        rs = gain / loss
        df['RSI'] = 100 - (100 / (1 + rs))

        # MACD
        exp1 = df['Close'].ewm(span=12, adjust=False).mean()
        exp2 = df['Close'].ewm(span=26, adjust=False).mean()
        df['MACD'] = exp1 - exp2
        df['Signal_Line'] = df['MACD'].ewm(span=9, adjust=False).mean()

        # Bollinger Bands
        df['BB_middle'] = df['Close'].rolling(window=20).mean()
        df['BB_upper'] = df['BB_middle'] + 2 * df['Close'].rolling(window=20).std()
        df['BB_lower'] = df['BB_middle'] - 2 * df['Close'].rolling(window=20).std()

        return df

    def calculate_risk_metrics(self, stock_data: pd.DataFrame, benchmark_data: pd.DataFrame) -> Dict:
        stock_returns = stock_data['Close'].pct_change()
        bench_returns = benchmark_data['Adj Close'].pct_change()

        covar = stock_returns.cov(bench_returns)
        bench_var = bench_returns.var()
        beta = covar / bench_var if isinstance(bench_var, float) else float(bench_var.iloc[0])

        risk_free_rate = 0.03
        stock_mean_return = float(stock_returns.mean() * 252)
        bench_mean_return = float(bench_returns.mean() * 252)
        alpha = stock_mean_return - (risk_free_rate + beta * (bench_mean_return - risk_free_rate))

        volatility = float(stock_returns.std() * np.sqrt(252))
        sharpe_ratio = (stock_mean_return - risk_free_rate) / volatility

        cumulative_returns = (1 + stock_returns).cumprod()
        rolling_max = cumulative_returns.expanding().max()
        drawdowns = cumulative_returns / rolling_max - 1
        max_drawdown = float(drawdowns.min())

        return {
            'beta': beta,
            'alpha': alpha,
            'volatility': volatility,
            'sharpe_ratio': sharpe_ratio,
            'max_drawdown': max_drawdown,
            'avg_daily_return': float(stock_returns.mean()),
            'return_std': float(stock_returns.std())
        }

    def analyze_news_sentiment(self, news_items: List[NewsItem]) -> Dict:
        if not news_items:
            return {
                'overall_sentiment': 'Neutral',
                'sentiment_trend': 'Neutral',
                'sentiment_summary': 'No recent news available'
            }

        sentiment_map = {
            'positive': 1,
            'negative': -1,
            'neutral': 0
        }

        sentiments = [sentiment_map[item.sentiment.lower()] for item in news_items]
        avg_sentiment = np.mean(sentiments)

        if len(sentiments) >= 2:
            recent_sentiment = np.mean(sentiments[:2])
            older_sentiment = np.mean(sentiments[-2:])
            trend = 'Improving' if recent_sentiment > older_sentiment else \
                   'Declining' if recent_sentiment < older_sentiment else 'Stable'
        else:
            trend = 'Stable'

        if avg_sentiment > 0.3:
            summary = 'Strongly Positive'
        elif avg_sentiment > 0:
            summary = 'Slightly Positive'
        elif avg_sentiment < -0.3:
            summary = 'Strongly Negative'
        elif avg_sentiment < 0:
            summary = 'Slightly Negative'
        else:
            summary = 'Neutral'

        return {
            'overall_sentiment': summary,
            'sentiment_trend': trend,
            'sentiment_summary': f"{summary} with a {trend.lower()} trend"
        }

    def generate_report(self, ticker: str) -> Dict:
        data = self.fetch_data(ticker)
        if not data:
            return None

        stock_data = data['stock_data']
        benchmark_data = data['benchmark_data']
        info = data['info']
        market = data['market']
        news_items = data['news']

        technical_data = self.calculate_technical_indicators(stock_data)
        risk_metrics = self.calculate_risk_metrics(stock_data, benchmark_data)
        news_analysis = self.analyze_news_sentiment(news_items)

        # Generate charts
        price_chart = self.create_price_chart(stock_data, technical_data)
        technical_chart = self.create_technical_chart(technical_data)

        current_price = float(stock_data['Close'].iloc[-1])
        sma_50 = float(technical_data['SMA_50'].iloc[-1])
        sma_200 = float(technical_data['SMA_200'].iloc[-1])
        rsi = float(technical_data['RSI'].iloc[-1])

        technical_signals = {
            'SMA_50': sma_50,
            'SMA_200': sma_200,
            'RSI': rsi,
            'Price_vs_SMA_50': 'Above' if current_price > sma_50 else 'Below',
            'Price_vs_SMA_200': 'Above' if current_price > sma_200 else 'Below',
            'RSI_trend': 'Overbought' if rsi > 70 else 'Oversold' if rsi < 30 else 'Neutral'
        }

        return {
            'company_info': {
                'name': info.get('shortName', ticker),
                'current_price': self.format_currency(current_price, market),
                '52_week_high': self.format_currency(info.get('fiftyTwoWeekHigh', 'N/A'), market),
                '52_week_low': self.format_currency(info.get('fiftyTwoWeekLow', 'N/A'), market),
                'sector': info.get('sector', 'N/A')
            },
            'technical_signals': technical_signals,
            'risk_metrics': risk_metrics,
            'news_analysis': news_analysis,
            'charts': {
                'price_chart': price_chart,
                'technical_chart': technical_chart
            }
        }


