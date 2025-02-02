import 'package:datazen/core/globalvariables.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'sp_stock.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class WatchListPage extends StatefulWidget {
  const WatchListPage({super.key});

  @override
  State<WatchListPage> createState() => _WatchListPageState();
}

class _WatchListPageState extends State<WatchListPage> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  /// Fetch stock price using Flask API
  Future<Map<String, dynamic>> fetchStockPrice(String symbol) async {
    try {
      final String apiUrl = '${GlobalVariable.url}/stock-info';
      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'ticker': symbol}),
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 200 && data.containsKey('data')) {
          final latestData = data['data'].isNotEmpty ? data['data'][0] : {};
          return {
            'price': latestData['Close'].toString(),
            'change':
                latestData['Price_Change']?.toDouble() > 0 ? 'up' : 'down',
          };
        } else {
          throw Exception("Invalid API response");
        }
      } else {
        throw Exception('Failed to fetch stock data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching stock data: $e');
      throw e;
    }
  }

  /// Fetch stock price and update Firebase
  Future<void> _updateStockPrice(Map<String, dynamic> stock) async {
    try {
      final stockData = await fetchStockPrice(stock['symbol']);
      stock['price'] = stockData['price'];
      stock['change'] = stockData['change'];

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('portfolio')
            .doc(stock['symbol'])
            .update({
          'price': stock['price'],
          'change': stock['change'],
        });
      }
    } catch (e) {
      print('Error updating stock price: $e');
    }
  }

  Future<void> _removeFromWatchList(String symbol) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception("User not logged in");
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('portfolio')
          .doc(symbol)
          .delete();
    } catch (e) {
      print('Error removing from watchlist: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return Center(child: Text('User not logged in'));
    }

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
              crossAxisAlignment: CrossAxisAlignment.start,
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
                      'FinSight ',
                      style: TextStyle(
                        fontSize: 35,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  "MY WATCHLIST",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Divider(color: Colors.grey[800]),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .collection('portfolio')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.hourglass_empty,
                                color: Colors.white,
                                size: 30,
                              ),
                              SizedBox(height: 15),
                              Text(
                                "Your watchlist is empty",
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        );
                      }

                      final watchList = snapshot.data!.docs;

                      return ListView.builder(
                        itemCount: watchList.length,
                        itemBuilder: (context, index) {
                          final stock = watchList[index];
                          final stockData =
                              stock.data() as Map<String, dynamic>;

                          // Fetch and update the price and trend in real-time
                          _updateStockPrice(stockData);

                          return Dismissible(
                            key: Key(stockData['symbol']),
                            direction: DismissDirection.endToStart,
                            onDismissed: (direction) {
                              _removeFromWatchList(stockData['symbol']);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      "${stockData['name']} removed from watchlist"),
                                ),
                              );
                            },
                            child: Card(
                              margin: EdgeInsets.symmetric(vertical: 5),
                              color: Colors.grey[900],
                              child: ListTile(
                                title: Text(
                                  stockData['name'],
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  stockData['symbol'],
                                  style: TextStyle(color: Colors.grey[400]),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          StockPage(stockData),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      );
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
}
