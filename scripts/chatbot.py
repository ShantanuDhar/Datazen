
from langchain.chains import GraphCypherQAChain
from langchain_community.graphs import Neo4jGraph
from langchain_community.llms import Cohere
from langchain.prompts import PromptTemplate
import dotenv
import os
import warnings

warnings.filterwarnings("ignore")

dotenv.load_dotenv()

neo4j_password = os.getenv("NEO4J_PASSWORD")
cohere_api_key=os.getenv("COHERE_API_KEY")

# Initialize the Cohere LLM
llm_cohere = Cohere(cohere_api_key=cohere_api_key, model="command-xlarge-nightly")

# Initialize Neo4j Graph
uri =  "neo4j+s://9a89da2e.databases.neo4j.io"
user = "neo4j"
password = neo4j_password

graph = Neo4jGraph(
    url=uri,
    username=user,
    password=password
)

prompt_template = """
Given the following schema of a Neo4j graph database about financial data:

Nodes:
- Company (Properties: name, ticker, sector)
- Sector (Properties: name, description)
- NewsArticle (Properties: title, link, publisher, detailed_time, content, sentiment)
- QuarterlyReport (Properties: quarterly, profit_loss, balance_sheet, ratio)

Relationships:
- (Company)-[:BELONGS_TO]->(Sector)
- (NewsArticle)-[:MENTIONS]->(Company)
- (QuarterlyReport)-[:REPORTS_ON]->(Company)

Note: Financial data in QuarterlyReport is stored as JSON strings. Use these patterns:
- For profit/loss data: CASE WHEN r.profit_loss IS NOT NULL THEN toFloat(split(split(r.profit_loss, '"netIncome":')[1], ',')[0]) ELSE 0 END as netIncome

User Question: {query}

Generate a Cypher query that answers this question. The query should:
1. Handle NULL values appropriately
2. Use proper JSON parsing for financial data
3. Include relevant filters and sorting
4. Limit results when appropriate

Important:
1. Return only the pure Cypher query without any markdown, SQL, or other formatting
2. For financial data parsing use: 
CASE WHEN r.profit_loss IS NOT NULL THEN toFloat(split(split(r.profit_loss, '"netIncome":')[1], ',')[0]) ELSE 0 END as netIncome
3. Include proper error handling with CASE statements
4. Always include appropriate ORDER BY and LIMIT clauses

Cypher Query:
"""

prompt = PromptTemplate(template=prompt_template, input_variables=["query"])

def process_with_cohere(user_query, graph_output):
    try:
        prompt = f"""
        You are a financial analysis assistant analyzing Neo4j graph data. 
        User Query: '{user_query}'
        Graph Data: {graph_output}
        
        Provide insights based on this data. Focus on:
        1. Key financial metrics and trends
        2. Sector performance comparisons
        3. Notable company-specific findings
        4. Relevant news sentiment if available
        
        if graph is empty , don't mention that graph is empty
        If there is no context, provide a general analysis based on data available on the web and if some part of data is not available, dont mention it in the output
        Keep the analysis clear and concise and dont give in markdown format
        """
        
        response = llm_cohere.generate(
            prompts=[prompt],
            max_tokens=300
        )
        
        if isinstance(response.generations, list):
            return response.generations[0][0].text.strip()
        else:
            return response.generations[0].text.strip()
    except Exception as e:
        print(f"Cohere processing error: {str(e)}")
        return "Unable to process the data for insights."

def chatbot_query(user_query):
    try:
        chain = GraphCypherQAChain.from_llm(
            llm=llm_cohere,
            graph=graph,
            verbose=True,
            cypher_prompt=prompt,
            return_direct=True,
            allow_dangerous_requests=True
        )
        
        result = chain.invoke({"query": user_query})
        
        if isinstance(result, dict):
            final_result = result.get('result', '')
        else:
            final_result = str(result)
        
        cohere_output = process_with_cohere(user_query, final_result)
        
        return {
            "graph_result": final_result,
            "cohere_output": cohere_output
        }
    except Exception as e:
        print(f"Error details: {str(e)}")
        return {
            "error": f"An error occurred: {str(e)}",
            "graph_result": None,
            "cohere_output": None
        }
