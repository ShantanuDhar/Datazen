import 'package:datazen/apikeys.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class StockPage extends StatefulWidget {
  final Map<String, dynamic> stockDetails;

  StockPage(this.stockDetails);

  @override
  _StockPageState createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  bool isLoading = true;
  Map<String, dynamic> stockData = {};
  String errorMessage = '';
  bool isInWatchlist = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    fetchStockData();
    checkWatchlistStatus();
  }

  Future<void> fetchStockData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final data = await fetchHistoricalStockData(
        widget.stockDetails['symbol'] ?? '',
        'IN', // Assuming all stocks are Indian
      );
      setState(() {
        stockData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error: ${e.toString()}';
      });
    }
  }

  Future<Map<String, dynamic>> fetchHistoricalStockData(
      String symbol, String region) async {
    final String apiUrl =
        'https://apidojo-yahoo-finance-v1.p.rapidapi.com/stock/v3/get-historical-data';
    final Map<String, String> queryParams = {
      'symbol': symbol,
      'region': region,
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
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load stock data: ${response.statusCode}');
    }
  }

  Future<void> checkWatchlistStatus() async {
    final String? userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('portfolio')
          .where('symbol', isEqualTo: widget.stockDetails['symbol'])
          .get();

      setState(() {
        isInWatchlist = snapshot.docs.isNotEmpty;
      });
    } catch (e) {
      print('Error checking watchlist status: $e');
    }
  }

  Future<void> toggleWatchlistStatus() async {
    final String? userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final stockDoc = _firestore
        .collection('users')
        .doc(userId)
        .collection('portfolio')
        .doc(widget.stockDetails['symbol']);

    try {
      if (isInWatchlist) {
        // Remove from Firestore
        await stockDoc.delete();
      } else {
        // Add to Firestore
        await stockDoc.set(widget.stockDetails);
      }

      setState(() {
        isInWatchlist = !isInWatchlist;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isInWatchlist
              ? "${widget.stockDetails['name']} added to watchlist"
              : "${widget.stockDetails['name']} removed from watchlist"),
        ),
      );
    } catch (e) {
      print('Error toggling watchlist status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: Text(
          widget.stockDetails['name'] ?? 'Stock Details',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(isInWatchlist ? Icons.star : Icons.star_border),
            onPressed: toggleWatchlistStatus,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Color(0xFF0D1B2A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : errorMessage.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(errorMessage, style: TextStyle(color: Colors.red)),
                        ElevatedButton(
                          onPressed: fetchStockData,
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : buildStockDetails(),
      ),
    );
  }

  Widget buildStockDetails() {
    final latestData = stockData['prices']?[0] ?? {};
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.stockDetails['symbol']} - ${widget.stockDetails['name']}',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            SizedBox(height: 20),
            buildInfoCard('Price', latestData['close']?.toString() ?? 'N/A'),
            buildInfoCard('Open', latestData['open']?.toString() ?? 'N/A'),
            buildInfoCard('High', latestData['high']?.toString() ?? 'N/A'),
            buildInfoCard('Low', latestData['low']?.toString() ?? 'N/A'),
            buildInfoCard('Volume', latestData['volume']?.toString() ?? 'N/A'),
            buildInfoCard('Date', _formatDate(latestData['date'])),
            SizedBox(height: 20),
            buildStockChart(),
          ],
        ),
      ),
    );
  }

  Widget buildInfoCard(String label, String value) {
    return Card(
      color: Colors.grey[850],
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(label, style: TextStyle(color: Colors.white)),
        trailing: Text(value, style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget buildStockChart() {
    List<FlSpot> spots = [];
    final prices = stockData['prices'] ?? [];
    for (int i = 0; i < prices.length && i < 10; i++) {
      final closePrice = prices[i]['close'];
      if (closePrice != null) {
        spots.add(FlSpot(i.toDouble(), closePrice.toDouble()));
      }
    }

    return Container(
      height: 200,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: LineChart(
        LineChartData(
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.greenAccent,
              belowBarData: BarAreaData(
                show: true,
                color: Colors.greenAccent.withOpacity(0.3),
              ),
            ),
          ],
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
        ),
      ),
    );
  }

  String _formatDate(int? timestamp) {
    if (timestamp == null) return 'N/A';
    return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000).toString();
  }
}
