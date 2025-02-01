import yfinance as yf
import plotly.graph_objects as go
from datetime import datetime, timedelta


#Recommeder 1.1
class SectorPerformanceTracker:
    def __init__(self):
        self.sector_etfs = {
            'PVTB': 'KBE',  # Banking ETF (closest approximation to private banks)
            'IT': 'XLK',  # Technology ETF
            'Telecom': 'IYZ',  # Telecommunications ETF
            'Cement': 'XLB',  # Materials ETF (best fit for cement sector)
            'Pharma': 'XPH',  # Pharmaceuticals ETF
            'Infra': 'PAVE',  # Infrastructure ETF
            'NBFC': 'XLF',  # Financial ETF (closest approximation to NBFCs)
            'FMCG': 'XLP',  # Consumer Staples ETF (best fit for FMCG)
            'Others': 'SPY',  # S&P 500 ETF for "Others"
            'Metal': 'XME',  # Metals and Mining ETF
            'PSUB': 'KBE',  # Banking ETF (best fit for public sector banks)
            'Power': 'XLU',  # Utilities ETF (for power sector)
            'Cap_Goods': 'XLI',  # Industrial ETF (capital goods sector)
            'Auto': 'CARZ',  # Global Auto ETF
            'Oil': 'XLE'  # Energy ETF (best fit for oil sector)
        }

    def fetch_sector_performance(self, date=None):
        performance_data = {}
        if date is None:
            date = (datetime.now() - timedelta(days=1)).strftime('%Y-%m-%d')

        try:
            spy_data = yf.download('^NSEI', start=date, end=(datetime.strptime(date, '%Y-%m-%d') + timedelta(days=1)).strftime('%Y-%m-%d'))
            if len(spy_data) > 0:
                benchmark_current = float(spy_data['Close'].iloc[0])
                benchmark_prev = float(spy_data['Open'].iloc[0])
                benchmark_change = ((benchmark_current - benchmark_prev) / benchmark_prev) * 100
            else:
                raise Exception("No benchmark data available for this date")
        except Exception as e:
            print(f"Error fetching benchmark data: {str(e)}")
            return None

        for sector, etf in self.sector_etfs.items():
            try:
                hist = yf.download(etf, start=date, end=(datetime.strptime(date, '%Y-%m-%d') + timedelta(days=1)).strftime('%Y-%m-%d'))
                if len(hist) > 0:
                    current_price = float(hist['Close'].iloc[0])
                    prev_price = float(hist['Open'].iloc[0])
                    sector_change = ((current_price - prev_price) / prev_price) * 100
                    contribution = sector_change - benchmark_change

                    performance_data[sector] = {
                        'contribution': round(contribution, 2),
                        'sector_number': None,
                        'absolute_change': round(sector_change, 2)
                    }
                    print(f"Successfully fetched data for {sector}: {contribution:.2f}%")
            except Exception as e:
                print(f"Error fetching data for {sector}: {str(e)}")
                continue

        return performance_data

    def get_sector_rankings(self, date=None):
        performance_data = self.fetch_sector_performance(date)
        if not performance_data:
            raise ValueError("No sector data available for the specified date")

        sorted_sectors = dict(sorted(performance_data.items(), key=lambda x: x[1]['contribution'], reverse=True))
        for i, sector in enumerate(sorted_sectors.keys(), 1):
            sorted_sectors[sector]['sector_number'] = i

        return sorted_sectors

    def create_visualization(self, date=None):
        try:
            data = self.get_sector_rankings(date)
        except ValueError as e:
            print(f"Error: {e}")
            return None

        sectors = list(data.keys())
        contributions = [data[sector]['contribution'] for sector in sectors]
        absolute_changes = [data[sector]['absolute_change'] for sector in sectors]
        colors = ['#2E8B57' if val > 0 else '#DC143C' for val in contributions]

        hover_text = [
            f"<b>{sector}</b><br>Relative Contribution: {contributions[i]:.2f}%<br>Absolute Change: {absolute_changes[i]:.2f}%<br>Rank: {data[sector]['sector_number']}"
            for i, sector in enumerate(sectors)
        ]

        fig = go.Figure()
        fig.add_trace(go.Bar(
            x=sectors,
            y=contributions,
            marker_color=colors,
            text=[f"{val:.2f}%" for val in contributions],
            textposition='outside',
            hovertext=hover_text,
            hoverinfo='text'
        ))

        date_str = date if date else (datetime.now() - timedelta(days=1)).strftime('%Y-%m-%d')
        fig.update_layout(
            title={'text': f'Sector Performance Contributors ({date_str})', 'x': 0.5, 'xanchor': 'center', 'font': {'size': 24}},
            yaxis_title="Relative Contribution (%)",
            xaxis_title="Sectors",
            plot_bgcolor='white',
            showlegend=False,
            yaxis=dict(gridcolor='lightgrey', zerolinecolor='black', zerolinewidth=2),
            xaxis=dict(tickangle=45),
            height=600,
            margin=dict(t=100, b=100)
        )

        annotations = [
            dict(x=sector, y=contributions[i], xref="x", yref="y", text=f"#{data[sector]['sector_number']}", showarrow=True,
                 font=dict(color="white", size=10), bgcolor=colors[i], borderpad=4, borderwidth=0, arrowhead=2)
            for i, sector in enumerate(sectors)
        ]
        fig.update_layout(annotations=annotations)
        return fig