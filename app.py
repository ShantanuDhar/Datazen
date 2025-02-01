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
import logging
import json
import datetime
import warnings
import numpy as np


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
def analyze_portfolio():
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

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)