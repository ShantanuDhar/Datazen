import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:datazen/apikeys.dart';
import 'package:datazen/pages/sp_watchlist.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_typeahead/flutter_typeahead.dart';

import 'package:url_launcher/url_launcher.dart';
import 'sp_stock.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _controllerOne;
  late Animation _animationOne;

  late AnimationController _controllerTwo;
  late Animation _animationTwo;

  late AnimationController _controllerThree;
  late Animation _animationThree;

  final String _textName = "Hey, Shantanu";
  final String _textWelcome = "Welcome to Profit Pocket";

  TextEditingController _textSearch = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  List<Map<dynamic, dynamic>> _news = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    fetchFirstName();
    // Initialize animations
    _initializeAnimations();
    // Fetch news data
    _initializeData();
  }

  // Assuming you have the current user's ID stored in a variable called 'userId'
  String firstName = '';

  Future<void> fetchFirstName() async {
    try {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get();
      if (userSnapshot.exists) {
        Map<String, dynamic> userData =
            userSnapshot.data() as Map<String, dynamic>;
        firstName = "Hey, ${userData['firstName']}" ?? '';
      }
    } catch (e) {
      print('Failed to fetch firstName: $e');
    }
  }

  // Call the fetchFirstName() function to fetch the firstName

  void _initializeAnimations() {
    // Name animation
    _controllerOne = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _animationOne = IntTween(begin: 0, end: _textName.length).animate(
      CurvedAnimation(parent: _controllerOne, curve: Curves.easeInOut),
    );
    _controllerOne.addListener(() => setState(() {}));
    _controllerOne.forward();

    // Welcome text animation
    _controllerTwo = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );
    _animationTwo = IntTween(begin: 0, end: _textWelcome.length).animate(
      CurvedAnimation(parent: _controllerTwo, curve: Curves.easeInOut),
    );
    _controllerTwo.addListener(() => setState(() {}));
    _controllerTwo.forward();

    // Hand wave animation
    _controllerThree = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    _animationThree = Tween<double>(begin: -5.0, end: 5.0).animate(
      CurvedAnimation(parent: _controllerThree, curve: Curves.elasticIn),
    );
    _controllerThree.forward();
  }

  Future<void> _initializeData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });
      _news = await _getNews();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load news: $e';
      });
      print('Error loading news: $e');
    }
  }

  Future<List<Map<dynamic, dynamic>>> _getNews() async {
    final url = Uri.parse(
        //Change this brother
        // 'https://www.alphavantage.co/query?function=NEWS_SENTIMENT&tickers=&apikey=$newsApiKey',
        // 'https://www.alphavantage.co/query?function=NEWS_SENTIMENT2&tickers=&apikey=$newsApiKey',
        'https://www.alphavantage.co/query?function=NEWS_SENTIMENT&tickers=AAPL&apikey=demo');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (!data.containsKey('feed')) {
        throw Exception('Invalid response format: missing feed key');
      }

      final newsList = data['feed'] as List<dynamic>;
      final filteredNews = newsList.where((item) {
        return item != null && item['title'] != null && item['url'] != null;
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

  // Future<List<Map<dynamic, dynamic>>> _getNews() async {
  //   final url = Uri.parse(
  //       'https://share-market-news-api-india.p.rapidapi.com/marketNews');

  //   final response = await http.get(
  //     url,
  //     headers: {
  //       'x-rapidapi-host': 'share-market-news-api-india.p.rapidapi.com',
  //       'x-rapidapi-key': '44419d2e7cmshb89f03029433720p189f6ejsnc93776741a4a',
  //     },
  //   );

  //   if (response.statusCode == 200) {
  //     final List<dynamic> data = json.decode(response.body);

  //     return data.map((item) {
  //       return {
  //         'title': item['Title'] ?? 'No title',
  //         'url': item['URL'] ?? '',
  //         'source': item['Source'] ?? 'Unknown',
  //       };
  //     }).toList();
  //   } else {
  //     throw Exception('Failed to load news: ${response.statusCode}');
  //   }
  // }

  Color _getSentimentColor(String sentiment) {
    switch (sentiment.toLowerCase()) {
      case 'bullish':
        return Colors.green;
      case 'somewhat-bullish':
        return Colors.lightGreen;
      case 'neutral':
        return Colors.grey;
      case 'somewhat-bearish':
        return Colors.orange;
      case 'bearish':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<List<Map<String, String>>> _getSuggestions(String query) async {
    if (query.isEmpty) return [];

    final url =
        Uri.parse('https://finnhub.io/api/v1/search?q=$query&token=$finKEy');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results = data['result'];

      if (results == null || results is! List) return [];

      return (results as List).map((result) {
        return {
          'symbol': result['symbol'] as String? ?? '',
          'name': result['description'] as String? ?? '',
        };
      }).toList();
    } else {
      throw Exception('Failed to load suggestions');
    }
  }

  void _navigateToDetailsPage(Map<String, String> stockDetails) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StockPage(stockDetails),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      print('Error launching URL: $e');
    }
  }

  Widget _buildNewsItem(Map<dynamic, dynamic> newsItem) {
    return Container(
      padding: EdgeInsets.all(12),
      margin: EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.5),
            Colors.black.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: newsItem['banner_image'] != null &&
                        newsItem['banner_image'].isNotEmpty
                    ? Image.network(
                        newsItem['banner_image'],
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            "assets/images/logo_named.png",
                            width: 100,
                            height: 100,
                          );
                        },
                      )
                    : Image.asset(
                        "assets/images/logo_named.png",
                        width: 100,
                        height: 100,
                      ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      newsItem['title'] ?? 'No title',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Source: ${newsItem['source'] ?? 'Unknown'} | Author: ${newsItem['authors']}',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    if (newsItem['overall_sentiment_label'] != null)
                      Container(
                        margin: EdgeInsets.only(top: 5),
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getSentimentColor(
                              newsItem['overall_sentiment_label']),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          newsItem['overall_sentiment_label'],
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (newsItem['summary'] != null) ...[
            SizedBox(height: 8),
            Text(
              newsItem['summary'],
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 12,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          Divider(color: Colors.grey[800]),
          InkWell(
            onTap: () => _launchURL(newsItem['url'] ?? ''),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Read More',
                  style: TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  Icons.link,
                  color: Colors.blue,
                  size: 16,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildNewsItem(Map<dynamic, dynamic> newsItem) {
  //   return Container(
  //     padding: EdgeInsets.all(12),
  //     margin: EdgeInsets.symmetric(vertical: 6),
  //     decoration: BoxDecoration(
  //       border: Border.all(color: Colors.grey.withOpacity(0.3)),
  //       borderRadius: BorderRadius.circular(12),
  //       gradient: LinearGradient(
  //         colors: [
  //           Colors.black.withOpacity(0.5),
  //           Colors.black.withOpacity(0.3),
  //         ],
  //         begin: Alignment.topLeft,
  //         end: Alignment.bottomRight,
  //       ),
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Text(
  //           newsItem['title'] ?? 'No title',
  //           style: TextStyle(
  //             color: Colors.white,
  //             fontWeight: FontWeight.bold,
  //             fontSize: 16,
  //           ),
  //           maxLines: 3,
  //           overflow: TextOverflow.ellipsis,
  //         ),
  //         SizedBox(height: 8),
  //         Text(
  //           'Source: ${newsItem['source']}',
  //           style: TextStyle(
  //             color: Colors.grey,
  //             fontSize: 12,
  //           ),
  //         ),
  //         Divider(color: Colors.grey[800]),
  //         InkWell(
  //           onTap: () => _launchURL(newsItem['url'] ?? ''),
  //           child: Row(
  //             mainAxisAlignment: MainAxisAlignment.center,
  //             children: [
  //               Text(
  //                 'Read More',
  //                 style: TextStyle(
  //                   color: Colors.blue,
  //                   decoration: TextDecoration.underline,
  //                 ),
  //               ),
  //               SizedBox(width: 4),
  //               Icon(
  //                 Icons.link,
  //                 color: Colors.blue,
  //                 size: 16,
  //               ),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Color(0xFF0D1B2A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          "assets/images/logo_bgless.png",
                          width: 50,
                          height: 50,
                        ),
                        SizedBox(width: 15),
                        Text(
                          'FinSight',
                          style: TextStyle(
                              fontSize: 30,
                              color: Theme.of(context).focusColor),
                        ),
                      ],
                    ),
                    // Portfolio Button
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => WatchListPage()),
                        );
                      },
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color.fromARGB(255, 7, 45, 75)
                                  .withOpacity(0.7),
                              const Color.fromARGB(255, 234, 177, 244)
                                  .withOpacity(0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              spreadRadius: 1,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.list,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Portfolio',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Form(
                  key: _formKey,
                  child: Row(
                    children: [
                      Expanded(
                        child: TypeAheadField<Map<String, String>>(
                          suggestionsCallback: (pattern) async {
                            return await _getSuggestions(pattern);
                          },
                          builder: (context, controller, focusNode) {
                            return TextField(
                              controller: controller,
                              focusNode: focusNode,
                              style: TextStyle(
                                  color: Theme.of(context).focusColor),
                              textCapitalization: TextCapitalization.characters,
                              decoration: InputDecoration(
                                hintText: "Search Stock Here...",
                                hintStyle: const TextStyle(color: Colors.grey),
                                filled: true,
                                fillColor: Colors.transparent,
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 15.0, horizontal: 20.0),
                                border: const OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(30.0)),
                                  borderSide: BorderSide(
                                      color: Colors.grey, width: 1.5),
                                ),
                                enabledBorder: const OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(30.0)),
                                  borderSide: BorderSide(
                                      color: Colors.grey, width: 1.5),
                                ),
                                focusedBorder: const OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(30.0)),
                                  borderSide: BorderSide(
                                      color: Colors.white, width: 1.5),
                                ),
                              ),
                            );
                          },
                          itemBuilder: (context, suggestion) {
                            return ListTile(
                              title: Row(
                                children: [
                                  Text(
                                    '${suggestion['symbol']} - ',
                                    style: TextStyle(
                                      color: Theme.of(context).focusColor,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '${suggestion['name']}',
                                      style: TextStyle(
                                          color: Theme.of(context).focusColor),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          onSelected: (suggestion) {
                            _textSearch.text = suggestion['symbol']!;
                            _navigateToDetailsPage(suggestion);
                          },
                          decorationBuilder: (context, child) {
                            return Material(
                              type: MaterialType.card,
                              elevation: 4,
                              color: Theme.of(context).cardColor,
                              child: child,
                            );
                          },
                          emptyBuilder: (context) => Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'No items found',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Row(
                          children: [
                            Text(
                              firstName,
                              style: TextStyle(
                                  fontSize: 45,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).focusColor),
                            ),
                            SizedBox(width: 10),
                            AnimatedBuilder(
                              animation: _animationThree,
                              child: Icon(
                                Icons.waving_hand_rounded,
                                size: 40,
                                color: Theme.of(context).focusColor,
                              ),
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(_animationThree.value, 0),
                                  child: child,
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    Text(
                      _textWelcome.substring(0, _animationTwo.value),
                      style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).focusColor),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Divider(color: Colors.white24),
                Text(
                  'TOP MARKET INSIGHTS',
                  style: TextStyle(
                      color: Theme.of(context).focusColor, fontSize: 18),
                ),
                SizedBox(height: 10),
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: Theme.of(context).focusColor,
                          ),
                        )
                      : _error.isNotEmpty
                          ? Center(
                              child: Text(
                                _error,
                                style: TextStyle(color: Colors.white),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _news.length,
                              itemBuilder: (context, index) {
                                return _buildNewsItem(_news[index]);
                              },
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controllerOne.dispose();
    _controllerTwo.dispose();
    _controllerThree.dispose();
    super.dispose();
  }
}
