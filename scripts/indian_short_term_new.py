# import requests

# # Define the URL
# url = 'https://api.marketaux.com/v1/news/all?countries=in&filter_entities=true&language=en&api_token=CAVP5WVXpmh0kg2YzEPowaIi8wa8vL8KygLNLPEf'

# # Send the GET request
# response = requests.get(url)

# # Check if the request was successful
# if response.status_code == 200:
#     # Parse the JSON response
#     data = response.json()
#     # Output the data
#     print(data)
# else:
#     print(f"Request failed with status code {response.status_code}")


import requests
from .fact_checker import check_fake

def get_indian_news_json():
    # Define the URL
    url = 'https://api.marketaux.com/v1/news/all?countries=in&filter_entities=true&language=en&api_token=CAVP5WVXpmh0kg2YzEPowaIi8wa8vL8KygLNLPEf'

    # Send the GET request
    response = requests.get(url)

    # Check if the request was successful
    if response.status_code == 200:
        # Parse the JSON response
        data = response.json()
        # Output the data
        return data
    else:
        print(f"Request failed with status code {response.status_code}")
        return None

def check_indian_news():
    output = []
    data = get_indian_news_json()

    if "error" in data:
        return {"error": data["error"]}

    for i, item in enumerate(data['data']):
        try:
            verification_result = check_fake(item['description'])
            output.append({
                "news": data['data'][i],  # Original news JSON
                "verification": verification_result  # True or False
            })
        except Exception as e:
            output.append({
                "news": data['data'][i],
                "verification": f"error: {str(e)}"
            })

    return output

# print(check_indian_news())