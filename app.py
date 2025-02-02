from flask import Flask, request, jsonify
from flask_cors import CORS
import io
import base64
from datetime import datetime, timedelta, date
from scripts.chatbot import chatbot_query
from scripts.recommendation1 import SectorPerformanceTracker
from scripts.recommendation2 import SectorAnalysisRAG
from scripts.recommendation3 import IntegratedStockAnalyzer
from scripts.risk_analysis import StockRiskAnalyzerAPI
from scripts.technical_analysis import UniversalStockAnalyzer
from scripts.Louvain_Girvan_Newman_long_term_portfolio import EnhancedIndianMarketAnalyzer
from scripts.short_term_mom_stock import BSEStockAnalyzer
import logging
import json
import warnings
import numpy as np
from scripts.annual_report import PDFAnalyzer
import asyncio

warnings.filterwarnings('ignore', category=DeprecationWarning, module='langchain')

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


app = Flask(__name__)
CORS(app)

#Chatbot

@app.route('/chatbot', methods=['POST'])
def handle_query():
    try:
        data = request.get_json()
        user_query = data.get('query')
        
        if not user_query:
            return jsonify({"error": "No query provided"}), 400
        
        result = chatbot_query(user_query)
        
        if "error" in result:
            return jsonify(result), 500
        
        return jsonify(result)
    
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({"status": "healthy"}), 200


#Recommendations

#1

def fig_to_base64(fig):
    img_bytes = fig.to_image(format="png")
    encoded = base64.b64encode(img_bytes).decode("utf-8")
    return encoded

@app.route('/get_sector_performance', methods=['POST'])
def get_sector_performance():
    data = request.get_json()
    date = data.get('date', None)

    tracker = SectorPerformanceTracker()
    fig = tracker.create_visualization(date)
    if fig is None:
        return jsonify({"error": "Could not generate visualization."}), 400

    img_base64 = fig_to_base64(fig)
    return jsonify({"image": img_base64})

#2

# @app.route('/rag_sector', methods=['GET'])
# def get_sector_analysis():
#     uri = "neo4j+s://c6227adb.databases.neo4j.io"
#     user = "neo4j"
#     password = "bzG73whvahGl5iTCm0jXkfEnlw1DdQOPXxrjNdtXHTs"
#     analyzer = SectorAnalysisRAG(uri, user, password)
#     try:
#         # Create the visualization
#         fig = analyzer.create_visualization()
        
#         # Convert the figure to a JSON string
#         fig_json = fig.to_json()
        
#         # Encode the JSON string to base64
#         fig_base64 = base64.b64encode(fig_json.encode('utf-8')).decode('utf-8')
        
#         return jsonify({
#             'status': 'success',
#             'data': fig_base64,
#             'type': 'plotly'  # Indicating that this is a Plotly figure
#         })
    
#     except Exception as e:
#         logger.error(f"Error generating sector analysis: {str(e)}")
#         return jsonify({
#             'status': 'error',
#             'message': str(e)
#         }), 500

@app.route('/rag_sector', methods=['GET'])
def get_sector_analysis():
    uri = "neo4j+s://c6227adb.databases.neo4j.io"
    user = "neo4j"
    password = "bzG73whvahGl5iTCm0jXkfEnlw1DdQOPXxrjNdtXHTs"
    
    try:
        analyzer = SectorAnalysisRAG(uri, user, password)
        
        # Get base64 encoded image
        img_base64 = analyzer.create_image()
        
        # Close the database connection
        analyzer.close()
        
        return jsonify({
            'status': 'success',
            'data': img_base64,
            'type': 'image/png'
        })
    
    except Exception as e:
        logger.error(f"Error in sector analysis endpoint: {str(e)}")
        return jsonify({
            'status': 'error',
            'message': str(e)
        }), 500

# Add CORS support if needed
@app.after_request
def after_request(response):
    response.headers.add('Access-Control-Allow-Origin', '*')
    response.headers.add('Access-Control-Allow-Headers', 'Content-Type,Authorization')
    response.headers.add('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE')
    return response

#3

# @app.route('/sector_stock_recommender', methods=['GET'])
# def get_stock_analysis():
#     try:
#         analyzer = IntegratedStockAnalyzer()
#         sector_analyses = analyzer.analyze_all_stocks()

#         # Convert the analysis results to JSON-serializable format
#         response_data = {}

#         for sector, analyses in sector_analyses.items():
#             sector_data = []
#             for analysis in analyses:
#                 news_items = []
#                 for news in analysis.news:
#                     news_items.append({
#                         'title': news.title,
#                         'publisher': news.publisher,
#                         'published_date': news.published_date,
#                         'url': news.url,
#                         'content': news.content,
#                         'sentiment': news.sentiment
#                     })

#                 stock_data = {
#                     'symbol': analysis.symbol,
#                     'final_score': round(float(analysis.final_score), 4),
#                     'short_term_strength': round(float(analysis.short_term_strength), 4),
#                     'medium_term_strength': round(float(analysis.medium_term_strength), 4),
#                     'long_term_strength': round(float(analysis.long_term_strength), 4),
#                     'sector_dominance': round(float(analysis.sector_dominance), 4),
#                     'consistency': round(float(analysis.consistency), 4),
#                     'market_adaptability': round(float(analysis.market_adaptability), 4),
#                     'news': news_items
#                 }
#                 sector_data.append(stock_data)

#             response_data[sector] = sector_data

#         return jsonify({
#             'status': 'success',
#             'data': response_data
#         }), 200

#     except Exception as e:
#         return jsonify({
#             'status': 'error',
#             'message': str(e)
#         }), 500

#     finally:
#         if 'analyzer' in locals():
#             analyzer.news_retriever.close()

# Custom JSON encoder to handle datetime objects
class CustomJSONEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, (datetime, date)):
            return obj.isoformat()
        elif isinstance(obj, np.float64):
            return float(obj)
        elif isinstance(obj, np.int64):
            return int(obj)
        return super().default(obj)

# Configure Flask to use the custom encoder
app.json_encoder = CustomJSONEncoder

# @app.route('/stock-analysis', methods=['GET'])
# def get_stock_analysis():
#     # Create a global analyzer instance
#     stock_analyzer = IntegratedStockAnalyzer()
#     try:
#         sector_analyses = stock_analyzer.analyze_all_stocks()
        
#         # Convert the analysis results to a JSON-serializable format
#         response_data = {
#             sector: [analysis.to_dict() for analysis in analyses]
#             for sector, analyses in sector_analyses.items()
#         }
        
#         return jsonify({
#             'status': 'success',
#             'data': response_data
#         }), 200

#     except Exception as e:
#         return jsonify({
#             'status': 'error',
#             'message': str(e)
#         }), 500

# @app.route('/stock-analysis', methods=['GET'])
# def get_stock_analysis():
#     # Create a global analyzer instance
#     stock_analyzer = IntegratedStockAnalyzer()
#     try:
#         sector_analyses = stock_analyzer.analyze_all_stocks()
        
#         # Convert the analysis results to a JSON-serializable format
#         response_data = {
#             sector: [analysis.to_dict() for analysis in analyses]
#             for sector, analyses in sector_analyses.items()
#         }
        
#         return jsonify({
#             'status': 'success',
#             'data': response_data
#         }), 200

#     except Exception as e:
#         return jsonify({
#             'status': 'error',
#             'message': str(e)
#         }), 500



@app.route('/health1', methods=['GET'])
def health_check1():
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat()
    })

# @app.route('/analyze_risk', methods=['POST'])
# def analyze_portfolio():
#     try:
#         data = request.get_json()
        
#         if not data or 'portfolio' not in data:
#             return jsonify({
#                 'error': 'Invalid request. Portfolio data is required.'
#             }), 400

#         portfolio = data['portfolio']
        
#         # Validate portfolio data
#         if not all(isinstance(v, (int, float)) for v in portfolio.values()):
#             return jsonify({
#                 'error': 'Invalid portfolio weights. All values must be numbers.'
#             }), 400

#         if abs(sum(portfolio.values()) - 1.0) > 0.0001:
#             return jsonify({
#                 'error': 'Portfolio weights must sum to 1.0'
#             }), 400

#         analyzer = StockRiskAnalyzerAPI()
#         report = analyzer.generate_risk_report_api(portfolio)

#         if report is None:
#             return jsonify({
#                 'error': 'Failed to generate risk report'
#             }), 500

#         return jsonify(report)

#     except Exception as e:
#         return jsonify({
#             'error': f'An error occurred: {str(e)}'
#         }), 500

# @app.errorhandler(404)
# def not_found(error):
#     return jsonify({'error': 'Not found'}), 404

# @app.errorhandler(500)
# def internal_error(error):
#     return jsonify({'error': 'Internal server error'}), 500

# if __name__ == '__main__':
#     app.run(debug=True, port=5000)

#Risk Analysis
@app.route('/analyze_risk', methods=['POST'])
def analyze_risk():
    try:
        data = request.get_json()
        
        if not data or 'portfolio' not in data:
            return jsonify({
                'error': 'Invalid request. Portfolio data is required.'
            }), 400

        portfolio = data['portfolio']
        
        # Validate portfolio data
        if not all(isinstance(v, (int, float)) for v in portfolio.values()):
            return jsonify({
                'error': 'Invalid portfolio weights. All values must be numbers.'
            }), 400

        if abs(sum(portfolio.values()) - 1.0) > 0.0001:
            return jsonify({
                'error': 'Portfolio weights must sum to 1.0'
            }), 400

        analyzer = StockRiskAnalyzerAPI()
        report = analyzer.generate_risk_report_api(portfolio)

        if report is None:
            return jsonify({
                'error': 'Failed to generate risk report'
            }), 500

        return jsonify(report)

    except Exception as e:
        return jsonify({
            'error': f'An error occurred: {str(e)}'
        }), 500

@app.errorhandler(404)
def not_found(error):
    return jsonify({'error': 'Not found'}), 404

@app.errorhandler(500)
def internal_error(error):
    return jsonify({'error': 'Internal server error'}), 500

#Technical Analysis
@app.route('/technical-analyze', methods=['POST'])
def analyze_stock():
    data = request.get_json()
    ticker = data.get('ticker')
    
    if not ticker:
        return jsonify({'error': 'Ticker symbol is required'}), 400

    analyzer = UniversalStockAnalyzer()
    report = analyzer.generate_report(ticker)
    
    if report is None:
        return jsonify({'error': f'Failed to generate report for {ticker}'}), 404
        
    return jsonify(report)


from scripts.gloabal_short_term import check_news
from scripts.indian_short_term_new import check_indian_news
from scripts.ticker import get_stock_info

# @app.route('/global_news', methods=['GET'])
# def check_news():
#     """Flask route to retrieve and process news"""
#     try:
#         processed_news=check_news()
#         # print(processed_news)
#         return jsonify({'news':processed_news}), 200

#     except Exception as e:
#         return jsonify({"error": str(e)}), 500


@app.route('/global_news', methods=['GET'])
def global_news():
    try:
        processed_news = check_news()
        return jsonify({"news": processed_news}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/indian_news', methods=['GET'])
def indian_news():
    try:
        processed_news = check_indian_news()
        return jsonify({"indian_news": processed_news}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    
@app.route('/lgn', methods=['GET'])
def analyze_portfolio():
    """Endpoint to trigger portfolio analysis and return results."""
    try:
        # Get parameters with defaults
        start_date = request.args.get('start_date', (datetime.now() - timedelta(days=3*365)).strftime('%Y-%m-%d'))
        end_date = request.args.get('end_date', datetime.now().strftime('%Y-%m-%d'))
        
        # Define your sector mapping here or import it
        sector_mapping = {
    "RELIANCE.NS": "Energy",
    "TCS.NS": "IT",
    "HDFCBANK.NS": "Banking",
    "INFY.NS": "IT",
    "ICICIBANK.NS": "Banking",
    "HINDUNILVR.NS": "FMCG",
    "ITC.NS": "FMCG",
    "SBIN.NS": "Banking",
    "BHARTIARTL.NS": "Telecom",
    "KOTAKBANK.NS": "Banking",
    "LT.NS": "Infrastructure",
    "AXISBANK.NS": "Banking",
    "ASIANPAINT.NS": "FMCG",
    "HCLTECH.NS": "IT",
    "BAJFINANCE.NS": "Financial Services",
    "WIPRO.NS": "IT",
    "MARUTI.NS": "Automobile",
    "ULTRACEMCO.NS": "Cement",
    "NESTLEIND.NS": "FMCG",
    "TITAN.NS": "Consumer Durables",
    "TECHM.NS": "IT",
    "SUNPHARMA.NS": "Pharma",
    "M&M.NS": "Automobile",
    "ADANIGREEN.NS": "Renewable Energy",
    "POWERGRID.NS": "Energy",
    "NTPC.NS": "Energy",
    "ONGC.NS": "Energy",
    "BPCL.NS": "Energy",
    "INDUSINDBK.NS": "Banking",
    "GRASIM.NS": "Cement",
    "ADANIPORTS.NS": "Logistics",
    "JSWSTEEL.NS": "Steel",
    "COALINDIA.NS": "Energy",
    "DRREDDY.NS": "Pharma",
    "APOLLOHOSP.NS": "Healthcare",
    "EICHERMOT.NS": "Automobile",
    "BAJAJFINSV.NS": "Financial Services",
    "TATAMOTORS.NS": "Automobile",
    "DIVISLAB.NS": "Pharma",
    "HDFCLIFE.NS": "Insurance",
    "CIPLA.NS": "Pharma",
    "HEROMOTOCO.NS": "Automobile",
    "SBICARD.NS": "Financial Services",
    "ADANIENT.NS": "Conglomerate",
    "UPL.NS": "Chemicals",
    "BRITANNIA.NS": "FMCG",
    "ICICIPRULI.NS": "Insurance",
    "SHREECEM.NS": "Cement",
    "PIDILITIND.NS": "Chemicals",
    "DMART.NS": "Retail",
    "ABB.NS": "Industrial Equipment",
    "AIAENG.NS": "Engineering",
    "ALKEM.NS": "Pharma",
    "AMBUJACEM.NS": "Cement",
    "AUROPHARMA.NS": "Pharma",
    "BANDHANBNK.NS": "Banking",
    "BERGEPAINT.NS": "FMCG",
    "BOSCHLTD.NS": "Automobile",
    "CANBK.NS": "Banking",
    "CHOLAFIN.NS": "Financial Services",
    "CUMMINSIND.NS": "Industrial Equipment",
    "DABUR.NS": "FMCG",
    "DLF.NS": "Real Estate",
    "ESCORTS.NS": "Automobile",
    "FEDERALBNK.NS": "Banking",
    "GLAND.NS": "Pharma",
    "GLAXO.NS": "Pharma",
    "GODREJCP.NS": "FMCG",
    "GODREJPROP.NS": "Real Estate",
    "HAL.NS": "Aerospace",
    "HAVELLS.NS": "Consumer Durables",
    "IGL.NS": "Energy",
    "IRCTC.NS": "Transportation",
    "LICI.NS": "Insurance",
    "LUPIN.NS": "Pharma",
    "NAUKRI.NS": "IT Services",
    "PEL.NS": "Financial Services",
    "PFC.NS": "Energy",
    "PNB.NS": "Banking",
    "RECLTD.NS": "Energy",
    "SIEMENS.NS": "Industrial Equipment",
    "SRF.NS": "Chemicals",
    "TATACHEM.NS": "Chemicals",
    "TATAELXSI.NS": "IT",
    "TRENT.NS": "Retail",
    "TVSMOTOR.NS": "Automobile",
    "VBL.NS": "FMCG",
    "VEDL.NS": "Metals",
    "WHIRLPOOL.NS": "Consumer Durables",
    "ZOMATO.NS": "Food Services",
    "INOXWIND.NS": "Renewable Energy",
    "SOLARA.NS": "Pharma",
    "INOXGREEN.NS": "Renewable Energy",
    "MOTHERSON.NS": "Automobile",
    "LLOYDSENGG.NS": "Steel",
    "HCC.NS": "Infrastructure",
    "CAMLINFINE.NS": "Chemicals",
    "AURUM.NS": "Real Estate",
    "AXISCADES.NS": "Engineering"
        }

        # Create an instance of the analyzer
        analyzer = EnhancedIndianMarketAnalyzer(start_date=start_date, end_date=end_date, sector_mapping=sector_mapping)

        # Perform the analysis
        analyzer.fetch_data(list(sector_mapping.keys()))
        analyzer.calculate_returns()
        analyzer.build_correlation_matrix(threshold=0.3)
        analyzer.create_network_graph()
        
        # Detect communities and analyze performance
        partition = analyzer.detect_communities_louvain()
        comm_analysis = analyzer.analyze_communities(partition)
        
        # Optimize portfolio
        portfolio = analyzer.optimize_portfolio(
            target_return=0.15,
            risk_free_rate=0.05,
            max_sector_exposure=0.30,
            max_stock_weight=0.15
        )

        if portfolio is None:
            return jsonify({"error": "Portfolio optimization failed"}), 500

        # Format notification
        notification = analyzer.format_notification(portfolio, [])

        return jsonify({
            "message": notification,
            "portfolio_metrics": {
                "expected_return": portfolio['expected_return'],
                "volatility": portfolio['volatility'],
                "sharpe_ratio": portfolio['sharpe_ratio']
            }
        }), 200

    except Exception as e:
        logger.error(f"Error in analyze_portfolio: {str(e)}")
        return jsonify({"error": str(e)}), 500


@app.route('/stock-info', methods=['POST'])
def stock_info_endpoint():
    # Get ticker symbol from query parameter
    data = request.get_json()
    
    # Validate ticker symbol
    if not data or 'ticker' not in data:
        return jsonify({
            "error": "Missing ticker symbol in request body",
            "status": 400
        }), 400
    
    ticker_symbol = data['ticker']
    
    # Validate ticker symbol
    if not ticker_symbol:
        return jsonify({
            "error": "Missing ticker symbol",
            "status": 400
        }), 400
    
    try:
        # Call the existing get_stock_info function
        stock_data = get_stock_info(ticker_symbol)
        
        if stock_data is None:
            return jsonify({
                "error": "No stock data found",
                "ticker": ticker_symbol,
                "status": 404
            }), 404
        
        # Convert DataFrame to list of dictionaries
        stock_records = stock_data.to_dict(orient='records')
        
        return jsonify({
            "ticker": ticker_symbol,
            "data": stock_records,
            "status": 200
        }), 200
    
    except Exception as e:
        return jsonify({
            "error": str(e),
            "ticker": ticker_symbol,
            "status": 500
        }), 500

async def run_pipeline():
    url = "https://www.screener.in/annual-reports/"
    analyzer = PDFAnalyzer(url)
    await analyzer.run()
    return analyzer.results

@app.route("/process", methods=["GET"])
def process():
    # Run the asynchronous pipeline and get the results
    results = asyncio.run(run_pipeline())
    
    # Filter each result to only include the PDF URL, FinBERT analysis, and BuySell analysis.
    filtered_results = []
    for result in results:
        entry = {
            "pdf_url": result.get("PDF_URL", None),
            "analysis": result.get("Analysis", {}),       # FinBERT analysis output
            "buy_sell_analysis": result.get("BuySellAnalysis", {})  # BuySell model output
        }
        filtered_results.append(entry)
    
    response_payload = {
        "results": filtered_results
    }
    
    return jsonify(response_payload)

def format_analysis_results(results):
    """Helper function to format analysis results for JSON response"""
    if not results:
        return None
    
    # Format industry momentum
    industry_momentum = results['industry_momentum'].reset_index()
    industry_momentum.columns = ['Industry', 'Momentum_Score']
    
    # Format top 10 stocks
    top_stocks = results['relative_strength'].head(10).reset_index()
    top_stocks.columns = ['Symbol', 'Relative_Strength', 'Industry', 'Company']
    
    return {
        'industries': industry_momentum.to_dict(orient='records'),
        'top_stocks': top_stocks.to_dict(orient='records')
    }

@app.route('/industry', methods=['GET'])
def get_market_analysis():
    """Endpoint to get market analysis results"""
    try:
        analyzer = BSEStockAnalyzer("scripts/Data/Equity (1).csv")
        results = analyzer.analyze_market()
        
        formatted_results = format_analysis_results(results)
        if not formatted_results:
            return jsonify({"error": "Analysis failed"}), 500
            
        return jsonify(formatted_results)
    
    except Exception as e:
        return jsonify({
            "error": f"Error processing request: {str(e)}"
        }), 500


if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)