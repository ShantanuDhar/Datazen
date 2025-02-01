import 'dart:convert';
import 'package:datazen/core/globalvariables.dart';
import 'package:datazen/pages/sp_long_term_insights.dart';
import 'package:datazen/pages/sp_portfolio_weight.dart';
import 'package:datazen/pages/sp_short_term_insights.dart';
import 'package:flutter/material.dart';
import 'package:glass_kit/glass_kit.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:typed_data';
import 'package:url_launcher/url_launcher.dart';
import 'package:fl_chart/fl_chart.dart';

class RecommendationPage extends StatefulWidget {
  @override
  _RecommendationPageState createState() => _RecommendationPageState();
}

class _RecommendationPageState extends State<RecommendationPage>
    with SingleTickerProviderStateMixin {
  final List<String> sectors = [
    'PVTB',
    'IT',
    'Telecom',
    'Cement',
    'Pharma',
    'Infra',
    'NBFC',
    'FMCG',
    'Metal',
    'PSUB',
    'Power',
    'Cap_Goods',
    'Auto',
    'Oil'
  ];

  List<String> chartImages = [];
  // Add this to store the API URL
  final String apiUrl = '${GlobalVariable.url}/stock-analysis';

  // Other existing variables remain unchanged
  String selectedSector = 'PVTB';

  String? sectorPerformanceImage;
  String? sectorPerformanceImage2;

  List<dynamic> recommendations = [];
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _controller.forward();

    callPerformances();
  }

  Future<void> callPerformances() async {
    await fetchSectorPerformance();

    await fetchSectorAnalysis();
    await fetchRecommendations();
  }

  Widget _buildSectorImage(String base64Image) {
    try {
      Uint8List bytes = base64Decode(base64Image);
      return Image.memory(
        bytes,
        width: double.infinity,
        height: 300,
        fit: BoxFit.contain,
      );
    } catch (e) {
      print('Error decoding image: $e');
      return Text("Error displaying image.");
    }
  }

  Future<void> fetchSectorPerformance() async {
    try {
      final response = await http.post(
        Uri.parse('${GlobalVariable.url}/get_sector_performance'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'date': '2024-10-24'}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(data);
        setState(() {
          sectorPerformanceImage = data['image'];
          chartImages.insert(0, 'data:image/png;base64,${data['image']}');
        });
      } else {
        print('Failed to fetch sector performance: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching sector performance: $e');
    }
  }

  Future<void> fetchSectorAnalysis() async {
    try {
      final response = await http.get(
        Uri.parse('${GlobalVariable.url}/rag_sector'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Ensure the response contains the expected data
        if (data['status'] == 'success' &&
            data['type'] == 'image/png' &&
            data['data'] != null) {
          setState(() {
            sectorPerformanceImage2 = data['data'];
            chartImages.insert(0, 'data:image/png;base64,${data['data']}');
          });
        } else {
          print('Unexpected data format or content in the response');
        }
      } else {
        print('Failed to fetch sector analysis: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching sector analysis: $e');
    }
  }

  Future<void> fetchRecommendations() async {
    try {
      final response = await http.get(
        Uri.parse('${GlobalVariable.url}/stock-analysis?$selectedSector'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          setState(() {
            final sectorData = data['data'][selectedSector];

            recommendations = sectorData.map((item) {
              return {
                'Symbol': item['symbol'],
                'Final_Score': item['final_score'].toString(),
                'Short_Term_Strength': item['short_term_strength'].toString(),
                'Medium_Term_Strength': item['medium_term_strength'].toString(),
                'Long_Term_Strength': item['long_term_strength'].toString(),
                'Sector_Dominance': item['sector_dominance'].toString(),
                'Consistency': item['consistency'].toString(),
                'Market_Adaptability': item['market_adaptability'].toString(),
                'News': item['news'], // List of news articles
              };
            }).toList();
          });
        } else {
          print('Error in data response: ${data['message']}');
        }
      } else {
        print('Failed to fetch recommendations: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching recommendations: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.black, Color(0xFF0D1B2A)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _animation,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(),
                  _buildSectorChart(),
                  //_buildSectorSelector(),
                  //_buildRecommendationsSection(),
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset(
              "assets/images/logo_bgless.png",
              width: 40,
              height: 40,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Market Insights',
                  style: TextStyle(
                    fontSize: 28,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Discover Top Recommendations',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectorChart() {
    if (chartImages.isNotEmpty)
      return Container(
        height: 250,
        margin: EdgeInsets.all(16),
        child: CarouselSlider(
          items: chartImages.map((imageUrl) {
            return GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return Dialog(
                      child: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: imageUrl.startsWith('data:image/png;base64,')
                              ? Image.memory(
                                  base64Decode(imageUrl.split(',')[1]),
                                  fit: BoxFit.contain,
                                )
                              : Image.network(
                                  imageUrl,
                                  fit: BoxFit.contain,
                                ),
                        ),
                      ),
                    );
                  },
                );
              },
              child: Container(
                width: MediaQuery.of(context).size.width,
                margin: EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.2), width: 1.5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: imageUrl.startsWith('data:image/png;base64,')
                      ? Image.memory(
                          base64Decode(imageUrl.split(',')[1]),
                          fit: BoxFit.cover,
                        )
                      : Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
            );
          }).toList(),
          options: CarouselOptions(
            height: 160,
            autoPlay: true,
            enlargeCenterPage: true,
            aspectRatio: 16 / 9,
            viewportFraction: 0.8,
          ),
        ),
      );
    return Container(
      height: 250,
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info, color: Colors.white.withOpacity(0.5), size: 40),
            SizedBox(height: 8),
            Text(
              'Image not available yet',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

//   // Widget _buildSectorSelector() {
//   //   return Container(
//   //     margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//   //     child: GlassContainer(
//   //       height: 60,
//   //       width: double.infinity,
//   //       gradient: LinearGradient(
//   //         colors: [
//   //           Colors.white.withOpacity(0.1),
//   //           Colors.white.withOpacity(0.05),
//   //         ],
//   //       ),
//   //       borderGradient: LinearGradient(
//   //         colors: [
//   //           Colors.white.withOpacity(0.2),
//   //           Colors.white.withOpacity(0.1),
//   //         ],
//   //       ),
//   //       blur: 20,
//   //       borderRadius: BorderRadius.circular(16),
//   //       borderWidth: 1.5,
//   //       child: Padding(
//   //         padding: EdgeInsets.symmetric(horizontal: 16),
//   //         child: DropdownButtonHideUnderline(
//   //           child: DropdownButton<String>(
//   //             value: selectedSector,
//   //             dropdownColor: Color(0xFF1B2B3B),
//   //             style: TextStyle(color: Colors.white),
//   //             icon: Icon(Icons.arrow_drop_down, color: Colors.white),
//   //             isExpanded: true,
//   //             onChanged: (String? newValue) {
//   //               setState(() {
//   //                 selectedSector = newValue!;
//   //                 fetchRecommendations();
//   //               });
//   //             },
//   //             items: sectors.map<DropdownMenuItem<String>>((String value) {
//   //               return DropdownMenuItem<String>(
//   //                 value: value,
//   //                 child: Text(value),
//   //               );
//   //             }).toList(),
//   //           ),
//   //         ),
//   //       ),
//   //     ),
//   //   );
//   // }
// Widget _buildRecommendationsSection() {
//   return Expanded(
//     child: ListView.builder(
//       padding: EdgeInsets.all(16),
//       itemCount: recommendations.length,
//       itemBuilder: (context, index) {
//         final recommendation = recommendations[index];
//         return GlassContainer(
//           height: 500, // Adjusted height for news display
//           width: double.infinity,
//           gradient: LinearGradient(
//             colors: [
//               Colors.white.withOpacity(0.1),
//               Colors.white.withOpacity(0.05),
//             ],
//           ),
//           borderGradient: LinearGradient(
//             colors: [
//               Colors.white.withOpacity(0.2),
//               Colors.white.withOpacity(0.1),
//             ],
//           ),
//           blur: 20,
//           borderRadius: BorderRadius.circular(16),
//           borderWidth: 1.5,
//           margin: EdgeInsets.only(bottom: 16),
//           child: Stack(
//             children: [
//               Positioned(
//                 right: -20,
//                 top: -20,
//                 child: Icon(
//                   Icons.trending_up,
//                   size: 100,
//                   color: Colors.white.withOpacity(0.05),
//                 ),
//               ),
//               Padding(
//                 padding: EdgeInsets.all(16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       recommendation['Symbol'],
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     SizedBox(height: 8),
//                     Wrap(
//                       spacing: 8,
//                       runSpacing: 8,
//                       children: [
//                         _buildInfoLabel('Final Score', recommendation['Final_Score']),
//                         _buildInfoLabel('Short Term Strength', recommendation['Short_Term_Strength']),
//                         _buildInfoLabel('Medium Term Strength', recommendation['Medium_Term_Strength']),
//                         _buildInfoLabel('Long Term Strength', recommendation['Long_Term_Strength']),
//                         _buildInfoLabel('Sector Dominance', recommendation['Sector_Dominance']),
//                         _buildInfoLabel('Consistency', recommendation['Consistency']),
//                         _buildInfoLabel('Market Adaptability', recommendation['Market_Adaptability']),
//                       ],
//                     ),
//                     SizedBox(height: 16),
//                     _buildNewsSection(recommendation['News']),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     ),
//   );
// }

  Widget _buildInfoLabel(String label, dynamic value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value.toString(),
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildNewsSection(List newsList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Related News',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        ...newsList.map((news) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                news['title'] ?? 'No Title',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                news['published_date'] ?? 'Date Unknown',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              GestureDetector(
                onTap: () async {
                  if (await canLaunch(news['url'])) {
                    await launch(news['url']);
                  }
                },
                child: Text(
                  news['url'],
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              SizedBox(height: 12),
            ],
          );
        }).toList(),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: EdgeInsets.all(20),
      height: 375,
      child: Column(
        children: [
          _buildSquareButton(
            'Short Term Insights',
            Icons.assessment,
            Colors.purple,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ShortTermInsightsPage()),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: _buildSquareButton(
              'Long Term Insights',
              Icons.insights,
              Colors.green,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LongTermInsightsPage()),
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: _buildSquareButton(
              'Option Trading',
              Icons.warning,
              Colors.red,
              () async {
                try {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      );
                    },
                  );

                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    final stocksSnapshot = await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .collection('portfolio')
                        .get();

                    Navigator.pop(context);

                    if (stocksSnapshot.docs.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('No stocks found in your portfolio'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final stocks = stocksSnapshot.docs
                        .map((doc) => doc['symbol'] as String)
                        .toList();

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            PortfolioWeightPage(stocks: stocks),
                      ),
                    );
                  }
                } catch (e) {
                  // Hide loading indicator if an error occurs
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error fetching stocks: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSquareButton(
      String text, IconData icon, Color color, VoidCallback onTap) {
    return GlassContainer(
      height: 100,
      width: double.infinity,
      gradient: LinearGradient(
        colors: [
          color.withOpacity(0.2),
          color.withOpacity(0.1),
        ],
      ),
      borderGradient: LinearGradient(
        colors: [
          color.withOpacity(0.3),
          color.withOpacity(0.2),
        ],
      ),
      blur: 20,
      borderRadius: BorderRadius.circular(20),
      borderWidth: 1.5,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 32),
                SizedBox(height: 12),
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showStockPredictionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String stockSymbol = '';
        return Dialog(
          backgroundColor: Colors.transparent,
          child: GlassContainer(
            height: 300,
            width: double.infinity,
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05),
              ],
            ),
            borderGradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.2),
                Colors.white.withOpacity(0.1),
              ],
            ),
            blur: 20,
            borderRadius: BorderRadius.circular(20),
            borderWidth: 1.5,
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Predict Stock Price',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter Stock Symbol',
                      hintStyle: TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white30),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: (value) => stockSymbol = value,
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel ',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.withOpacity(0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  StockPredictionPage(symbol: stockSymbol),
                            ),
                          );
                        },
                        child: Text('Predict'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class PortfolioAnalysisPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.black, Color(0xFF0D1B2A)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    'Portfolio Analysis',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              // Add your portfolio analysis UI here
            ],
          ),
        ),
      ),
    );
  }
}

class StockPredictionPage extends StatelessWidget {
  final String symbol;
  final List<Map<String, dynamic>> predictions = [
    {
      'date': 'Monday, Oct 30',
      'price': 2673.00,
      'change': '+0.63%',
      'trend': 'up'
    },
    {
      'date': 'Tuesday, Oct 31',
      'price': 2687.00,
      'change': '+0.52%',
      'trend': 'up'
    },
    {
      'date': 'Wednesday, Nov 1',
      'price': 2698.00,
      'change': '+0.41%',
      'trend': 'up'
    },
    {
      'date': 'Thursday, Nov 2',
      'price': 2724.00,
      'change': '+0.96%',
      'trend': 'up'
    },
    {
      'date': 'Friday, Nov 3',
      'price': 2722.00,
      'change': '-0.07%',
      'trend': 'down'
    },
  ];

  StockPredictionPage({required this.symbol});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.black, Color(0xFF0D1B2A)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      'Price Prediction: $symbol',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Current Price Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.withOpacity(0.2),
                        Colors.purple.withOpacity(0.2)
                      ],
                    ),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Price',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '₹2,656.30',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20),

              // Predictions Table
              Expanded(
                child: Container(
                  margin: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Price Predictions',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: predictions.length,
                          itemBuilder: (context, index) {
                            final prediction = predictions[index];
                            return Container(
                              margin: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        prediction['date'],
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 16,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        '₹${prediction['price'].toStringAsFixed(2)}',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: prediction['trend'] == 'up'
                                          ? Colors.green.withOpacity(0.2)
                                          : Colors.red.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      prediction['change'],
                                      style: TextStyle(
                                        color: prediction['trend'] == 'up'
                                            ? Colors.green
                                            : Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
