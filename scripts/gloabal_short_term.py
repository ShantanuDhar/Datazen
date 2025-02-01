import requests
import json

# Define the API endpoint and API key
url = "https://api.polygon.io/v2/reference/news"
params = {
    "limit": 10,
    "apiKey": "wKsUoEUYgcUJQJku4xKhFuhv7hQpQuZp"
}

# Make the GET request
response = requests.get(url, params=params)

# Check if the request was successful
if response.status_code == 200:
    data = response.json()
    # Convert JSON to a string for easy transmission
    json_output = json.dumps(data, indent=4)
    print(json_output)  # You can send this data to the frontend
else:
    print(f"Error: {response.status_code}, {response.text}")
