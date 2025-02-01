import http.client
import json

conn = http.client.HTTPSConnection("livemint-api.p.rapidapi.com")

headers = {
    'x-rapidapi-key': "1e4f93d9f4msha2fc20ba862816cp172850jsn4981f6564d9b",
    'x-rapidapi-host': "livemint-api.p.rapidapi.com"
}

conn.request("GET", "/stock?name=AURUM", headers=headers)

res = conn.getresponse()
data = res.read()

# Decode the response data
decoded_data = data.decode("utf-8")

# Convert to JSON format
try:
    json_data = json.loads(decoded_data)
    
    def extract_all_news(data, key="recentNews"):
        """Recursively search for 'recentNews' key in JSON."""
        if isinstance(data, dict):
            if key in data:
                return data[key]  # Return the found recentNews data
            for value in data.values():
                result = extract_all_news(value, key)
                if result:
                    return result
        elif isinstance(data, list):
            for item in data:
                result = extract_all_news(item, key)
                if result:
                    return result
        return None

    # Extract all news dynamically
    all_news = extract_all_news(json_data, "recentNews")

    if all_news:
        print(json.dumps(all_news, indent=4))  # Pretty print JSON
    else:
        print("No news found.")

except json.JSONDecodeError as e:
    print("Error decoding JSON:", e)
