import 'package:datazen/pages/sp_technical_analysis.dart';
import 'package:flutter/material.dart';

class TickerListPage extends StatelessWidget {
  final List<dynamic> tickers;

  TickerListPage({required this.tickers});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF0D1B2A),
        title: Text("Tickers List", style: TextStyle(color: Colors.white)),
      ),
      body: tickers.isEmpty
          ? Center(
              child: Text(
                "No tickers available",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(16.0),
              itemCount: tickers.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: (){
                    Navigator.push(context, MaterialPageRoute(builder: (context) => TechnicalAnalysisPage(stockSymbol:  tickers[index])));
                  },
                  child: Card(
                    color: Colors.grey[850],
                    margin: EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        tickers[index],
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
