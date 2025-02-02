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

  /// Method to safely retrieve valid data or show 'N/A'
  String _safeData(dynamic value) {
    if (value == null || (value is num && value.isNaN)) {
      return 'N/A';
    }
    return value.toString();
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
          decodedImage1 = plots['allocation_plot'] != null
              ? base64Decode(plots['allocation_plot'])
              : null;
          decodedImage2 = plots['risks_plot'] != null
              ? base64Decode(plots['risks_plot'])
              : null;
          decodedImage3 = plots['historical_plot'] != null
              ? base64Decode(plots['historical_plot'])
              : null;
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
                                              '${e.key}: ${_safeData(e.value)}%')
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
                              )
                            else
                              _buildPlaceholder(
                                  'Allocation Plot Not Available'),

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
                              )
                            else
                              _buildPlaceholder('Risks Plot Not Available'),

                            // Third Analysis Image
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
                              )
                            else
                              _buildPlaceholder(
                                  'Historical Plot Not Available'),
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

  Widget _buildPlaceholder(String message) {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child: Text(
        message,
        style: TextStyle(color: Colors.white, fontSize: 16),
        textAlign: TextAlign.center,
      ),
    );
  }
}
