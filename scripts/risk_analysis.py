import yfinance as yf
import pandas as pd
import numpy as np
from scipy import stats
from sklearn.preprocessing import StandardScaler
from typing import List, Dict, Union, Tuple
import matplotlib.pyplot as plt
import seaborn as sns
import plotly.express as px
import io
import base64
import matplotlib
import matplotlib.pyplot as plt
matplotlib.use('Agg')

class StockRiskAnalyzer:
    def __init__(self):
        """Initialize the risk analyzer with necessary components"""
        self.scaler = StandardScaler()
        self.risk_free_rate = self._get_risk_free_rate()

    def _get_risk_free_rate(self) -> float:
        """Fetch current 10-year Treasury yield as risk-free rate"""
        try:
            treasury = yf.Ticker("^TNX")
            return treasury.info['regularMarketPrice'] / 100
        except:
            return 0.03  # Default to 3% if unable to fetch

    def fetch_stock_data(self,
                        symbols: Union[str, List[str]],
                        period: str = "2y") -> Dict[str, pd.DataFrame]:
        """Fetch historical data for given stock symbols"""
        if isinstance(symbols, str):
            symbols = [symbols]

        stock_data = {}
        for symbol in symbols:
            try:
                stock = yf.Ticker(symbol)
                data = stock.history(period=period)
                if not data.empty:
                    stock_data[symbol] = data
                    print(f"Successfully fetched data for {symbol}")
                else:
                    print(f"No data available for {symbol}")
            except Exception as e:
                print(f"Error fetching data for {symbol}: {str(e)}")

        return stock_data

    def _calculate_var(self, returns: pd.Series, confidence_level: float) -> float:
        """Calculate Value at Risk"""
        return abs(np.percentile(returns, (1 - confidence_level) * 100))

    def _calculate_cvar(self, returns: pd.Series, confidence_level: float) -> float:
        """Calculate Conditional Value at Risk (Expected Shortfall)"""
        var = self._calculate_var(returns, confidence_level)
        return abs(returns[returns <= -var].mean())

    def _calculate_max_drawdown(self, prices: pd.Series) -> float:
        """Calculate maximum drawdown"""
        rolling_max = prices.expanding().max()
        drawdowns = prices / rolling_max - 1
        return abs(drawdowns.min())

    def _calculate_technical_metrics(self, data: pd.DataFrame) -> Dict:
        """Calculate technical indicators for risk assessment"""
        close = data['Close']

        ma_20 = close.rolling(window=20).mean()
        ma_50 = close.rolling(window=50).mean()
        ma_200 = close.rolling(window=200).mean()

        delta = close.diff()
        gain = (delta.where(delta > 0, 0)).rolling(window=14).mean()
        loss = (-delta.where(delta < 0, 0)).rolling(window=14).mean()
        rs = gain / loss
        rsi = 100 - (100 / (1 + rs))

        std_20 = close.rolling(window=20).std()
        upper_band = ma_20 + (std_20 * 2)
        lower_band = ma_20 - (std_20 * 2)

        return {
            'ma_20': ma_20.iloc[-1],
            'ma_50': ma_50.iloc[-1],
            'ma_200': ma_200.iloc[-1],
            'rsi': rsi.iloc[-1],
            'upper_band': upper_band.iloc[-1],
            'lower_band': lower_band.iloc[-1],
            'ma_metrics': {
                'price_vs_ma50': close.iloc[-1] / ma_50.iloc[-1] - 1,
                'price_vs_ma200': close.iloc[-1] / ma_200.iloc[-1] - 1,
            }
        }

    def _calculate_momentum_metrics(self, data: pd.DataFrame) -> Dict:
        """Calculate momentum indicators"""
        returns = data['Close'].pct_change()

        return {
            'momentum_1m': returns.rolling(21).sum().iloc[-1],
            'momentum_3m': returns.rolling(63).sum().iloc[-1],
            'momentum_6m': returns.rolling(126).sum().iloc[-1],
            'momentum_12m': returns.rolling(252).sum().iloc[-1],
            'momentum_volatility': returns.rolling(63).std().iloc[-1]
        }

    def _calculate_volatility_metrics(self, data: pd.DataFrame) -> Dict:
        """Calculate volatility indicators"""
        returns = data['Close'].pct_change()

        return {
            'volatility_1m': returns.rolling(21).std().iloc[-1] * np.sqrt(252),
            'volatility_3m': returns.rolling(63).std().iloc[-1] * np.sqrt(252),
            'volatility_6m': returns.rolling(126).std().iloc[-1] * np.sqrt(252),
            'volatility_12m': returns.rolling(252).std().iloc[-1] * np.sqrt(252)
        }

    def _calculate_tail_risk_metrics(self, returns: pd.Series) -> Dict:
        """Calculate tail risk metrics"""
        var_99 = self._calculate_var(returns, 0.99)
        cvar_99 = self._calculate_cvar(returns, 0.99)

        downside_returns = returns[returns < 0]
        downside_deviation = np.sqrt(np.mean(downside_returns**2))

        return {
            'var_99': var_99,
            'cvar_99': cvar_99,
            'downside_deviation': downside_deviation,
            'tail_ratio': abs(np.percentile(returns, 95)) / abs(np.percentile(returns, 5))
        }

    def _calculate_portfolio_risk_score(self, stock_risks: Dict[str, Dict], portfolio: Dict[str, float]) -> float:
        """Calculate the overall portfolio risk score"""
        weighted_risks = [
            risk['total_risk_score'] * portfolio[symbol]
            for symbol, risk in stock_risks.items()
        ]

        portfolio_risk_score = sum(weighted_risks) / sum(portfolio.values())
        diversification_score = self._calculate_diversification_score(portfolio, {})
        final_risk_score = portfolio_risk_score * (1.2 - diversification_score)

        return min(1.0, max(0.0, final_risk_score))

    def analyze_portfolio_risk(self,
                             portfolio: Dict[str, float],
                             detailed: bool = True) -> Dict:
        """Analyze risk for entire portfolio"""
        symbols = list(portfolio.keys())
        stock_data = self.fetch_stock_data(symbols)

        stock_risks = {symbol: self.analyze_stock_risk(data)
                      for symbol, data in stock_data.items()}

        returns_data = self._calculate_portfolio_returns(stock_data, portfolio)

        portfolio_risk = {
            'total_risk_score': self._calculate_portfolio_risk_score(stock_risks, portfolio),
            'portfolio_volatility': returns_data['portfolio_returns'].std() * np.sqrt(252),
            'portfolio_var': self._calculate_portfolio_var(returns_data['portfolio_returns']),
            'portfolio_cvar': self._calculate_portfolio_cvar(returns_data['portfolio_returns']),
            'diversification_score': self._calculate_diversification_score(portfolio, stock_data),
            'individual_stock_risks': stock_risks
        }
        if detailed:
            portfolio_risk.update({
                'correlation_matrix': self._calculate_correlation_matrix(stock_data),
                'portfolio_beta': self._calculate_portfolio_beta(returns_data),
                'risk_attribution': self._calculate_risk_attribution(stock_risks, portfolio),
                'stress_test_results': self._perform_stress_test(returns_data['portfolio_returns']),
                'risk_decomposition': self._decompose_risk_factors(stock_data, portfolio)
            })

        return portfolio_risk

    def analyze_stock_risk(self, stock_data: pd.DataFrame) -> Dict:
        """Comprehensive risk analysis for a single stock"""
        returns = stock_data['Close'].pct_change().dropna()
        log_returns = np.log(1 + returns)

        volatility = returns.std() * np.sqrt(252)

        risk_metrics = {
            'basic_metrics': {
                'daily_volatility': returns.std(),
                'annualized_volatility': volatility,
                'skewness': returns.skew(),
                'kurtosis': returns.kurtosis(),
                'var_95': self._calculate_var(returns, 0.95),
                'cvar_95': self._calculate_cvar(returns, 0.95),
                'max_drawdown': self._calculate_max_drawdown(stock_data['Close']),
            },
            'technical_metrics': self._calculate_technical_metrics(stock_data),
            'momentum_metrics': self._calculate_momentum_metrics(stock_data),
            'volatility_metrics': self._calculate_volatility_metrics(stock_data),
            'tail_risk_metrics': self._calculate_tail_risk_metrics(returns)
        }

        risk_metrics['total_risk_score'] = self._calculate_total_risk_score(risk_metrics)

        return risk_metrics

    def _calculate_portfolio_returns(self,
                                   stock_data: Dict[str, pd.DataFrame],
                                   portfolio: Dict[str, float]) -> Dict:
        """Calculate portfolio returns and related metrics"""
        returns_data = {}
        for symbol, data in stock_data.items():
            returns_data[symbol] = data['Close'].pct_change()

        returns_df = pd.DataFrame(returns_data)

        weights = np.array([portfolio[symbol] for symbol in returns_df.columns])
        portfolio_returns = returns_df.dot(weights)

        market_data = self.fetch_stock_data('^GSPC')
        market_returns = market_data['^GSPC']['Close'].pct_change()
        market_returns = market_returns[market_returns.index.isin(portfolio_returns.index)]

        return {
            'portfolio_returns': portfolio_returns,
            'market_returns': market_returns,
            'individual_returns': returns_df
        }

    def _calculate_portfolio_var(self, returns: pd.Series) -> float:
        """Calculate portfolio Value at Risk"""
        return self._calculate_var(returns, 0.95)

    def _calculate_portfolio_cvar(self, returns: pd.Series) -> float:
        """Calculate portfolio Conditional Value at Risk"""
        return self._calculate_cvar(returns, 0.95)

    def _calculate_correlation_matrix(self, stock_data: Dict[str, pd.DataFrame]) -> pd.DataFrame:
        """Calculate correlation matrix between stocks"""
        returns_data = {}
        for symbol, data in stock_data.items():
            returns_data[symbol] = data['Close'].pct_change()
        returns_df = pd.DataFrame(returns_data)
        return returns_df.corr()

    def _calculate_portfolio_beta(self, returns_data: Dict) -> float:
        """Calculate portfolio beta"""
        portfolio_returns = returns_data['portfolio_returns']
        market_returns = returns_data['market_returns']

        covar = portfolio_returns.cov(market_returns)
        market_var = market_returns.var()

        return covar / market_var if market_var != 0 else 1

    def _calculate_risk_attribution(self,
                                  stock_risks: Dict[str, Dict],
                                  portfolio: Dict[str, float]) -> Dict:
        """Calculate risk attribution for each position"""
        total_risk = sum(risk['total_risk_score'] * portfolio[symbol]
                        for symbol, risk in stock_risks.items())

        attribution = {}
        for symbol, risk in stock_risks.items():
            attribution[symbol] = {
                'risk_contribution': risk['total_risk_score'] * portfolio[symbol],
                'risk_percentage': (risk['total_risk_score'] * portfolio[symbol] / total_risk
                                  if total_risk != 0 else 0)
            }

        return attribution

    def _perform_stress_test(self, returns: pd.Series) -> Dict:
        """Perform stress testing on portfolio"""
        scenarios = {
            'market_crash': -0.20,
            'severe_correction': -0.10,
            'moderate_correction': -0.05,
            'slight_correction': -0.02
 }

        results = {}
        portfolio_std = returns.std()

        for scenario, shock in scenarios.items():
            expected_loss = shock * (1 + portfolio_std)
            results[scenario] = {
                'expected_loss': expected_loss,
                'confidence_interval': (
                    expected_loss - 2 * portfolio_std,
                    expected_loss + 2 * portfolio_std
                )
            }

        return results

    def _decompose_risk_factors(self,
                              stock_data: Dict[str, pd.DataFrame],
                              portfolio: Dict[str, float]) -> Dict:
        """Decompose portfolio risk into factor contributions"""
        factor_betas = {}
        for symbol, data in stock_data.items():
            returns = data['Close'].pct_change()
            market_cap = data['Close'] * data['Volume']
            volatility = returns.rolling(21).std()

            factor_betas[symbol] = {
                'market': 1.0,  # Simplified market beta
                'size': np.log(market_cap.mean()),
                'volatility': volatility.mean()
            }

        portfolio_factor_exposure = {
            factor: sum(portfolio[symbol] * betas [factor]
                       for symbol, betas in factor_betas.items())
            for factor in ['market', 'size', 'volatility']
        }

        return portfolio_factor_exposure

    def _calculate_diversification_score(self,
                                       portfolio: Dict[str, float],
                                       stock_data: Dict[str, pd.DataFrame]) -> float:
        """Calculate portfolio diversification score"""
        hhi = sum(allocation ** 2 for allocation in portfolio.values())

        sector_allocations = self._calculate_sector_allocations(portfolio)
        sector_hhi = sum(alloc ** 2 for alloc in sector_allocations.values())

        return (1 - hhi) * 0.6 + (1 - sector_hhi) * 0.4

    def _calculate_sector_allocations(self, portfolio: Dict[str, float]) -> Dict[str, float]:
        """Calculate allocations by sector"""
        sector_allocations = {}

        for symbol, allocation in portfolio.items():
            try:
                stock = yf.Ticker(symbol)
                sector = stock.info.get('sector', 'Unknown')
                sector_allocations[sector] = sector_allocations.get(sector, 0) + allocation
            except:
                sector_allocations['Unknown'] = sector_allocations.get('Unknown', 0) + allocation

        return sector_allocations

    def _calculate_total_risk_score(self, risk_metrics: Dict) -> float:
        """Calculate comprehensive risk score from 0 (lowest risk) to 1 (highest risk)"""
        weights = {
            'volatility': 0.3,
            'technical': 0.2,
            'momentum': 0.15,
            'tail_risk': 0.35
        }

        volatility_score = min(1.0, risk_metrics['basic_metrics']['annualized_volatility'] / 0.4)

        tech_metrics = risk_metrics['technical_metrics']
        rsi_score = abs(tech_metrics['rsi'] - 50) / 50
        ma_score = abs(tech_metrics['ma_metrics']['price_vs_ma200'])
        technical_score = (rsi_score + ma_score) / 2

        momentum_metrics = risk_metrics['momentum_metrics']
        momentum_score = abs(momentum_metrics['momentum_12m']) + momentum_metrics['momentum_volatility']
        momentum_score = min(1.0, momentum_score)

        tail_metrics = risk_metrics['tail_risk_metrics']
        tail_score = (tail_metrics['cvar_99'] + tail_metrics['downside_deviation']) / 2
        tail_score = min(1.0, tail_score * 5)  # Scale up tail risk

        total_score = (
            weights['volatility'] * volatility_score +
            weights['technical'] * technical_score +
            weights['momentum'] * momentum_score +
            weights['tail_risk'] * tail_score
        )

        return min(1.0, total_score)

    def plot_portfolio_allocation(self, portfolio: Dict[str, float]) -> None:
        """Create a pie chart of portfolio allocation"""
        plt.figure(figsize=(10, 8))
        plt.pie(list(portfolio.values()), labels=list(portfolio.keys()), autopct='%1.1f%%', startangle=90)
        plt.title('Portfolio Allocation', fontsize=16)
        plt.axis('equal')
        plt.tight_layout()
        plt.show()

    def plot_individual_stock_risks(self, stock_risks: Dict[str, Dict]) -> None:
        """Plot individual stock risk scores as a bar chart"""
        symbols = list(stock_risks.keys())
        risk_scores = [risk['total_risk_score'] for risk in stock_risks.values()]

        plt.figure(figsize=(10, 6))
        bars = plt.bar(symbols, risk_scores, color='lightcoral')
        plt.title('Individual Stock Risk Scores', fontsize=16)
        plt.xlabel('Stocks', fontsize=12)
        plt.ylabel('Total Risk Score', fontsize=12 )

        for bar in bars:
            height = bar.get_height()
            plt.text(bar.get_x() + bar.get_width()/2., height,
                     f'{height:.2f}',
                     ha='center', va='bottom')
        plt.tight_layout()
        plt.show()

    def plot_correlation_heatmap(self, correlation_matrix: pd.DataFrame) -> None:
        """Plot correlation heatmap for portfolio stocks"""
        plt.figure(figsize=(10, 8))
        sns.heatmap(correlation_matrix,
                    annot=True,
                    cmap='RdYlBu',
                    center=0,
                    vmin=-1, vmax=1)
        plt.title('Stock Correlation Heatmap', fontsize=16)
        plt.tight_layout()
        plt.show()

    def plot_historical_performance(self, stock_data: Dict[str, pd.DataFrame]) -> None:
      """Plot historical performance of stocks in the portfolio"""
      plt.figure(figsize=(12, 6))
      for symbol, data in stock_data.items():
          plt.plot(data.index, data['Close'], label=symbol)
      plt.title('Historical Stock Performance', fontsize=16)
      plt.xlabel('Date', fontsize=12)
      plt.ylabel('Price (USD)', fontsize=12)
      plt.legend()
      plt.tight_layout()
      plt.show()

    def generate_risk_report(self, portfolio: Dict[str, float]) -> Dict:
      """Generate comprehensive risk report for portfolio"""
      try:
          risk_analysis = self.analyze_portfolio_risk(portfolio, detailed=True)

          self.plot_portfolio_allocation(portfolio)
          self.plot_individual_stock_risks(risk_analysis['individual_stock_risks'])

          if 'correlation_matrix' in risk_analysis:
              self.plot_correlation_heatmap(risk_analysis['correlation_matrix'])

          stock_data = self.fetch_stock_data(list(portfolio.keys()))
          self.plot_historical_performance(stock_data)

          return {
              'summary': {
                  'total_risk_score': risk_analysis['total_risk_score'],
                  'portfolio_volatility': risk_analysis['portfolio_volatility'],
                  'diversification_score': risk_analysis['diversification_score'],
                  'risk_level': self._categorize_risk_level(risk_analysis['total_risk_score'])
              },
              'risk_metrics': risk_analysis,
              'recommendations': self._generate_risk_recommendations(risk_analysis),
              'alerts': self._generate_risk_alerts(risk_analysis)
          }
      except Exception as e:
          print(f"An error occurred while generating the risk report: {str(e)}")
          return None

    def _categorize_risk_level(self, risk_score: float) -> str:
        """Categorize risk level based on risk score"""
        if risk_score < 0.2:
            return "Very Low"
        elif risk_score < 0.4:
            return "Low"
        elif risk_score < 0.6:
            return "Moderate"
        elif risk_score < 0.8:
            return "High"
        else:
            return "Very High"

    def _generate_risk_recommendations(self, risk_analysis: Dict) -> List[Dict]:
        """Generate risk management recommendations"""
        recommendations = []

        if risk_analysis['diversification_score'] < 0.6:
            recommendations.append({
                'type': 'DIVERSIFICATION',
                'priority': 'HIGH',
                'description': 'Consider increasing portfolio diversification',
                'details': 'Portfolio shows high concentration risk'
            })

        if risk_analysis['portfolio_volatility'] > 0.25:  # 25% annualized volatility
            recommendations.append({
                'type': 'VOLATILITY',
                'priority': 'HIGH',
                'description': 'Consider reducing portfolio volatility',
                'details': 'Portfolio volatility exceeds target threshold'
            })

        high_risk_stocks = [
            symbol for symbol, risk in risk_analysis['individual_stock_risks'].items()
            if risk['total_risk_score'] > 0.7
        ]

        if high_risk_stocks:
            recommendations.append({
                'type': 'STOCK_SPECIFIC',
                'priority': 'MEDIUM',
                'description': f'Review high-risk positions: {", ".join(high_risk_stocks)}',
                'details': 'These positions show elevated risk metrics'
            })

        return recommendations

    def _generate_risk_alerts(self, risk_analysis: Dict) -> List[Dict]:
        """Generate risk alerts based on analysis"""
        alerts = []

        if risk_analysis['portfolio_var'] > 0.03:  # 3% daily VaR
            alerts.append({
                'type': 'VAR_BREACH',
                'severity': 'HIGH',
                'message': 'Portfolio VaR exceeds risk tolerance'
            })

        if 'cor relation_matrix' in risk_analysis:
            corr_matrix = risk_analysis['correlation_matrix']
            high_corr = (corr_matrix > 0.8).sum().sum() - corr_matrix.shape[0]
            if high_corr > 0:
                alerts.append({
                    'type': 'HIGH_CORRELATION',
                    'severity': 'MEDIUM',
                    'message': f'Detected {high_corr//2} highly correlated pairs'
                })

        return alerts

def plot_to_base64(plt):
    """Convert matplotlib plot to base64 string"""
    img = io.BytesIO()
    plt.savefig(img, format='png', bbox_inches='tight')
    img.seek(0)
    plt.close()
    return base64.b64encode(img.getvalue()).decode()

class StockRiskAnalyzerAPI(StockRiskAnalyzer):
    
    def generate_risk_report_api(self, portfolio: Dict[str, float]) -> Dict:
        """Generate risk report with base64 encoded plots for API response"""
        try:
            risk_analysis = self.analyze_portfolio_risk(portfolio, detailed=True)
            
            # Generate and capture plots
            # Portfolio Allocation Plot
            plt.figure(figsize=(10, 8))
            plt.pie(list(portfolio.values()), labels=list(portfolio.keys()), 
                autopct='%1.1f%%', startangle=90)
            plt.title('Portfolio Allocation', fontsize=16)
            plt.axis('equal')
            allocation_plot = plot_to_base64(plt)

            # Individual Stock Risks Plot
            plt.figure(figsize=(10, 6))
            symbols = list(risk_analysis['individual_stock_risks'].keys())
            risk_scores = [risk['total_risk_score'] 
                        for risk in risk_analysis['individual_stock_risks'].values()]
            bars = plt.bar(symbols, risk_scores, color='lightcoral')
            plt.title('Individual Stock Risk Scores', fontsize=16)
            plt.xlabel('Stocks', fontsize=12)
            plt.ylabel('Total Risk Score', fontsize=12)
            for bar in bars:
                height = bar.get_height()
                plt.text(bar.get_x() + bar.get_width()/2., height,
                        f'{height:.2f}', ha='center', va='bottom')
            risks_plot = plot_to_base64(plt)

            # Historical Performance Plot
            stock_data = self.fetch_stock_data(list(portfolio.keys()))
            plt.figure(figsize=(12, 6))
            for symbol, data in stock_data.items():
                # Normalize prices to start at 100 for better comparison
                normalized_prices = data['Close'] / data['Close'].iloc[0] * 100
                plt.plot(data.index, normalized_prices, label=symbol)
            plt.title('Historical Stock Performance (Normalized)', fontsize=16)
            plt.xlabel('Date', fontsize=12)
            plt.ylabel('Normalized Price', fontsize=12)
            plt.legend()
            plt.grid(True)
            historical_plot = plot_to_base64(plt)

            return {
                'summary': {
                    'total_risk_score': risk_analysis['total_risk_score'],
                    'portfolio_volatility': risk_analysis['portfolio_volatility'],
                    'diversification_score': risk_analysis['diversification_score'],
                    'risk_level': self._categorize_risk_level(risk_analysis['total_risk_score'])
                },
                'plots': {
                    'allocation_plot': allocation_plot,
                    'risks_plot': risks_plot,
                    'historical_plot': historical_plot  # Changed from correlation_plot to historical_plot
                },
                'recommendations': self._generate_risk_recommendations(risk_analysis),
                'alerts': self._generate_risk_alerts(risk_analysis)
            }
        except Exception as e:
            print(f"An error occurred while generating the risk report: {str(e)}")
            return None
