import requests
import json
from .fact_checker import check_fake
import os

# def get_news_json():
#     # Define the API endpoint and API key
#     url = "https://api.polygon.io/v2/reference/news"
#     params = {
#         "limit": 2,
#         "apiKey": "wKsUoEUYgcUJQJku4xKhFuhv7hQpQuZp"
#     }

#     # Make the GET request
#     response = requests.get(url, params=params)

#     # Check if the request was successful
#     if response.status_code == 200:
#         data = response.json()
#         # Convert JSON to a string for easy transmission
#         json_output = json.dumps(data, indent=4)
#     else:
#         print(f"Error: {response.status_code}, {response.text}")
#     return json_output

# def extract_titles_from_json_string(json_string):
#     try:
#         # Parse the JSON string
#         data = json.loads(json_string)
        
#         # Extract titles
#         titles = [result.get('title', '') for result in data.get('results', [])]
        
#         return data,titles

#     except json.JSONDecodeError as e:
#         print(f"JSON Decode Error: {e}")
#         return []

# def serialize_json_output(json_output):
#     def convert_to_serializable(obj):
#         """Recursively convert complex objects to JSON-serializable format"""
#         if isinstance(obj, (str, int, float, bool, type(None))):
#             return obj
#         elif isinstance(obj, dict):
#             return {k: convert_to_serializable(v) for k, v in obj.items()}
#         elif isinstance(obj, list):
#             return [convert_to_serializable(item) for item in obj]
#         elif isinstance(obj, requests.Response):
#             return obj.json()
#         elif hasattr(obj, '__dict__'):
#             return convert_to_serializable(obj.__dict__)
#         else:
#             return str(obj)

#     try:
#         # Handle different input types
#         if isinstance(json_output, requests.Response):
#             json_output = json_output.json()
        
#         # Convert entire structure to JSON-serializable
#         serialized_output = convert_to_serializable(json_output)
#         return serialized_output
    
#     except Exception as e:
#         return {"error": f"Serialization failed: {str(e)}"}



# def check_news():
#     output=[]
#     json_output = get_news_json()
#     data,titles = extract_titles_from_json_string(json_output)
#     for i,title in enumerate(titles):
#         try:
#             output.append({"json_output":serialize_json_output(data['results'][i]),"verification":serialize_json_output(check_fake(title))})
#         except:
#             output.append({"json_output":serialize_json_output(data['results'][i]),"verification":serialize_json_output("error")})
#     return output

# # print(type(check_news()))

# # import requests
# # import json
# # from .fact_checker import check_fake

# # def get_news_json():
# #     url = "https://api.polygon.io/v2/reference/news"
# #     params = {
# #         "limit": 10,
# #         "apiKey": "wKsUoEUYgcUJQJku4xKhFuhv7hQpQuZp"
# #     }

# #     response = requests.get(url, params=params)

# #     if response.status_code == 200:
# #         return response.json()  # Return the JSON dictionary directly
# #     else:
# #         print(f"Error: {response.status_code}, {response.text}")
# #         return {"error": f"API request failed with status {response.status_code}"}

# # def extract_titles_from_json(data):
# #     try:
# #         return [result.get('title', '') for result in data.get('results', [])]
# #     except (json.JSONDecodeError, TypeError) as e:
# #         print(f"JSON Decode Error: {e}")
# #         return []

# # # def check_news():
# # #     output = []
# # #     data = get_news_json()
    
# # #     if "error" in data:  # Handle API failure
# # #         return {"error": data["error"]}
    
# # #     titles = extract_titles_from_json(data)
    
# # #     for i, title in enumerate(titles):
# # #         try:
# # #             verification_result = check_fake(title)
# # #             output.append({"json_output": data['results'][i], "verification": verification_result})
# # #         except Exception as e:
# # #             output.append({"json_output": data['results'][i], "verification": f"error: {str(e)}"})
    
# # #     return output

# # def check_news():    for items in json_output:

# #     output = []
# #     json_output = get_news_json()
# #     data, titles = extract_titles_from_json(json_output)
# #     for i, title in enumerate(titles):
# #         try:
# #             json_data = json.dumps(data['results'][i])  # Ensure it's serializable
# #             output.append({"json_output": json_data, "verification": check_fake(title)})
# #         except Exception as e:
# #             output.append({"json_output": "error", "verification": "error"})
# #     return output



# # print(check_news())

def get_news_json():
    url = "https://api.polygon.io/v2/reference/news"
    params = {
        "limit": 10,
        "apiKey": os.getenv("POLYGON_API_KEY")  # Ensure API key is set in .env
    }

    response = requests.get(url, params=params)
    try:
        return response.json() if response.status_code == 200 else {"error": "API request failed"}
    except json.JSONDecodeError:
        return {"error": "Invalid JSON response"}

# Step 9: Extract Titles from API Response
def extract_titles_from_json(data):
    try:
        return [result.get('title', '') for result in data.get('results', [])]
    except (json.JSONDecodeError, TypeError):
        return []

# Step 10: Check News Validity
def check_news():
    output = []
    data = get_news_json()

    if "error" in data:
        return {"error": data["error"]}

    titles = extract_titles_from_json(data)

    for i, title in enumerate(titles):
        try:
            verification_result = check_fake(title +"\n"+data['results'][i]['description'])
            output.append({
                "news": data['results'][i],  # Original news JSON
                "verification": verification_result  # True or False
            })
        except Exception as e:
            output.append({
                "news": data['results'][i],
                "verification": f"error: {str(e)}"
            })

    return output