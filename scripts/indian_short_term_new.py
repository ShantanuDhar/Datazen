import requests

# Define the URL
url = 'https://api.marketaux.com/v1/news/all?countries=in&filter_entities=true&language=en&api_token=CAVP5WVXpmh0kg2YzEPowaIi8wa8vL8KygLNLPEf'

# Send the GET request
response = requests.get(url)

# Check if the request was successful
if response.status_code == 200:
    # Parse the JSON response
    data = response.json()
    # Output the data
    print(data)
else:
    print(f"Request failed with status code {response.status_code}")
