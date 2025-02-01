import 'package:datazen/pages/sp_stock.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;


class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<Map<String, String>> _watchList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWatchList();
  }

  Future<void> _loadWatchList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? watchListData = prefs.getStringList('watchlist');
      final List<Map<String, String>> watchList = watchListData != null
          ? watchListData
              .map((item) => Map<String, String>.from(json.decode(item) as Map))
              .toList()
          : [];
      setState(() {
        _watchList = watchList;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading watchlist: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>> fetchStockData(String symbol) async {
    final String apiUrl =
        'https://apidojo-yahoo-finance-v1.p.rapidapi.com/stock/v3/get-historical-data';
    final Map<String, String> queryParams = {
      'symbol': symbol,
      'region': 'IN', // Assuming all stocks are Indian
    };

    final Uri uri = Uri.parse(apiUrl).replace(queryParameters: queryParams);
    final response = await http.get(
      uri,
      headers: {
        'x-rapidapi-host': 'apidojo-yahoo-finance-v1.p.rapidapi.com',
        'x-rapidapi-key': 'YOUR_RAPID_API_KEY',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load stock data: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Stock Dashboard', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.grey[900],
      ),
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
            padding: const EdgeInsets.all(16.0),
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Watchlist",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 10),
                      Expanded(
                        child: _watchList.isEmpty
                            ? Center(
                                child: Text(
                                  "Your watchlist is empty",
                                  style: TextStyle(color: Colors.white),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _watchList.length,
                                itemBuilder: (context, index) {
                                  final stock = _watchList[index];
                                  return Card(
                                    color: Colors.grey[850],
                                    margin: EdgeInsets.symmetric(vertical: 8),
                                    child: ListTile(
                                      title: Text(
                                        stock['name']!,
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      subtitle: Text(
                                        stock['symbol']!,
                                        style:
                                            TextStyle(color: Colors.grey[400]),
                                      ),
                                      trailing:
                                          FutureBuilder<Map<String, dynamic>>(
                                        future:
                                            fetchStockData(stock['symbol']!),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return CircularProgressIndicator();
                                          } else if (snapshot.hasError) {
                                            return Icon(Icons.error,
                                                color: Colors.red);
                                          } else {
                                            final latestData =
                                                snapshot.data!['prices'][0];
                                            return Column(
                                              children: [
                                                Text(
                                                  "\$${latestData['close']}",
                                                  style: TextStyle(
                                                      color:
                                                          Colors.greenAccent),
                                                ),
                                                Icon(
                                                  latestData['close'] >
                                                          latestData['open']
                                                      ? Icons.trending_up
                                                      : Icons.trending_down,
                                                  color: latestData['close'] >
                                                          latestData['open']
                                                      ? Colors.green
                                                      : Colors.red,
                                                ),
                                              ],
                                            );
                                          }
                                        },
                                      ),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                StockPage(stock),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        "Market Overview",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 10),
                      _buildMarketOverviewChart(),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildMarketOverviewChart() {
    // Sample data for chart, you can replace this with your own data
    List<FlSpot> spots = [
      FlSpot(0, 100),
      FlSpot(1, 110),
      FlSpot(2, 90),
      FlSpot(3, 115),
      FlSpot(4, 105),
      FlSpot(5, 130),
    ];

    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          borderData:
              FlBorderData(show: true, border: Border.all(color: Colors.white)),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.greenAccent,
              belowBarData: BarAreaData(show: false),
            ),
          ],
          titlesData: FlTitlesData(
              // bottomTitles: SideTitles(showTitles: true, reservedSize: 22, getTitlesWidget: (value, meta) {
              //   switch (value.toInt()) {
              //     case 0:
              //       return Text('Mon', style: TextStyle(color: Colors.white));
              //     case 1:
              //       return Text('Tue', style: TextStyle(color: Colors.white));
              //     case 2:
              //       return Text('Wed', style: TextStyle(color: Colors.white));
              //     case 3:
              //       return Text('Thu', style: TextStyle(color: Colors.white));
              //     case 4:
              //       return Text('Fri', style: TextStyle(color: Colors.white));
              //     case 5:
              //       return Text('Sat', style: TextStyle(color: Colors.white));
              //     default:
              //       return Text('');
              //   }
              // }),
              // leftTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (value, meta) {
              //   return Text(value.toString(), style: TextStyle(color: Colors.white));
              // }),
              ),
        ),
      ),
    );
  }
}
