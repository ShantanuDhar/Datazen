
# # from flask import Flask, jsonify
# # from flask_cors import CORS
# # import numpy as np
# # import pandas as pd
# # import yfinance as yf
# # from datetime import datetime, timedelta
# # from neo4j import GraphDatabase
# # from dataclasses import dataclass
# # from typing import List, Dict, Optional

# # @dataclass
# # class NewsItem:
# #     title: str
# #     publisher: str
# #     published_date: str
# #     url: str
# #     content: str
# #     sentiment: float

# # @dataclass
# # class StockAnalysis:
# #     symbol: str
# #     final_score: float
# #     short_term_strength: float
# #     medium_term_strength: float
# #     long_term_strength: float
# #     sector_dominance: float
# #     consistency: float
# #     market_adaptability: float
# #     news: List[NewsItem]

# # class Neo4jNewsRetriever:
# #     def __init__(self, uri="neo4j+s://c6227adb.databases.neo4j.io",
# #                  user="neo4j",
# #                  password="bzG73whvahGl5iTCm0jXkfEnlw1DdQOPXxrjNdtXHTs"):
# #         self.driver = GraphDatabase.driver(uri, auth=(user, password))

# #     def close(self):
# #         self.driver.close()

# #     def get_stock_news(self, symbol: str) -> List[NewsItem]:
# #         with self.driver.session() as session:
# #             clean_symbol = symbol.replace('.NS', '.NS')

# #             query = """
# #             MATCH (na:NewsArticle)-[:MENTIONS]->(c:Company {ticker: $symbol})
# #             RETURN na.title AS title,
# #                    na.link AS link,
# #                    na.publisher AS publisher,
# #                    na.detailed_time AS published_date,
# #                    na.content AS content,
# #                    na.sentiment AS sentiment
# #             ORDER BY na.detailed_time DESC
# #             LIMIT 1
# #             """

# #             results = session.run(query, symbol=clean_symbol)
# #             news_items = []

# #             for record in results:
# #                 news_item = NewsItem(
# #                     title=record['title'],
# #                     publisher=record['publisher'],
# #                     published_date=record['published_date'],
# #                     url=record['link'],
# #                     content=record['content'][:200] + '...' if record['content'] else 'No content available',
# #                     sentiment=record['sentiment']
# #                 )
# #                 news_items.append(news_item)

# #             return news_items

# # class IntegratedStockAnalyzer:
# #     def __init__(self, benchmark='^NSEI'):
# #         self.benchmark = benchmark
# #         self.sector_stocks = {
# #             'PVTB': ['HDFCBANK.NS', 'ICICIBANK.NS', 'KOTAKBANK.NS', 'AXISBANK.NS', 'INDUSINDBK.NS'],
# #             'IT': ['INFY.NS', 'TCS.NS', 'WIPRO.NS', 'TECHM.NS', 'HCLTECH.NS'],
# #             'Telecom': ['BHARTIARTL.NS', 'RELIANCE.NS', 'IDEA.NS', 'MTNL.NS', 'TTML.NS'],
# #             'Cement': ['ULTRACEMCO.NS', 'ACC.NS', 'SHREECEM.NS', 'AMBUJACEM.NS', 'RAMCOCEM.NS'],
# #             'Pharma': ['SUNPHARMA.NS', 'CIPLA.NS', 'DRREDDY.NS', 'AUROPHARMA.NS', 'BIOCON.NS'],
# #             'Infra': ['LT.NS', 'BEML.NS', 'GMRINFRA.NS', 'IRB.NS', 'DLF.NS'],
# #             'NBFC': ['BAJFINANCE.NS', 'MUTHOOTFIN.NS', 'LICHSGFIN.NS', 'CHOLAFIN.NS', 'HDFCAMC.NS'],
# #             'FMCG': ['HINDUNILVR.NS', 'ITC.NS', 'NESTLEIND.NS', 'BRITANNIA.NS', 'DABUR.NS'],
# #             'Metal': ['TATASTEEL.NS', 'HINDALCO.NS', 'JSWSTEEL.NS', 'VEDL.NS', 'SAIL.NS'],
# #             'Auto': ['MARUTI.NS', 'TATAMOTORS.NS', 'BAJAJ-AUTO.NS', 'EICHERMOT.NS', 'TVSMOTOR.NS']
# #         }
# #         self.news_retriever = Neo4jNewsRetriever()

# #     def fetch_stock_data(self, symbols: List[str], start_date: str, end_date: str) -> pd.DataFrame:
# #         try:
# #             data = yf.download(symbols, start=start_date, end=end_date)
# #             return data['Adj Close']
# #         except Exception as e:
# #             print(f"Error fetching data: {e}")
# #             return pd.DataFrame()

# #     def calculate_relative_strength(self, stock_data: pd.Series,
# #                                   periods: List[int] = [30, 90, 180]) -> Dict[str, float]:
# #         strengths = {}
# #         for period in periods:
# #             if len(stock_data) > period:
# #                 returns = (stock_data.iloc[-1] - stock_data.iloc[-period-1]) / stock_data.iloc[-period-1]
# #                 strengths[f'{period}d'] = returns
# #             else:
# #                 strengths[f'{period}d'] = 0
# #         return strengths

# #     def calculate_sector_dominance(self, stock_return: float) -> float:
# #         return stock_return

# #     def analyze_cycles(self, stock_data: pd.Series) -> float:
# #         monthly_returns = stock_data.pct_change().resample('ME').mean()
# #         cycle_score = monthly_returns.std() * np.sqrt(12)
# #         return cycle_score

# #     def calculate_market_impact(self, stock_data: pd.Series,
# #                               benchmark_data: pd.DataFrame) -> Dict[str, float]:
# #         stock_monthly = stock_data.pct_change().resample('ME').mean()
# #         bench_monthly = benchmark_data.iloc[:, 0].pct_change().resample('ME').mean()

# #         aligned_data = pd.concat([stock_monthly, bench_monthly], axis=1).dropna()

# #         if aligned_data.empty:
# #             return {'up_market': 0, 'down_market': 0, 'market_adaptability': 0}

# #         stock_returns = aligned_data.iloc[:, 0]
# #         bench_returns = aligned_data.iloc[:, 1]

# #         up_market = stock_returns[bench_returns > 0].mean()
# #         down_market = stock_returns[bench_returns < 0].mean()

# #         return {
# #             'up_market': up_market if not pd.isna(up_market) else 0,
# #             'down_market': down_market if not pd.isna(down_market) else 0,
# #             'market_adaptability': (up_market - down_market) if not pd.isna(up_market) and not pd.isna(down_market) else 0
# #         }

# #     def calculate_consistency_score(self, stock_data: pd.Series) -> float:
# #         monthly_returns = stock_data.pct_change().resample('ME').mean()
# #         positive_months = (monthly_returns > 0).sum() / len(monthly_returns)
# #         return positive_months

# #     def analyze_stock(self, symbol: str, stock_data: pd.DataFrame,
# #                      sector_returns: pd.Series, benchmark_data: pd.DataFrame) -> Optional[StockAnalysis]:
# #         try:
# #             symbol_data = stock_data[symbol].dropna()

# #             if len(symbol_data) < 180:
# #                 return None

# #             strength_scores = self.calculate_relative_strength(symbol_data)
# #             dominance = self.calculate_sector_dominance(sector_returns[symbol])
# #             cycle_score = self.analyze_cycles(symbol_data)
# #             market_impact = self.calculate_market_impact(symbol_data, benchmark_data)
# #             consistency = self.calculate_consistency_score(symbol_data)

# #             final_score = (
# #                 0.25 * (strength_scores['30d'] + 1) +
# #                 0.20 * (strength_scores['90d'] + 1) +
# #                 0.15 * (strength_scores['180d'] + 1) +
# #                 0.15 * (dominance + 1) +
# #                 0.10 * consistency +
# #                 0.15 * (market_impact['market_adaptability'] + 1)
# #             )

# #             # Fetch news for the stock
# #             news_items = self.news_retriever.get_stock_news(symbol)

# #             return StockAnalysis(
# #                 symbol=symbol,
# #                 final_score=final_score,
# #                 short_term_strength=strength_scores['30d'],
# #                 medium_term_strength=strength_scores['90d'],
# #                 long_term_strength=strength_scores['180d'],
# #                 sector_dominance=dominance,
# #                 consistency=consistency,
# #                 market_adaptability=market_impact['market_adaptability'],
# #                 news=news_items
# #             )

# #         except Exception as e:
# #             print(f"Error analyzing {symbol}: {e}")
# #             return None

# #     def analyze_all_stocks(self) -> Dict[str, List[StockAnalysis]]:
# #         end_date = datetime.now().strftime('%Y-%m-%d')
# #         start_date = (datetime.now() - timedelta(days=365)).strftime('%Y-%m-%d')

# #         benchmark_data = self.fetch_stock_data([self.benchmark], start_date, end_date)
# #         sector_analyses = {}

# #         for sector, symbols in self.sector_stocks.items():
# #             sector_analyses[sector] = []

# #             try:
# #                 stock_data = self.fetch_stock_data(symbols, start_date, end_date)
# #                 if stock_data.empty:
# #                     continue

# #                 sector_returns = stock_data.pct_change(periods=90).iloc[-1]

# #                 for symbol in symbols:
# #                     if symbol not in stock_data.columns:
# #                         continue

# #                     analysis = self.analyze_stock(symbol, stock_data, sector_returns, benchmark_data)
# #                     if analysis:
# #                         sector_analyses[sector].append(analysis)

# #                 # Sort stocks within each sector by final score and keep top 2
# #                 sector_analyses[sector] = sorted(
# #                     sector_analyses[sector],
# #                     key=lambda x: x.final_score,
# #                     reverse=True
# #                 )[:2]

# #             except Exception as e:
# #                 print(f"Error processing sector {sector}: {e}")
# #                 continue

# #         return sector_analyses

# # def format_output(analysis: StockAnalysis) -> str:
# #     """Format a single stock analysis for display"""
# #     output = [
# #         f"\nStock Analysis for {analysis.symbol}",
# #         "-" * 40,
# #         f"Final Score: {analysis.final_score:.4f}",
# #         f"Short-term Strength: {analysis.short_term_strength:.4f}",
# #         f"Medium-term Strength: {analysis.medium_term_strength:.4f}",
# #         f"Long-term Strength: {analysis.long_term_strength:.4f}",
# #         f"Sector Dominance: {analysis.sector_dominance:.4f}",
# #         f"Consistency: {analysis.consistency:.4f}",
# #         f"Market Adaptability: {analysis.market_adaptability:.4f}",
# #         "\nRelated News:",
# #     ]

# #     for idx, news in enumerate(analysis.news, 1):
# #         output.extend([
# #             f"\nNews {idx}:",
# #             f"Title: {news.title}",
# #             f"Publisher: {news.publisher}",
# #             f"Date: {news.published_date}",
# #             f"Sentiment: {news.sentiment}",
# #             f"URL: {news.url}",
# #             f"Summary: {news.content}"
# #         ])

# #     return "\n".join(output)



# from flask import Flask, jsonify
# import numpy as np
# import pandas as pd
# import yfinance as yf
# from datetime import datetime, timedelta, date
# from neo4j import GraphDatabase
# from dataclasses import dataclass
# from typing import List, Dict, Optional
# from flask_cors import CORS
# import json

# @dataclass
# class NewsItem:
#     title: str
#     publisher: str
#     published_date: str
#     url: str
#     content: str
#     sentiment: float

#     def to_dict(self):
#         return {
#             'title': self.title,
#             'publisher': self.publisher,
#             'published_date': self.published_date,
#             'url': self.url,
#             'content': self.content,
#             'sentiment': float(self.sentiment) if self.sentiment is not None else None
#         }

# @dataclass
# class StockAnalysis:
#     symbol: str
#     final_score: float
#     short_term_strength: float
#     medium_term_strength: float
#     long_term_strength: float
#     sector_dominance: float
#     consistency: float
#     market_adaptability: float
#     news: List[NewsItem]

#     def to_dict(self):
#         return {
#             'symbol': self.symbol,
#             'final_score': float(self.final_score),
#             'short_term_strength': float(self.short_term_strength),
#             'medium_term_strength': float(self.medium_term_strength),
#             'long_term_strength': float(self.long_term_strength),
#             'sector_dominance': float(self.sector_dominance),
#             'consistency': float(self.consistency),
#             'market_adaptability': float(self.market_adaptability),
#             'news': [news.to_dict() for news in self.news]
#         }

# class Neo4jNewsRetriever:
#     def __init__(self, uri="neo4j+s://c6227adb.databases.neo4j.io",
#                  user="neo4j",
#                  password="bzG73whvahGl5iTCm0jXkfEnlw1DdQOPXxrjNdtXHTs"):
#         self.driver = GraphDatabase.driver(uri, auth=(user, password))

#     def close(self):
#         self.driver.close()

#     def get_stock_news(self, symbol: str) -> List[NewsItem]:
#         with self.driver.session() as session:
#             clean_symbol = symbol.replace('.NS', '.NS')

#             query = """
#             MATCH (na:NewsArticle)-[:MENTIONS]->(c:Company {ticker: $symbol})
#             RETURN na.title AS title,
#                    na.link AS link,
#                    na.publisher AS publisher,
#                    na.detailed_time AS published_date,
#                    na.content AS content,
#                    na.sentiment AS sentiment
#             ORDER BY na.detailed_time DESC
#             LIMIT 1
#             """

#             results = session.run(query, symbol=clean_symbol)
#             news_items = []

#             for record in results:
#                 try:
#                     sentiment = float(record['sentiment']) if record['sentiment'] is not None else None
#                 except (ValueError, TypeError):
#                     sentiment = None
                    
#                 news_item = NewsItem(
#                     title=record['title'] or '',
#                     publisher=record['publisher'] or '',
#                     published_date=str(record['published_date']) if record['published_date'] else '',
#                     url=record['link'] or '',
#                     content=record['content'][:200] + '...' if record['content'] else 'No content available',
#                     sentiment=sentiment
#                 )
#                 news_items.append(news_item)

#             return news_items

# class IntegratedStockAnalyzer:
#     def __init__(self, benchmark='^NSEI'):
#         self.benchmark = benchmark
#         self.sector_stocks = {
#             'PVTB': ['HDFCBANK.NS', 'ICICIBANK.NS', 'KOTAKBANK.NS', 'AXISBANK.NS', 'INDUSINDBK.NS'],
#             'IT': ['INFY.NS', 'TCS.NS', 'WIPRO.NS', 'TECHM.NS', 'HCLTECH.NS'],
#             'Telecom': ['BHARTIARTL.NS', 'RELIANCE.NS', 'IDEA.NS', 'MTNL.NS', 'TTML.NS'],
#             'Cement': ['ULTRACEMCO.NS', 'ACC.NS', 'SHREECEM.NS', 'AMBUJACEM.NS', 'RAMCOCEM.NS'],
#             'Pharma': ['SUNPHARMA.NS', 'CIPLA.NS', 'DRREDDY.NS', 'AUROPHARMA.NS', 'BIOCON.NS'],
#             'Infra': ['LT.NS', 'BEML.NS', 'GMRINFRA.NS', 'IRB.NS', 'DLF.NS'],
#             'NBFC': ['BAJFINANCE.NS', 'MUTHOOTFIN.NS', 'LICHSGFIN.NS', 'CHOLAFIN.NS', 'HDFCAMC.NS'],
#             'FMCG': ['HINDUNILVR.NS', 'ITC.NS', 'NESTLEIND.NS', 'BRITANNIA.NS', 'DABUR.NS'],
#             'Metal': ['TATASTEEL.NS', 'HINDALCO.NS', 'JSWSTEEL.NS', 'VEDL.NS', 'SAIL.NS'],
#             'Auto': ['MARUTI.NS', 'TATAMOTORS.NS', 'BAJAJ-AUTO.NS', 'EICHERMOT.NS', 'TVSMOTOR.NS']
#         }
#         self.news_retriever = Neo4jNewsRetriever()

#     def fetch_stock_data(self, symbols: List[str], start_date: str, end_date: str) -> pd.DataFrame:
#         try:
#             data = yf.download(symbols, start=start_date, end=end_date)
#             return data['Adj Close']
#         except Exception as e:
#             print(f"Error fetching data: {e}")
#             return pd.DataFrame()

#     def calculate_relative_strength(self, stock_data: pd.Series,
#                                   periods: List[int] = [30, 90, 180]) -> Dict[str, float]:
#         strengths = {}
#         for period in periods:
#             if len(stock_data) > period:
#                 returns = (stock_data.iloc[-1] - stock_data.iloc[-period-1]) / stock_data.iloc[-period-1]
#                 strengths[f'{period}d'] = float(returns)
#             else:
#                 strengths[f'{period}d'] = 0.0
#         return strengths

#     def calculate_sector_dominance(self, stock_return: float) -> float:
#         return float(stock_return)

#     def analyze_cycles(self, stock_data: pd.Series) -> float:
#         monthly_returns = stock_data.pct_change().resample('ME').mean()
#         cycle_score = monthly_returns.std() * np.sqrt(12)
#         return float(cycle_score)

#     def calculate_market_impact(self, stock_data: pd.Series,
#                               benchmark_data: pd.DataFrame) -> Dict[str, float]:
#         stock_monthly = stock_data.pct_change().resample('ME').mean()
#         bench_monthly = benchmark_data.iloc[:, 0].pct_change().resample('ME').mean()

#         aligned_data = pd.concat([stock_monthly, bench_monthly], axis=1).dropna()

#         if aligned_data.empty:
#             return {'up_market': 0.0, 'down_market': 0.0, 'market_adaptability': 0.0}

#         stock_returns = aligned_data.iloc[:, 0]
#         bench_returns = aligned_data.iloc[:, 1]

#         up_market = float(stock_returns[bench_returns > 0].mean() if not pd.isna(stock_returns[bench_returns > 0].mean()) else 0.0)
#         down_market = float(stock_returns[bench_returns < 0].mean() if not pd.isna(stock_returns[bench_returns < 0].mean()) else 0.0)

#         return {
#             'up_market': up_market,
#             'down_market': down_market,
#             'market_adaptability': float(up_market - down_market)
#         }

#     def calculate_consistency_score(self, stock_data: pd.Series) -> float:
#         monthly_returns = stock_data.pct_change().resample('ME').mean()
#         positive_months = (monthly_returns > 0).sum() / len(monthly_returns)
#         return float(positive_months)

#     def analyze_stock(self, symbol: str, stock_data: pd.DataFrame,
#                      sector_returns: pd.Series, benchmark_data: pd.DataFrame) -> Optional[StockAnalysis]:
#         try:
#             symbol_data = stock_data[symbol].dropna()

#             if len(symbol_data) < 180:
#                 return None

#             strength_scores = self.calculate_relative_strength(symbol_data)
#             dominance = self.calculate_sector_dominance(sector_returns[symbol])
#             cycle_score = self.analyze_cycles(symbol_data)
#             market_impact = self.calculate_market_impact(symbol_data, benchmark_data)
#             consistency = self.calculate_consistency_score(symbol_data)

#             final_score = float(
#                 0.25 * (strength_scores['30d'] + 1) +
#                 0.20 * (strength_scores['90d'] + 1) +
#                 0.15 * (strength_scores['180d'] + 1) +
#                 0.15 * (dominance + 1) +
#                 0.10 * consistency +
#                 0.15 * (market_impact['market_adaptability'] + 1)
#             )

#             news_items = self.news_retriever.get_stock_news(symbol)

#             return StockAnalysis(
#                 symbol=symbol,
#                 final_score=final_score,
#                 short_term_strength=strength_scores['30d'],
#                 medium_term_strength=strength_scores['90d'],
#                 long_term_strength=strength_scores['180d'],
#                 sector_dominance=dominance,
#                 consistency=consistency,
#                 market_adaptability=market_impact['market_adaptability'],
#                 news=news_items
#             )

#         except Exception as e:
#             print(f"Error analyzing {symbol}: {e}")
#             return None

#     def analyze_all_stocks(self) -> Dict[str, List[StockAnalysis]]:
#         end_date = datetime.now().strftime('%Y-%m-%d')
#         start_date = (datetime.now() - timedelta(days=365)).strftime('%Y-%m-%d')
#         print(f"Fetching data from {start_date} to {end_date}")

#         benchmark_data = self.fetch_stock_data([self.benchmark], start_date, end_date)
#         sector_analyses = {}

#         for sector, symbols in self.sector_stocks.items():
#             sector_analyses[sector] = []

#             try:
#                 stock_data = self.fetch_stock_data(symbols, start_date, end_date)
#                 if stock_data.empty:
#                     continue

#                 sector_returns = stock_data.pct_change(periods=90).iloc[-1]

#                 for symbol in symbols:
#                     if symbol not in stock_data.columns:
#                         continue

#                     analysis = self.analyze_stock(symbol, stock_data, sector_returns, benchmark_data)
#                     if analysis:
#                         sector_analyses[sector].append(analysis)

#                 sector_analyses[sector] = sorted(
#                     sector_analyses[sector],
#                     key=lambda x: x.final_score,
#                     reverse=True
#                 )[:2]

#             except Exception as e:
#                 print(f"Error processing sector {sector}: {e}")
#                 continue

#         return sector_analyses

import numpy as np
import pandas as pd
import yfinance as yf
from datetime import datetime, timedelta, date
from neo4j import GraphDatabase
from dataclasses import dataclass
from typing import List, Dict, Optional



@dataclass
class NewsItem:
    title: str
    publisher: str
    published_date: str
    url: str
    content: str
    sentiment: float

    def to_dict(self):
        return {
            'title': self.title,
            'publisher': self.publisher,
            'published_date': self.published_date,
            'url': self.url,
            'content': self.content,
            'sentiment': float(self.sentiment) if self.sentiment is not None else None
        }

@dataclass
class StockAnalysis:
    symbol: str
    final_score: float
    short_term_strength: float
    medium_term_strength: float
    long_term_strength: float
    sector_dominance: float
    consistency: float
    market_adaptability: float
    news: List[NewsItem]

    def to_dict(self):
        return {
            'symbol': self.symbol,
            'final_score': float(self.final_score),
            'short_term_strength': float(self.short_term_strength),
            'medium_term_strength': float(self.medium_term_strength),
            'long_term_strength': float(self.long_term_strength),
            'sector_dominance': float(self.sector_dominance),
            'consistency': float(self.consistency),
            'market_adaptability': float(self.market_adaptability),
            'news': [news.to_dict() for news in self.news]
        }

class Neo4jNewsRetriever:
    def __init__(self, uri="neo4j+s://c6227adb.databases.neo4j.io",
                 user="neo4j",
                 password="bzG73whvahGl5iTCm0jXkfEnlw1DdQOPXxrjNdtXHTs"):
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
            LIMIT 1
            """

            results = session.run(query, symbol=clean_symbol)
            news_items = []

            for record in results:
                try:
                    sentiment = float(record['sentiment']) if record['sentiment'] is not None else None
                except (ValueError, TypeError):
                    sentiment = None
                    
                news_item = NewsItem(
                    title=record['title'] or '',
                    publisher=record['publisher'] or '',
                    published_date=str(record['published_date']) if record['published_date'] else '',
                    url=record['link'] or '',
                    content=record['content'][:200] + '...' if record['content'] else 'No content available',
                    sentiment=sentiment
                )
                news_items.append(news_item)

            return news_items

class IntegratedStockAnalyzer:
    def __init__(self, benchmark='^NSEI'):
        self.benchmark = benchmark
        self.sector_stocks = {
            'PVTB': ['HDFCBANK.NS', 'ICICIBANK.NS', 'KOTAKBANK.NS', 'AXISBANK.NS', 'INDUSINDBK.NS'],
            'IT': ['INFY.NS', 'TCS.NS', 'WIPRO.NS', 'TECHM.NS', 'HCLTECH.NS'],
            'Telecom': ['BHARTIARTL.NS', 'RELIANCE.NS', 'IDEA.NS', 'MTNL.NS', 'TTML.NS'],
            'Cement': ['ULTRACEMCO.NS', 'ACC.NS', 'SHREECEM.NS', 'AMBUJACEM.NS', 'RAMCOCEM.NS'],
            'Pharma': ['SUNPHARMA.NS', 'CIPLA.NS', 'DRREDDY.NS', 'AUROPHARMA.NS', 'BIOCON.NS'],
            'Infra': ['LT.NS', 'BEML.NS', 'GMRINFRA.NS', 'IRB.NS', 'DLF.NS'],
            'NBFC': ['BAJFINANCE.NS', 'MUTHOOTFIN.NS', 'LICHSGFIN.NS', 'CHOLAFIN.NS', 'HDFCAMC.NS'],
            'FMCG': ['HINDUNILVR.NS', 'ITC.NS', 'NESTLEIND.NS', 'BRITANNIA.NS', 'DABUR.NS'],
            'Metal': ['TATASTEEL.NS', 'HINDALCO.NS', 'JSWSTEEL.NS', 'VEDL.NS', 'SAIL.NS'],
            'Auto': ['MARUTI.NS', 'TATAMOTORS.NS', 'BAJAJ-AUTO.NS', 'EICHERMOT.NS', 'TVSMOTOR.NS']
        }
        self.news_retriever = Neo4jNewsRetriever()

    # def fetch_stock_data(self, symbols: List[str], start_date: str, end_date: str) -> pd.DataFrame:
    #     try:
    #         data = yf.download(symbols, start=start_date, end=end_date)
    #         return data['Adj Close']
    #     except Exception as e:
    #         print(f"Error fetching data: {e}")
    #         return pd.DataFrame()

    # def calculate_relative_strength(self, stock_data: pd.Series,
    #                               periods: List[int] = [30, 90, 180]) -> Dict[str, float]:
    #     strengths = {}
    #     for period in periods:
    #         if len(stock_data) > period:
    #             returns = (stock_data.iloc[-1] - stock_data.iloc[-period-1]) / stock_data.iloc[-period-1]
    #             strengths[f'{period}d'] = float(returns)
    #         else:
    #             strengths[f'{period}d'] = 0.0
    #     return strengths

    def calculate_sector_dominance(self, stock_return: float) -> float:
        return float(stock_return)

    def analyze_cycles(self, stock_data: pd.Series) -> float:
        monthly_returns = stock_data.pct_change().resample('ME').mean()
        cycle_score = monthly_returns.std() * np.sqrt(12)
        return float(cycle_score)

    # def calculate_market_impact(self, stock_data: pd.Series,
    #                           benchmark_data: pd.DataFrame) -> Dict[str, float]:
    #     stock_monthly = stock_data.pct_change().resample('ME').mean()
    #     bench_monthly = benchmark_data.iloc[:, 0].pct_change().resample('ME').mean()

    #     aligned_data = pd.concat([stock_monthly, bench_monthly], axis=1).dropna()

    #     if aligned_data.empty:
    #         return {'up_market': 0.0, 'down_market': 0.0, 'market_adaptability': 0.0}

    #     stock_returns = aligned_data.iloc[:, 0]
    #     bench_returns = aligned_data.iloc[:, 1]

    #     up_market = float(stock_returns[bench_returns > 0].mean() if not pd.isna(stock_returns[bench_returns > 0].mean()) else 0.0)
    #     down_market = float(stock_returns[bench_returns < 0].mean() if not pd.isna(stock_returns[bench_returns < 0].mean()) else 0.0)

    #     return {
    #         'up_market': up_market,
    #         'down_market': down_market,
    #         'market_adaptability': float(up_market - down_market)
    #     }

    # def calculate_consistency_score(self, stock_data: pd.Series) -> float:
    #     monthly_returns = stock_data.pct_change().resample('ME').mean()
    #     positive_months = (monthly_returns > 0).sum() / len(monthly_returns)
    #     return float(positive_months)

    # def analyze_stock(self, symbol: str, stock_data: pd.DataFrame,
    #                  sector_returns: pd.Series, benchmark_data: pd.DataFrame) -> Optional[StockAnalysis]:
    #     try:
    #         symbol_data = stock_data[symbol].dropna()

    #         if len(symbol_data) < 180:
    #             return None

    #         strength_scores = self.calculate_relative_strength(symbol_data)
    #         dominance = self.calculate_sector_dominance(sector_returns[symbol])
    #         cycle_score = self.analyze_cycles(symbol_data)
    #         market_impact = self.calculate_market_impact(symbol_data, benchmark_data)
    #         consistency = self.calculate_consistency_score(symbol_data)

    #         final_score = float(
    #             0.25 * (strength_scores['30d'] + 1) +
    #             0.20 * (strength_scores['90d'] + 1) +
    #             0.15 * (strength_scores['180d'] + 1) +
    #             0.15 * (dominance + 1) +
    #             0.10 * consistency +
    #             0.15 * (market_impact['market_adaptability'] + 1)
    #         )

    #         news_items = self.news_retriever.get_stock_news(symbol)

    #         return StockAnalysis(
    #             symbol=symbol,
    #             final_score=final_score,
    #             short_term_strength=strength_scores['30d'],
    #             medium_term_strength=strength_scores['90d'],
    #             long_term_strength=strength_scores['180d'],
    #             sector_dominance=dominance,
    #             consistency=consistency,
    #             market_adaptability=market_impact['market_adaptability'],
    #             news=news_items
    #         )

    #     except Exception as e:
    #         print(f"Error analyzing {symbol}: {e}")
    #         return None

    # def analyze_all_stocks(self) -> Dict[str, List[StockAnalysis]]:
    #     end_date = datetime.now().strftime('%Y-%m-%d')
    #     start_date = (datetime.now() - timedelta(days=365)).strftime('%Y-%m-%d')
    #     print(f"Fetching data from {start_date} to {end_date}")

    #     benchmark_data = self.fetch_stock_data([self.benchmark], start_date, end_date)
    #     sector_analyses = {}

    #     for sector, symbols in self.sector_stocks.items():
    #         sector_analyses[sector] = []

    #         try:
    #             stock_data = self.fetch_stock_data(symbols, start_date, end_date)
    #             if stock_data.empty:
    #                 continue

    #             sector_returns = stock_data.pct_change(periods=90).iloc[-1]

    #             for symbol in symbols:
    #                 if symbol not in stock_data.columns:
    #                     continue

    #                 analysis = self.analyze_stock(symbol, stock_data, sector_returns, benchmark_data)
    #                 if analysis:
    #                     sector_analyses[sector].append(analysis)

    #             sector_analyses[sector] = sorted(
    #                 sector_analyses[sector],
    #                 key=lambda x: x.final_score,
    #                 reverse=True
    #             )[:2]

    #         except Exception as e:
    #             print(f"Error processing sector {sector}: {e}")
    #             continue

    #     return sector_analyses

    def fetch_stock_data(self, symbols: List[str], start_date: str, end_date: str) -> pd.DataFrame:
        try:
            data = yf.download(symbols, start=start_date, end=end_date)
            if isinstance(data.columns, pd.MultiIndex):
                return data['Adj Close']
            return data  # If single symbol, return as is
        except Exception as e:
            print(f"Error fetching data: {e}")
            return pd.DataFrame()

    # def analyze_stock(self, symbol: str, stock_data: pd.DataFrame,
    #                 sector_returns: pd.Series, benchmark_data: pd.DataFrame) -> Optional[StockAnalysis]:
    #     try:
    #         # Handle both single and multiple stock cases
    #         if isinstance(stock_data.columns, pd.MultiIndex):
    #             symbol_data = stock_data[symbol].dropna()
    #         else:
    #             symbol_data = stock_data.dropna()

    #         if len(symbol_data) < 180:
    #             return None

    #         strength_scores = self.calculate_relative_strength(symbol_data)
            
    #         # Ensure sector_returns is properly accessed
    #         try:
    #             sector_return = sector_returns[symbol] if isinstance(sector_returns, pd.Series) else sector_returns
    #         except:
    #             sector_return = 0.0
                
    #         dominance = self.calculate_sector_dominance(sector_return)
    #         cycle_score = self.analyze_cycles(symbol_data)
    #         market_impact = self.calculate_market_impact(symbol_data, benchmark_data)
    #         consistency = self.calculate_consistency_score(symbol_data)

    #         final_score = float(
    #             0.25 * (strength_scores['30d'] + 1) +
    #             0.20 * (strength_scores['90d'] + 1) +
    #             0.15 * (strength_scores['180d'] + 1) +
    #             0.15 * (dominance + 1) +
    #             0.10 * consistency +
    #             0.15 * (market_impact['market_adaptability'] + 1)
    #         )

    #         news_items = self.news_retriever.get_stock_news(symbol)

    #         return StockAnalysis(
    #             symbol=symbol,
    #             final_score=final_score,
    #             short_term_strength=strength_scores['30d'],
    #             medium_term_strength=strength_scores['90d'],
    #             long_term_strength=strength_scores['180d'],
    #             sector_dominance=dominance,
    #             consistency=consistency,
    #             market_adaptability=market_impact['market_adaptability'],
    #             news=news_items
    #         )

    #     except Exception as e:
    #         print(f"Error analyzing {symbol}: {e}")
    #         return None

    def analyze_all_stocks(self) -> Dict[str, List[StockAnalysis]]:
        end_date = datetime.now().strftime('%Y-%m-%d')
        start_date = (datetime.now() - timedelta(days=365)).strftime('%Y-%m-%d')
        print(f"Fetching data from {start_date} to {end_date}")

        benchmark_data = self.fetch_stock_data([self.benchmark], start_date, end_date)
        sector_analyses = {}

        for sector, symbols in self.sector_stocks.items():
            sector_analyses[sector] = []

            try:
                stock_data = self.fetch_stock_data(symbols, start_date, end_date)
                if stock_data.empty:
                    continue

                # Calculate sector returns
                if isinstance(stock_data.columns, pd.MultiIndex):
                    sector_returns = stock_data.pct_change(periods=90).iloc[-1]
                else:
                    sector_returns = stock_data.pct_change(periods=90).iloc[-1]

                for symbol in symbols:
                    if isinstance(stock_data.columns, pd.MultiIndex):
                        if symbol not in stock_data.columns.levels[1]:
                            continue
                    else:
                        if symbol not in stock_data.columns:
                            continue

                    analysis = self.analyze_stock(symbol, stock_data, sector_returns, benchmark_data)
                    if analysis:
                        sector_analyses[sector].append(analysis)

                sector_analyses[sector] = sorted(
                    sector_analyses[sector],
                    key=lambda x: x.final_score,
                    reverse=True
                )[:2]

            except Exception as e:
                print(f"Error processing sector {sector}: {e}")
                continue
    
    def calculate_relative_strength(self, stock_data: pd.Series,
        periods: List[int] = [30, 90, 180]) -> Dict[str, float]:
        strengths = {}
        for period in periods:
            if len(stock_data) > period:
                try:
                    start_price = stock_data.iloc[-period-1]
                    end_price = stock_data.iloc[-1]
                    if isinstance(start_price, pd.Series):
                        start_price = start_price.iloc[0]
                    if isinstance(end_price, pd.Series):
                        end_price = end_price.iloc[0]
                    returns = (end_price - start_price) / start_price
                    strengths[f'{period}d'] = float(returns)
                except Exception as e:
                    print(f"Error calculating {period}d strength: {e}")
                    strengths[f'{period}d'] = 0.0
            else:
                strengths[f'{period}d'] = 0.0
        return strengths

    def calculate_sector_dominance(self, stock_return: float) -> float:
        try:
            if isinstance(stock_return, pd.Series):
                return float(stock_return.iloc[0])
            return float(stock_return)
        except Exception as e:
            print(f"Error calculating sector dominance: {e}")
            return 0.0

    def analyze_cycles(self, stock_data: pd.Series) -> float:
        try:
            if isinstance(stock_data, pd.DataFrame):
                stock_data = stock_data.iloc[:, 0]
            monthly_returns = stock_data.pct_change().resample('ME').mean()
            cycle_score = monthly_returns.std() * np.sqrt(12)
            return float(cycle_score)
        except Exception as e:
            print(f"Error calculating cycles: {e}")
            return 0.0

    def calculate_market_impact(self, stock_data: pd.Series,
                            benchmark_data: pd.DataFrame) -> Dict[str, float]:
        try:
            if isinstance(stock_data, pd.DataFrame):
                stock_data = stock_data.iloc[:, 0]
            if isinstance(benchmark_data, pd.DataFrame):
                benchmark_data = benchmark_data.iloc[:, 0]

            stock_monthly = stock_data.pct_change().resample('ME').mean()
            bench_monthly = benchmark_data.pct_change().resample('ME').mean()

            aligned_data = pd.concat([stock_monthly, bench_monthly], axis=1).dropna()

            if aligned_data.empty:
                return {'up_market': 0.0, 'down_market': 0.0, 'market_adaptability': 0.0}

            stock_returns = aligned_data.iloc[:, 0]
            bench_returns = aligned_data.iloc[:, 1]

            up_market = float(stock_returns[bench_returns > 0].mean() if len(stock_returns[bench_returns > 0]) > 0 else 0.0)
            down_market = float(stock_returns[bench_returns < 0].mean() if len(stock_returns[bench_returns < 0]) > 0 else 0.0)

            return {
                'up_market': up_market,
                'down_market': down_market,
                'market_adaptability': float(up_market - down_market)
            }
        except Exception as e:
            print(f"Error calculating market impact: {e}")
            return {'up_market': 0.0, 'down_market': 0.0, 'market_adaptability': 0.0}

    def calculate_consistency_score(self, stock_data: pd.Series) -> float:
        try:
            if isinstance(stock_data, pd.DataFrame):
                stock_data = stock_data.iloc[:, 0]
            monthly_returns = stock_data.pct_change().resample('ME').mean()
            positive_months = (monthly_returns > 0).sum() / len(monthly_returns)
            return float(positive_months)
        except Exception as e:
            print(f"Error calculating consistency score: {e}")
            return 0.0

    def analyze_stock(self, symbol: str, stock_data: pd.DataFrame,
        sector_returns: pd.Series, benchmark_data: pd.DataFrame) -> Optional[StockAnalysis]:
        try:
            # Handle both single and multiple stock cases
            if isinstance(stock_data.columns, pd.MultiIndex):
                symbol_data = stock_data[('Adj Close', symbol)].dropna()
            else:
                symbol_data = stock_data.dropna()

            if len(symbol_data) < 180:
                return None

            strength_scores = self.calculate_relative_strength(symbol_data)
            
            # Handle sector returns
            try:
                if isinstance(sector_returns, pd.Series):
                    sector_return = sector_returns.get(('Adj Close', symbol), 0.0)
                else:
                    sector_return = sector_returns
            except:
                sector_return = 0.0
                
            dominance = self.calculate_sector_dominance(sector_return)
            cycle_score = self.analyze_cycles(symbol_data)
            market_impact = self.calculate_market_impact(symbol_data, benchmark_data)
            consistency = self.calculate_consistency_score(symbol_data)

            final_score = float(
                0.25 * (strength_scores['30d'] + 1) +
                0.20 * (strength_scores['90d'] + 1) +
                0.15 * (strength_scores['180d'] + 1) +
                0.15 * (dominance + 1) +
                0.10 * consistency +
                0.15 * (market_impact['market_adaptability'] + 1)
            )

            news_items = self.news_retriever.get_stock_news(symbol)

            return StockAnalysis(
                symbol=symbol,
                final_score=final_score,
                short_term_strength=strength_scores['30d'],
                medium_term_strength=strength_scores['90d'],
                long_term_strength=strength_scores['180d'],
                sector_dominance=dominance,
                consistency=consistency,
                market_adaptability=market_impact['market_adaptability'],
                news=news_items
            )

        except Exception as e:
            print(f"Error analyzing {symbol}: {e}")
            return None

            return sector_analyses


