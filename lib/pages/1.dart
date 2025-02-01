import 'dart:convert';
import 'package:http/http.dart' as http; 


void main() async {
  try {
    final newsData = await _getNews();
    print("News Data Retrieved Successfully:");
    for (var newsItem in newsData) {
      print(newsItem);
    }
  } catch (e) {
    print("Error retrieving news: $e");
  }
}

Future<List<Map<dynamic, dynamic>>> _getNews() async {
  final url = Uri.parse(
      'https://www.alphavantage.co/query?function=NEWS_SENTIMENT&tickers=&apikey=O40FNMZXD87D7FLS');

  final response = await http.get(url);

  if (response.statusCode == 200) {
    final data = json.decode(response.body);

    // Print the response to see the full structure
    print("API Response: $data");

    if (!data.containsKey('feed')) {
      throw Exception('Invalid response format: missing feed key');
    }

    final newsList = data['feed'] as List<dynamic>;

    // Process the news list
    final filteredNews = newsList.where((item) {
      return item != null &&
          item['banner_image'] != null &&
          item['banner_image'].isNotEmpty &&
          item['title'] != null &&
          item['url'] != null;
    }).toList();

    return filteredNews.map((item) {
      return {
        'title': item['title'],
        'url': item['url'],
        'source': item['source'],
        'time_published': item['time_published'],
        'banner_image': item['banner_image'],
        'summary': item['summary'],
        'overall_sentiment_score': item['overall_sentiment_score'],
        'overall_sentiment_label': item['overall_sentiment_label'],
        'authors': (item['authors'] as List?)?.join(', ') ?? 'Unknown',
      };
    }).toList();
  } else {
    throw Exception('Failed to load news: ${response.statusCode}');
  }
}
