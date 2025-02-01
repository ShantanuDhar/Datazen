import 'package:flutter/material.dart';
import 'package:glass_kit/glass_kit.dart';

class StockPredictionPage extends StatefulWidget {
  @override
  _StockPredictionPageState createState() => _StockPredictionPageState();
}

class _StockPredictionPageState extends State<StockPredictionPage> {
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
              _buildHeader()
              // Implement stock price prediction logic here
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildHeader() {
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Row(
      children: [
        Image.asset(
          "assets/images/logo_bgless.png",
          width: 50,
          height: 50,
        ),
        SizedBox(width: 15),
        Expanded(
          child: Text(
            'Market Insights',
            style: TextStyle(
              fontSize: 30,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}
