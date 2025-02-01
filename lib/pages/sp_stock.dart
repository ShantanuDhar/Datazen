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
        //ssuming all stocks are Indian
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

  Future<Map<String, dynamic>> fetchHistoricalStockData(String symbol) async {
    try {
      final String apiUrl =
          'https://www.alphavantage.co/query?function=TIME_SERIES_DAILY&symbol=$symbol&outputsize=full&apikey=$alphaVantageKey';

      final Uri uri = Uri.parse(apiUrl);
      final response = await http.get(uri).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('API Response: $data');

        if (data.containsKey('Time Series (Daily)')) {
          final Map<String, dynamic> timeSeries = data['Time Series (Daily)'];

          // Extract the most recent 10 days of data
          final List<Map<String, dynamic>> priceList = timeSeries.entries
              .take(10)
              .map((entry) => {
                    'date': entry.key,
                    'open': entry.value['1. open'],
                    'high': entry.value['2. high'],
                    'low': entry.value['3. low'],
                    'close': entry.value['4. close'],
                    'volume': entry.value['5. volume'],
                  })
              .toList();

          return {'prices': priceList};
        } else {
          throw Exception('Invalid API response format');
        }
      } else {
        throw Exception('Failed to fetch data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching historical stock data: $e');
      throw e;
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
