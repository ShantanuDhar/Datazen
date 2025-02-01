import 'package:flutter/material.dart';
import 'package:glass_kit/glass_kit.dart';

class StockInsightsPage extends StatefulWidget {
  @override
  _StockInsightsPageState createState() => _StockInsightsPageState();
}

class _StockInsightsPageState extends State<StockInsightsPage> {
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
              GlassContainer(
                height: 80,
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
                elevation: 3,
                margin: EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'Stock Insights',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              // Implement stock insights logic here
            ],
          ),
        ),
      ),
    );
  }
}
