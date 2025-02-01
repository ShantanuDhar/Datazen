# from neo4j import GraphDatabase
# import plotly.graph_objects as go
# import pandas as pd
# from sentence_transformers import SentenceTransformer
# from sklearn.metrics.pairwise import cosine_similarity
# import numpy as np
# from typing import List, Dict, Any
# import logging

# # Set up logging
# logging.basicConfig(level=logging.INFO)
# logger = logging.getLogger(__name__)

# class SectorAnalysisRAG:
#     def __init__(self, uri: str, username: str, password: str):
#         """Initialize the SectorAnalysisRAG class with database credentials"""
#         try:
#             self.driver = GraphDatabase.driver(uri, auth=(username, password))
#             self.model = SentenceTransformer('all-MiniLM-L6-v2')
#             self.sector_data_cache = None
#             self.embeddings_cache = None
#             logger.info("Successfully initialized SectorAnalysisRAG")
#         except Exception as e:
#             logger.error(f"Error initializing SectorAnalysisRAG: {str(e)}")
#             raise

#     def close(self):
#         if self.driver:
#             self.driver.close()
#             logger.info("Database connection closed")

#     def get_latest_data(self, batch_size: int = 1000) -> Dict[str, Any]:
#         try:
#             query = """
#             MATCH (s:Sector)<-[:BELONGS_TO]-(c:Company)<-[:REPORTS_ON]-(q:QuarterlyReport)
#             WHERE q.quarterly IS NOT NULL
#             WITH s.name as sector, c.name as company, q.quarterly as quarterly_data
#             WITH sector, company, apoc.convert.fromJsonMap(quarterly_data) as data
#             WITH sector, company, keys(data) as quarters, data
#             WITH sector, company, quarters, data
#             ORDER BY quarters[-1] DESC
#             WITH sector, company, quarters[0] as latest_quarter, data[quarters[0]] as latest_data

#             RETURN sector,
#                    collect({
#                        company: company,
#                        net_profit: toFloat(latest_data.`Net Profit\u00a0+`),
#                        sales: toFloat(latest_data.`Sales\u00a0+`),
#                        quarter: latest_quarter,
#                        other_metrics: latest_data
#                    }) as company_data
#             """

#             with self.driver.session() as session:
#                 result = session.run(query)
#                 data = {record["sector"]: record["company_data"] for record in result}
#                 logger.info(f"Retrieved data for {len(data)} sectors")
#                 return data
#         except Exception as e:
#             logger.error(f"Error retrieving data: {str(e)}")
#             raise

#     def process_sector_data(self) -> pd.DataFrame:
#         try:
#             raw_data = self.get_latest_data()
#             processed_data = []

#             for sector, companies in raw_data.items():
#                 sector_metrics = {
#                     'sector': sector,
#                     'total_net_profit': sum(c['net_profit'] for c in companies if c['net_profit']),
#                     'avg_net_profit': np.mean([c['net_profit'] for c in companies if c['net_profit']]),
#                     'total_sales': sum(c['sales'] for c in companies if c['sales']),
#                     'company_count': len(companies),
#                     'companies': companies,
#                     'quarter': companies[0]['quarter'] if companies else None
#                 }
#                 processed_data.append(sector_metrics)

#             df = pd.DataFrame(processed_data)
#             logger.info("Successfully processed sector data")
#             return df
#         except Exception as e:
#             logger.error(f"Error processing sector data: {str(e)}")
#             raise

#     def generate_sector_insights(self, df: pd.DataFrame) -> List[str]:
#         try:
#             insights = []
#             total_market_profit = df['total_net_profit'].sum()
#             insights.append(f"Total market net profit: ₹{total_market_profit:.2f} Cr")
            
#             top_sectors = df.nlargest(3, 'avg_net_profit')
#             insights.append("\nTop performing sectors by average net profit:")
#             for _, sector in top_sectors.iterrows():
#                 insights.append(f"{sector['sector']}: ₹{sector['avg_net_profit']:.2f} Cr")

#             insights.append(f"\nTotal number of sectors: {len(df)}")
#             avg_companies = df['company_count'].mean()
#             insights.append(f"Average companies per sector: {avg_companies:.1f}")

#             logger.info("Generated sector insights")
#             return insights
#         except Exception as e:
#             logger.error(f"Error generating insights: {str(e)}")
#             raise

#     def create_visualization(self) -> go.Figure:
#         try:
#             df = self.process_sector_data()
#             df = df.sort_values('avg_net_profit', ascending=True)

#             hover_text = []
#             for _, row in df.iterrows():
#                 company_details = "<br>".join([
#                     f"{c['company']}: ₹{c['net_profit']:.2f} Cr"
#                     for c in row['companies']
#                 ])

#                 hover_text.append(
#                     f"<b>{row['sector']}</b><br>" +
#                     f"Average Net Profit: ₹{row['avg_net_profit']:.2f} Cr<br>" +
#                     f"Total Net Profit: ₹{row['total_net_profit']:.2f} Cr<br>" +
#                     f"Total Sales: ₹{row['total_sales']:.2f} Cr<br>" +
#                     f"Companies: {row['company_count']}<br>" +
#                     f"<br>Company Details:<br>{company_details}"
#                 )

#             colors = ['#2E8B57' if val > 0 else '#DC143C' for val in df['avg_net_profit']]

#             fig = go.Figure()

#             fig.add_trace(go.Bar(
#                 y=df['sector'],
#                 x=df['avg_net_profit'],
#                 orientation='h',
#                 marker_color=colors,
#                 text=[f"₹{val:.0f} Cr" for val in df['avg_net_profit']],
#                 textposition='outside',
#                 hovertext=hover_text,
#                 hoverinfo='text'
#             ))

#             fig.update_layout(
#                 title={
#                     'text': f'Sector-wise Performance Analysis (Quarter: {df.iloc[0]["quarter"]})',
#                     'x': 0.5,
#                     'xanchor': 'center',
#                     'font': {'size': 24}
#                 },
#                 xaxis_title="Average Net Profit (₹ Cr)",
#                 yaxis_title="Sectors",
#                 plot_bgcolor='white',
#                 showlegend=False,
#                 height=800,
#                 margin=dict(t=100, b=100, l=200, r=100),
#                 hoverlabel=dict(
#                     bgcolor="white",
#                     font_size=12,
#                     font_family="Arial"
#                 ),
#                 yaxis=dict(
#                     showgrid=False,
#                     showline=True,
#                     showticklabels=True,
#                     domain=[0, 0.9],
#                 ),
#                 xaxis=dict(
#                     zeroline=True,
#                     showline=True,
#                     showticklabels=True,
#                     showgrid=True,
#                     domain=[0, 1],
#                     gridcolor='lightgrey',
#                     zerolinecolor='black',
#                     zerolinewidth=2,
#                 ),
#             )

#             insights = self.generate_sector_insights(df)
#             insight_text = "<br>".join(insights)

#             fig.add_annotation( # Add a text annotation
#                 text=insight_text,
#                 xref="paper",
#                 yref="paper",
#                 x=0.5,
#                 y=0.05,
#                 showarrow=False,
#                 font=dict(size=14, color="black"),
#                 align="left",
#             )

#             logger.info("Created visualization")
#             return fig
#         except Exception as e:
#             logger.error(f"Error creating visualization: {str(e)}")
#             raise

from neo4j import GraphDatabase
import plotly.graph_objects as go
import pandas as pd
from sentence_transformers import SentenceTransformer
import numpy as np
from typing import List, Dict, Any
import logging
import base64

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class SectorAnalysisRAG:
    def __init__(self, uri: str, username: str, password: str):
        """Initialize the SectorAnalysisRAG class with database credentials"""
        try:
            self.driver = GraphDatabase.driver(uri, auth=(username, password))
            self.model = SentenceTransformer('all-MiniLM-L6-v2')
            self.sector_data_cache = None
            self.embeddings_cache = None
            logger.info("Successfully initialized SectorAnalysisRAG")
        except Exception as e:
            logger.error(f"Error initializing SectorAnalysisRAG: {str(e)}")
            raise

    def close(self):
        if self.driver:
            self.driver.close()
            logger.info("Database connection closed")

    def get_latest_data(self, batch_size: int = 1000) -> Dict[str, Any]:
        try:
            query = """
            MATCH (s:Sector)<-[:BELONGS_TO]-(c:Company)<-[:REPORTS_ON]-(q:QuarterlyReport)
            WHERE q.quarterly IS NOT NULL
            WITH s.name as sector, c.name as company, q.quarterly as quarterly_data
            WITH sector, company, apoc.convert.fromJsonMap(quarterly_data) as data
            WITH sector, company, keys(data) as quarters, data
            WITH sector, company, quarters, data
            ORDER BY quarters[-1] DESC
            WITH sector, company, quarters[0] as latest_quarter, data[quarters[0]] as latest_data

            RETURN sector,
                   collect({
                       company: company,
                       net_profit: toFloat(latest_data.`Net Profit\u00a0+`),
                       sales: toFloat(latest_data.`Sales\u00a0+`),
                       quarter: latest_quarter,
                       other_metrics: latest_data
                   }) as company_data
            """

            with self.driver.session() as session:
                result = session.run(query)
                data = {record["sector"]: record["company_data"] for record in result}
                logger.info(f"Retrieved data for {len(data)} sectors")
                return data
        except Exception as e:
            logger.error(f"Error retrieving data: {str(e)}")
            raise

    def process_sector_data(self) -> pd.DataFrame:
        try:
            raw_data = self.get_latest_data()
            processed_data = []

            for sector, companies in raw_data.items():
                sector_metrics = {
                    'sector': sector,
                    'total_net_profit': sum(c['net_profit'] for c in companies if c['net_profit']),
                    'avg_net_profit': np.mean([c['net_profit'] for c in companies if c['net_profit']]),
                    'total_sales': sum(c['sales'] for c in companies if c['sales']),
                    'company_count': len(companies),
                    'companies': companies,
                    'quarter': companies[0]['quarter'] if companies else None
                }
                processed_data.append(sector_metrics)

            df = pd.DataFrame(processed_data)
            logger.info("Successfully processed sector data")
            return df
        except Exception as e:
            logger.error(f"Error processing sector data: {str(e)}")
            raise

    def generate_sector_insights(self, df: pd.DataFrame) -> List[str]:
        try:
            insights = []
            total_market_profit = df['total_net_profit'].sum()
            insights.append(f"Total market net profit: ₹{total_market_profit:.2f} Cr")
            
            top_sectors = df.nlargest(3, 'avg_net_profit')
            insights.append("\nTop performing sectors by average net profit:")
            for _, sector in top_sectors.iterrows():
                insights.append(f"{sector['sector']}: ₹{sector['avg_net_profit']:.2f} Cr")

            insights.append(f"\nTotal number of sectors: {len(df)}")
            avg_companies = df['company_count'].mean()
            insights.append(f"Average companies per sector: {avg_companies:.1f}")

            logger.info("Generated sector insights")
            return insights
        except Exception as e:
            logger.error(f"Error generating insights: {str(e)}")
            raise

    def create_visualization(self) -> go.Figure:
        try:
            df = self.process_sector_data()
            df = df.sort_values('avg_net_profit', ascending=True)

            hover_text = []
            for _, row in df.iterrows():
                company_details = "<br>".join([
                    f"{c['company']}: ₹{c['net_profit']:.2f} Cr"
                    for c in row['companies']
                ])

                hover_text.append(
                    f"<b>{row['sector']}</b><br>" +
                    f"Average Net Profit: ₹{row['avg_net_profit']:.2f} Cr<br>" +
                    f"Total Net Profit: ₹{row['total_net_profit']:.2f} Cr<br>" +
                    f"Total Sales: ₹{row['total_sales']:.2f} Cr<br>" +
                    f"Companies: {row['company_count']}<br>" +
                    f"<br>Company Details:<br>{company_details}"
                )

            colors = ['#2E8B57' if val > 0 else '#DC143C' for val in df['avg_net_profit']]

            fig = go.Figure()

            fig.add_trace(go.Bar(
                y=df['sector'],
                x=df['avg_net_profit'],
                orientation='h',
                marker_color=colors,
                text=[f"₹{val:.0f} Cr" for val in df['avg_net_profit']],
                textposition='outside',
                hovertext=hover_text,
                hoverinfo='text'
            ))

            fig.update_layout(
                title={
                    'text': f'Sector-wise Performance Analysis (Quarter: {df.iloc[0]["quarter"]})',
                    'x': 0.5,
                    'xanchor': 'center',
                    'font': {'size': 24}
                },
                xaxis_title="Average Net Profit (₹ Cr)",
                yaxis_title="Sectors",
                plot_bgcolor='white',
                showlegend=False,
                height=800,
                margin=dict(t=100, b=100, l=200, r=100),
                hoverlabel=dict(
                    bgcolor="white",
                    font_size=12,
                    font_family="Arial"
                ),
                yaxis=dict(
                    showgrid=False,
                    showline=True,
                    showticklabels=True,
                    domain=[0, 0.9],
                ),
                xaxis=dict(
                    zeroline=True,
                    showline=True,
                    showticklabels=True,
                    showgrid=True,
                    domain=[0, 1],
                    gridcolor='lightgrey',
                    zerolinecolor='black',
                    zerolinewidth=2,
                ),
            )

            insights = self.generate_sector_insights(df)
            insight_text = "<br>".join(insights)

            fig.add_annotation(
                text=insight_text,
                xref="paper",
                yref="paper",
                x=0.5,
                y=0.05,
                showarrow=False,
                font=dict(size=14, color="black"),
                align="left",
            )

            logger.info("Created visualization")
            return fig
        except Exception as e:
            logger.error(f"Error creating visualization: {str(e)}")
            raise

    def create_image(self) -> str:
        """
        Create visualization and return as base64 encoded image
        """
        try:
            fig = self.create_visualization()
            
            # Convert figure to PNG image
            img_bytes = fig.to_image(format="png", engine="kaleido", width=1200, height=800)
            
            # Convert to base64
            img_base64 = base64.b64encode(img_bytes).decode('utf-8')
            
            logger.info("Successfully created and encoded image")
            return img_base64
            
        except Exception as e:
            logger.error(f"Error creating image: {str(e)}")
            raise
