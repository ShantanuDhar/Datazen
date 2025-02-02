import 'package:datazen/core/globalvariables.dart';
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
  List<Map<String, dynamic>> stockData = [];
  String errorMessage = '';
  bool isInWatchlist = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    fetchStockData(widget.stockDetails['symbol']).then((data) {
      setState(() {
        stockData = data['prices'] ?? [];
        isLoading = false;
      });
    }).catchError((e) {
      setState(() {
        errorMessage = 'Error fetching data: $e';
        isLoading = false;
      });
    });
    checkWatchlistStatus();
  }

  Future<Map<String, dynamic>> fetchStockData(String stockSymbol) async {
    try {
      final Uri uri = Uri.parse('${GlobalVariable.url}/stock-info');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'ticker': stockSymbol}),
      );

      if (response.statusCode == 200) {
        // Replace NaN with 0
        final sanitizedResponse = response.body.replaceAll('NaN', '0');
        final Map<String, dynamic> data = json.decode(sanitizedResponse);

        if (data['status'] == 200) {
          final prices = (data['data'] as List<dynamic>)
              .map((entry) => {
                    'date': entry['Date'],
                    'open': entry['Open'],
                    'high': entry['High'],
                    'low': entry['Low'],
                    'close': entry['Close'],
                    'volume': entry['Volume'],
                    'change': entry['Price_Change'],
                    'direction': entry['Change_Direction'],
                  })
              .toList();

          return {'prices': prices};
        } else {
          throw Exception('API returned an error status');
        }
      } else {
        throw Exception('Failed to fetch data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching stock data: $e');
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
        await stockDoc.delete();
      } else {
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
                          onPressed: () async {
                            setState(() => isLoading = true);
                            await fetchStockData(widget.stockDetails['symbol'])
                                .then((data) {
                              setState(() {
                                stockData = data['prices'] ?? [];
                                isLoading = false;
                              });
                            }).catchError((e) {
                              setState(() {
                                errorMessage = 'Error fetching data: $e';
                                isLoading = false;
                              });
                            });
                          },
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
    if (stockData.isEmpty) {
      return Center(
        child: Text(
          'No stock data available',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    final latestData = stockData.first;
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
            buildInfoCard('Volume', latestData['volume']?.toString() ?? 'N/A'),
            buildInfoCard('Date', latestData['date'] ?? 'N/A'),
            buildInfoCard(
                'Price Change', latestData['change']?.toString() ?? 'N/A'),
            buildInfoCard('Change Direction', latestData['direction'] ?? 'N/A'),
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
    for (int i = 0; i < stockData.length && i < 10; i++) {
      final closePrice = stockData[i]['close'];
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
}
