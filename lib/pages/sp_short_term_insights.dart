import 'package:datazen/apikeys.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class ShortTermInsightsPage extends StatefulWidget {
  @override
  _ShortTermInsightsPageState createState() => _ShortTermInsightsPageState();
}

class _ShortTermInsightsPageState extends State<ShortTermInsightsPage> {
  final String apiUrl =
      "https://api.polygon.io/v2/reference/news?limit=10&apiKey=$polygonKey";
  List<dynamic> newsArticles = [];
  List<bool> expandedList = [];

  @override
  void initState() {
    super.initState();
    fetchNews();
  }

  Future<void> fetchNews() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          newsArticles = data['results'] ?? [];
          expandedList = List.generate(newsArticles.length, (index) => false);
        });
      } else {
        print("Error fetching news: ${response.statusCode}");
      }
    } catch (e) {
      print("Exception: $e");
    }
  }

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
      body: newsArticles.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: EdgeInsets.all(16.0),
              itemCount: newsArticles.length,
              itemBuilder: (context, index) {
                final article = newsArticles[index];
                final sentiment = article['insights']?.isNotEmpty == true
                    ? article['insights'][0]['sentiment']
                    : "neutral";
                final sentimentReason = article['insights']?.isNotEmpty == true
                    ? article['insights'][0]['sentiment_reasoning']
                    : "No sentiment analysis available.";
                final tickers = article['tickers']?.join(', ') ?? "N/A";
                final formattedDate = formatDate(article['published_utc']);

                return Card(
                  color: Colors.grey[850],
                  margin: EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                        Text(
                          "${article['title']} (${tickers})",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "By ${article['author'] ?? "Unknown"}",
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                            Text(
                              formattedDate,
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Container(
                          padding:
                              EdgeInsets.symmetric(vertical: 4, horizontal: 8),
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
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          sentimentReason,
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        SizedBox(height: 10),
                        expandedList[index]
                            ? Text(
                                article['description'] ??
                                    "No description available.",
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 14),
                              )
                            : SizedBox.shrink(),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  expandedList[index] = !expandedList[index];
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                              ),
                              child: Text(expandedList[index]
                                  ? "Show Less"
                                  : "Read More"),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                final url = article['article_url'];
                                if (await canLaunch(url)) {
                                  await launch(url);
                                } else {
                                  print("Could not open URL");
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                              ),
                              child: Text("Open Article"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
