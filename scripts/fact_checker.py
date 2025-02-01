# Import necessary libraries
from langchain.agents import AgentType, initialize_agent
from langchain_core.tools import BaseTool
from langchain_cohere import ChatCohere
import cohere
import requests
from bs4 import BeautifulSoup
from typing import List
import string


# Step 1: Initialize Cohere Client
cohere_client = cohere.Client('RxSPixDw28aNcvuOvUJivFUiepCOiByY4eBmrY2p')  # Replace with your Cohere API key

# Step 2: Initialize LLM with Cohere
llm = ChatCohere(
    cohere_api_key='RxSPixDw28aNcvuOvUJivFUiepCOiByY4eBmrY2p',  # Replace with your Cohere API key
    model="command-r-plus"
)

class GoogleSearchTool(BaseTool):
    name: str = "google_search"
    description: str = "Search Google for current information and retrieve relevant results."

    def _run(self, query: str) -> List[str]:
        search_url = f"https://www.google.com/search?q={query}"
        headers = {
            "User -Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3"
        }
        response = requests.get(search_url, headers=headers)
        soup = BeautifulSoup(response.text, "html.parser")

        results = []
        for g in soup.find_all("div", class_="tF2Cxc"):
            title_element = g.find("h3")
            snippet_element = g.find("div", class_="IsZvec")
            if title_element and snippet_element:
                title = title_element.get_text()
                snippet = snippet_element.get_text()
                results.append(f"{title} - {snippet}")
        return results

class CohereRerankTool(BaseTool):
    name: str = "cohere_reranker"
    description: str = "Reranks documents using Cohere's API to prioritize the most relevant results."

    def _run(self, query: str) -> List[str]:
        google_search_tool = GoogleSearchTool()
        docs = google_search_tool._run(query)

        response = cohere_client.rerank(
            model="rerank-multilingual-v3.0",
            query=query,
            documents=docs,
            top_n=3  # Limit to top 3 results
        )
        return [f"{doc.document.title} - {doc.document.snippet}" for doc in response.results]

# Step 5: Initialize Tools
google_search_tool = GoogleSearchTool()
reranker = CohereRerankTool()

tools = [google_search_tool, reranker]

# Step 6: Initialize the Agent
agent = initialize_agent(
    tools,
    llm,
    agent=AgentType.ZERO_SHOT_REACT_DESCRIPTION,
    verbose=True,
    handle_parsing_errors=True,
    max_iterations=5
)

def verify_claim(claim: str) -> str:
    prompt = f"Verify this claim: {claim}. Consider the essence of the claim and whether the search results support it, even if the wording differs. The final answer should be 'true' or 'false'."
    response = agent.run(prompt)
    return response

def check_fake(claim):
    result = verify_claim(claim)
    result_cleaned = result.translate(str.maketrans('', '', string.punctuation))
    print(result_cleaned)
    
    is_true_present = 'true' in result_cleaned.lower()
    return is_true_present

# claim = "ITC Hotels shares rallied 5% ahead of Budget, stakeholders seek tax relief"
# result = check_fake(claim)
# print("Verification Result:", result)