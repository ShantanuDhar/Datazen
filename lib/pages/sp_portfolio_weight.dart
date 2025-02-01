import 'package:datazen/pages/sp_risk.dart';
import 'package:flutter/material.dart';
import 'package:glass_kit/glass_kit.dart';


class PortfolioWeightPage extends StatefulWidget {
  final List<String> stocks;

  PortfolioWeightPage({required this.stocks});

  @override
  _PortfolioWeightPageState createState() => _PortfolioWeightPageState();
}

class _PortfolioWeightPageState extends State<PortfolioWeightPage> {
  Map<String, double> stockWeights = {};
  double totalPercentage = 0;

  @override
  void initState() {
    super.initState();
    // Initialize all stocks with 0%
    widget.stocks.forEach((stock) {
      stockWeights[stock] = 0;
    });
  }

  void updateTotalPercentage() {
    totalPercentage =
        stockWeights.values.fold(0, (sum, weight) => sum + weight);
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Portfolio Weights',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Total: ${totalPercentage.toStringAsFixed(2)}%',
                            style: TextStyle(
                              color: totalPercentage == 100
                                  ? Colors.green
                                  : Colors.red,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Stock Weight Inputs
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: widget.stocks.length,
                  itemBuilder: (context, index) {
                    String stock = widget.stocks[index];
                    return GlassContainer(
                      height: 120,
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
                      borderRadius: BorderRadius.circular(16),
                      borderWidth: 1.5,
                      margin: EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stock,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Slider(
                                    value: stockWeights[stock] ?? 0,
                                    min: 0,
                                    max: 100,
                                    divisions: 100,
                                    activeColor: Colors.blue,
                                    inactiveColor: Colors.blue.withOpacity(0.3),
                                    onChanged: (value) {
                                      setState(() {
                                        stockWeights[stock] = value;
                                        updateTotalPercentage();
                                      });
                                    },
                                  ),
                                ),
                                SizedBox(width: 16),
                                Text(
                                  '${(stockWeights[stock] ?? 0).toStringAsFixed(2)}%',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
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

              // Continue Button
              Padding(
                padding: EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: totalPercentage == 100
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RiskAnalysisPage(
                                portfolioWeights: stockWeights,
                              ),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.withOpacity(0.3),
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Analyze Risk',
                    style: TextStyle(fontSize: 18),
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
