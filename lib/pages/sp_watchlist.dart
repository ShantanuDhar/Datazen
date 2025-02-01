import 'package:datazen/apikeys.dart';
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  Future<void> _fetchStockPrice(Map<String, dynamic> stock) async {
    try {
      final priceData = await fetchLatestStockData(stock['symbol']);
      stock['price'] = priceData['close'].toString();
      stock['change'] = priceData['close'] > priceData['open'] ? 'up' : 'down';

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
      print('Error fetching stock price: $e');
    }
  }

  Future<Map<String, dynamic>> fetchLatestStockData(String symbol) async {
    final String apiUrl =
        'https://apidojo-yahoo-finance-v1.p.rapidapi.com/stock/v3/get-historical-data';
    final Map<String, String> queryParams = {
      'symbol': symbol,
      'region': 'IN',
    };

    final Uri uri = Uri.parse(apiUrl).replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {
        'x-rapidapi-host': 'apidojo-yahoo-finance-v1.p.rapidapi.com',
        'x-rapidapi-key': RapidApiKEy,
      },
    ).timeout(Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['prices']?[0];
    } else {
      throw Exception('Failed to load stock data: ${response.statusCode}');
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
                      'Profit Pocket',
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
                          final stockData = stock.data() as Map<String, dynamic>;

                          // Fetch and update the price and trend in real-time
                          _fetchStockPrice(stockData);

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
                            background: Container(
                              color: Colors.red,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Padding(
                                  padding: const EdgeInsets.all(15.0),
                                  child:
                                      Icon(Icons.delete, color: Colors.white),
                                ),
                              ),
                            ),
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
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (stockData.containsKey('price'))
                                      Text(
                                        "\$${stockData['price']}",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    if (stockData.containsKey('change'))
                                      Icon(
                                        stockData['change'] == 'up'
                                            ? Icons.trending_up
                                            : Icons.trending_down,
                                        color: stockData['change'] == 'up'
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                  ],
                                ),
                                onTap: () async {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => StockPage(stockData),
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
