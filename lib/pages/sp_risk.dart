import 'package:datazen/core/globalvariables.dart';
import 'package:flutter/material.dart';
import 'package:glass_kit/glass_kit.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';


class RiskAnalysisPage extends StatefulWidget {
  final Map<String, double> portfolioWeights;

  RiskAnalysisPage({required this.portfolioWeights});

  @override
  _RiskAnalysisPageState createState() => _RiskAnalysisPageState();
}

class _RiskAnalysisPageState extends State<RiskAnalysisPage> {
  bool isLoading = true;
  Uint8List? decodedImage1;
  Uint8List? decodedImage2;
  Uint8List? decodedImage3;
  final String apiUrl = '${GlobalVariable.url}/analyze_risk';

  @override
  void initState() {
    super.initState();
    analyzePortfolio();
  }

  Future<void> analyzePortfolio() async {
    try {
      final requestData = {
        'portfolio': widget.portfolioWeights
            .map((stock, weight) => MapEntry(stock, weight / 100))
      };

      print('Sending request with data: ${jsonEncode(requestData)}');

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestData),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final plots = responseData['plots'];

        setState(() {
          decodedImage1 = base64Decode(plots['allocation_plot']);
          decodedImage2 = base64Decode(plots['risks_plot']);
          decodedImage3 = base64Decode(plots['historical_plot']);
          // Add the second plot key based on your API response
          // decodedImage2 = base64Decode(plots['your_second_plot_key']);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to analyze portfolio: ${response.statusCode}');
      }
    } catch (e) {
      print('Error during analysis: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error analyzing portfolio: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
                    Text(
                      'Risk Analysis Results',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: Colors.white,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Analyzing portfolio risk...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Portfolio Summary
                            GlassContainer(
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
                              borderRadius: BorderRadius.circular(20),
                              borderWidth: 1.5,
                              margin: EdgeInsets.only(bottom: 16),
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Portfolio Composition',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      widget.portfolioWeights.entries
                                          .map((e) =>
                                              '${e.key}: ${e.value.toStringAsFixed(2)}%')
                                          .join(', '),
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // First Analysis Image
                            if (decodedImage1 != null)
                              GlassContainer(
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
                                margin: EdgeInsets.symmetric(vertical: 8),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.memory(
                                    decodedImage1!,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),

                            // Second Analysis Image
                            if (decodedImage2 != null)
                              GlassContainer(
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
                                margin: EdgeInsets.symmetric(vertical: 8),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.memory(
                                    decodedImage2!,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            if (decodedImage3 != null)
                              GlassContainer(
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
                                margin: EdgeInsets.symmetric(vertical: 8),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.memory(
                                    decodedImage3!,
                                    fit: BoxFit.contain,
                                  ),
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
