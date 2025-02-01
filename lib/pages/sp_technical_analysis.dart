import 'dart:convert';
import 'package:datazen/core/globalvariables.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TechnicalAnalysisPage extends StatefulWidget {
  final String stockSymbol;

  TechnicalAnalysisPage({required this.stockSymbol});

  @override
  _TechnicalAnalysisPageState createState() => _TechnicalAnalysisPageState();
}

class _TechnicalAnalysisPageState extends State<TechnicalAnalysisPage> {
  bool showCharts = false;
  Map<String, dynamic> analysisData = {};
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    performTechnicalAnalysis();
  }

  Future<void> performTechnicalAnalysis() async {
    final response = await http.post(
      Uri.parse('${GlobalVariable.url}/technical-analyze'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'ticker': widget.stockSymbol}),
    );

    if (response.statusCode == 200) {
      setState(() {
        analysisData = jsonDecode(response.body);
        showCharts = true;
        errorMessage = '';
      });
    } else {
      setState(() {
        errorMessage =
            'Error fetching data: ${jsonDecode(response.body)['error']}';
      });
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
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(),
                if (errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      errorMessage,
                      style: TextStyle(color: Colors.redAccent, fontSize: 14),
                    ),
                  ),
                if (showCharts) _buildChartsSection(),
                if (showCharts) _buildDataTable(),
              ],
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
          Text(
            'Technical Analysis - ${widget.stockSymbol.toUpperCase()}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection() {
    final charts = analysisData['charts'] ?? {};
    final priceChart = charts['price_chart'];
    final technicalChart = charts['technical_chart'];

    return Column(
      children: [
        if (priceChart != null)
          _buildChartFromBase64(priceChart, 'Price Chart'),
        if (technicalChart != null)
          _buildChartFromBase64(technicalChart, 'Technical Chart'),
      ],
    );
  }

  Widget _buildChartFromBase64(String base64Image, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.white, fontSize: 18)),
          SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
            ),
            child: Image.memory(
              base64Decode(base64Image),
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    final companyInfo = analysisData['company_info'] ?? {};
    final riskMetrics = analysisData['risk_metrics'] ?? {};
    final technicalSignals = analysisData['technical_signals'] ?? {};

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildInfoTable('Company Info', companyInfo),
          _buildInfoTable('Risk Metrics', riskMetrics),
          _buildInfoTable('Technical Signals', technicalSignals),
        ],
      ),
    );
  }

  Widget _buildInfoTable(String title, Map<String, dynamic> data) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: Colors.white, fontSize: 18)),
              SizedBox(height: 10),
              DataTable(
                columns: [
                  DataColumn(
                      label: Text('Metric',
                          style: TextStyle(color: Colors.white))),
                  DataColumn(
                      label:
                          Text('Value', style: TextStyle(color: Colors.white))),
                ],
                rows: data.entries.map((entry) {
                  return DataRow(cells: [
                    DataCell(Text(entry.key,
                        style: TextStyle(color: Colors.white70))),
                    DataCell(Text(entry.value.toString(),
                        style: TextStyle(color: Colors.white))),
                  ]);
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
