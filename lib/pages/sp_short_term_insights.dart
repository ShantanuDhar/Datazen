import 'package:datazen/apikeys.dart';
import 'package:datazen/core/globalvariables.dart';
import 'package:datazen/pages/sp_ticker_list_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class ShortTermInsightsPage extends StatefulWidget {
  @override
  _ShortTermInsightsPageState createState() => _ShortTermInsightsPageState();
}

class _ShortTermInsightsPageState extends State<ShortTermInsightsPage> {
  final String apiUrl =
      "https://api.polygon.io/v2/reference/news?limit=10&apiKey=$polygonKey";
  // Replace with your actual ngrok endpoint URL for local news
  final String ngrokUrl =
      "https://580b-2409-40c0-18-c343-7be2-2c64-9b57-a18f.ngrok-free.app/indian_news";

  List<dynamic> newsArticles = [];
  List<bool> expandedList = [];
  bool isLocalNews = false; // Toggle between global and local news
  bool isReasonExpanded = false;
  bool isLoading = false; // Flag to track loading state

  @override
  void initState() {
    super.initState();
    fetchNews();
  }

  @override
  void dispose() {
    newsArticles = [];
    super.dispose();
  }

  // Toggle the news source and fetch the related news from either endpoint.
  void toggleNewsSource() {
    setState(() {
      isLocalNews = !isLocalNews;
      isLoading = true;
    });
    fetchNews();
  }

  Future<void> fetchNews() async {
    if (isLocalNews) {
      try {
        // GET request to local news endpoint via ngrok
        final response = await http.get(Uri.parse(ngrokUrl));
        if (response.statusCode == 200) {
          // Print the complete JSON response from the endpoint.
          print("Complete Local News Response: ${response.body}");

          // Decode the response JSON
          final data = json.decode(response.body);

          // Transform the local news response into a structure similar to global news.
          // We assume the local JSON contains an "indian_news" key with a list of items.
          List<dynamic> localNews = data['indian_news'] ?? [];
          List<dynamic> transformedNews = localNews.map((item) {
            final news = item['news'];
            // Use the title from the JSON if available, otherwise compute a default title.
            final title = news['title'] ??
                (news['description']?.split(' ')?.take(6)?.join(' ') + "...");
            final description =
                news['description'] ?? "No description available.";
            final imageUrl = news['image_url'] ??
                'https://via.placeholder.com/350x180.png?text=Local+News';
            final entities = news['entities'] ?? [];
            // Extract ticker symbols from each entity.
            final tickers = entities.map((e) => e['symbol'] ?? "").toList();

            return {
              'title': title,
              'description': description,
              'author': "Local Reporter",
              // Use the published time from the news JSON if available.
              'published_utc':
                  news['published_at'] ?? DateTime.now().toUtc().toString(),
              'image_url': imageUrl,
              'tickers': tickers,
              'entities': entities,
              'insights': [], // No sentiment insights provided, leave it empty.
              // Use the verification field from the outer object.
              'verification': item['verification'] ?? false
            };
          }).toList();

          setState(() {
            newsArticles = transformedNews;
            expandedList = List.generate(newsArticles.length, (index) => false);
            isLoading = false;
          });
        } else {
          print("Error fetching local news: ${response.statusCode}");
          setState(() {
            isLoading = false;
          });
        }
      } catch (e) {
        print("Exception fetching local news: $e");
        setState(() {
          isLoading = false;
        });
      }
    } else {
      // Global news from the API
      try {
        final response = await http.get(Uri.parse(apiUrl));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          setState(() {
            newsArticles = data['results'] ?? [];
            expandedList = List.generate(newsArticles.length, (index) => false);
            isLoading = false;
          });
        } else {
          print("Error fetching news: ${response.statusCode}");
          setState(() {
            isLoading = false;
          });
        }
      } catch (e) {
        print("Exception: $e");
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // Format a UTC date string into a human-friendly format.
  String formatDate(String utcDate) {
    if (utcDate == null) return "Unknown date";
    DateTime date = DateTime.parse(utcDate).toLocal();
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF0D1B2A),
        title:
            Text("Short Term Insights", style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          // Stylish animated toggle button for switching between local and global news.
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: toggleNewsSource,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: isLocalNews
                      ? LinearGradient(
                          colors: [Colors.teal, Colors.greenAccent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : LinearGradient(
                          colors: [Colors.blueGrey, Colors.grey],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated icon switches based on news source.
                    AnimatedSwitcher(
                      duration: Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) =>
                          ScaleTransition(scale: animation, child: child),
                      child: Icon(
                        isLocalNews ? Icons.public : Icons.location_on,
                        key: ValueKey<bool>(isLocalNews),
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 10),
                    // Animated text updates based on toggle state.
                    AnimatedSwitcher(
                      duration: Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                      child: Text(
                        isLocalNews ? "Show Global News" : "Show Local News",
                        key: ValueKey<String>(isLocalNews ? "global" : "local"),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Show loading indicator when data is being fetched.
          if (isLoading)
            Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            // Expanded widget to display a list of news articles.
            Expanded(
              child: newsArticles.isEmpty
                  ? Center(
                      child: Text("No articles available",
                          style: TextStyle(color: Colors.white)))
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: newsArticles.length,
                      itemBuilder: (context, index) {
                        final article = newsArticles[index];
                        // For global news we may have insights; for local news, leave as default.
                        final sentiment =
                            article['insights']?.isNotEmpty == true
                                ? article['insights'][0]['sentiment']
                                : "neutral";
                        final sentimentReason =
                            article['insights']?.isNotEmpty == true
                                ? article['insights'][0]['sentiment_reasoning']
                                : "No sentiment analysis available.";
                        final tickers = article['tickers'] ?? [];
                        final formattedDate =
                            formatDate(article['published_utc']);
                        // Check the verification status.
                        final isVerified = article['verification'] ?? false;

                        return Card(
                          color: Colors.grey[850],
                          margin: EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Display image banner using the provided image URL.
                                article['image_url'] != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          article['image_url'],
                                          height: 180,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : SizedBox.shrink(),
                                SizedBox(height: 10),
                                // Title row with dynamic verification indicator.
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        "${article['title']}",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    // Dynamic verification indicator
                                    Row(
                                      children: [
                                        Icon(Icons.circle,
                                            size: 12,
                                            color: isVerified
                                                ? Colors.green
                                                : Colors.red),
                                        SizedBox(width: 4),
                                        Text(
                                          isVerified
                                              ? "Verified"
                                              : "Not Verified",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "By ${article['author'] ?? "Unknown"}",
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 14),
                                    ),
                                    Text(
                                      formattedDate,
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 14),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                // Show ticker symbols using Chips.
                                Wrap(
                                  spacing: 8,
                                  children: (tickers as List<dynamic>)
                                      .map(
                                        (ticker) => Chip(
                                          label: Text(
                                            ticker,
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                          backgroundColor: Colors.blueGrey,
                                        ),
                                      )
                                      .toList(),
                                ),
                                SizedBox(height: 8),
                                // Display sentiment if available.
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 4, horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: sentiment == "positive"
                                        ? Colors.green
                                        : sentiment == "negative"
                                            ? Colors.red
                                            : Colors.grey,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    sentiment.toUpperCase(),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 5),
                                // Toggle sentiment reasoning view.
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      isReasonExpanded = !isReasonExpanded;
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text("Show Reason",
                                        style: TextStyle(color: Colors.white)),
                                  ),
                                ),
                                if (isReasonExpanded)
                                  Text(
                                    '$sentimentReason',
                                    style: TextStyle(
                                      color: sentiment == "positive"
                                          ? Colors.green
                                          : sentiment == "negative"
                                              ? Colors.red
                                              : Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                SizedBox(height: 10),
                                // Expand to show full article description.
                                expandedList[index]
                                    ? Text(
                                        article['description'] ??
                                            "No description available.",
                                        style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14),
                                      )
                                    : SizedBox.shrink(),
                                SizedBox(height: 10),
                                // Row for "Read More" and "Show Tickers" actions.
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          expandedList[index] =
                                              !expandedList[index];
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blueAccent,
                                      ),
                                      child: Text(
                                        expandedList[index]
                                            ? "Show Less"
                                            : "Read More",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                TickerListPage(
                                                    tickers: tickers),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.redAccent,
                                      ),
                                      child: Text(
                                        "Show Tickers",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
        ],
      ),
    );
  }
}
