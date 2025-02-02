import 'dart:io';

import 'package:datazen/core/globalvariables.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class LongTermInsightsPage extends StatefulWidget {
  @override
  _LongTermInsightsPageState createState() => _LongTermInsightsPageState();
}

class _LongTermInsightsPageState extends State<LongTermInsightsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF0D1B2A),
        title: Text(
          'Long Term Insights',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blueAccent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(text: 'Annual Report'),
            Tab(text: 'Louvain Girvan Newman'),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.black, Color(0xFF0D1B2A)],
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildAnnualReportTab(context),
            _buildLouvainGirvanNewmanTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnualReportTab(BuildContext context) {
    // Dummy data for the annual reports
    final List<Map<String, String>> annualReports = [
      {
        "stockName": "Stock A",
        "pdf":
            "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf",
        "recommendationTag": "Buy",
        "verificationTag": "Verified",
      },
      {
        "stockName": "Stock B",
        "pdf": "https://www.africau.edu/images/default/sample.pdf",
        "recommendationTag": "Sell",
        "verificationTag": "Hoax",
      },
      {
        "stockName": "Stock C",
        "pdf":
            "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf",
        "recommendationTag": "Hold",
        "verificationTag": "Verified",
      },
      {
        "stockName": "Stock D",
        "pdf": "https://www.africau.edu/images/default/sample.pdf",
        "recommendationTag": "Buy",
        "verificationTag": "Hoax",
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        itemCount: annualReports.length,
        itemBuilder: (context, index) {
          final report = annualReports[index];

          return Card(
            color: Colors.grey[850],
            margin: EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          report['stockName'] ?? "N/A",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          // Verification Tag
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            margin: EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: report['verificationTag'] == "Verified"
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              report['verificationTag'] ?? "",
                              style: TextStyle(
                                color: report['verificationTag'] == "Verified"
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      _openPdfViewer(context, report['pdf'] ?? "");
                    },
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      color: Colors.black,
                      child: Center(
                        child: Text(
                          "PDF Preview (Tap to View)",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildIconButton(
                        Icons.picture_as_pdf,
                        "View PDF",
                        Colors.orangeAccent,
                        () {
                          _openPdfViewer(context, report['pdf'] ?? "");
                        },
                      ),
                      _buildIconButton(
                        Icons.summarize_outlined,
                        "Summarize",
                        Colors.blueAccent,
                        () {
                          print("Summarize for ${report['stockName']}");
                        },
                      ),
                      _buildIconButton(
                        Icons.sentiment_neutral,
                        "Sentiment",
                        Colors.greenAccent,
                        () {
                          print("Recommendation for ${report['stockName']}");
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Text('Recommendation: ',
                          style: TextStyle(color: Colors.white, fontSize: 16)),
                      SizedBox(width: 4),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getTagColor(report['recommendationTag']),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          report['recommendationTag'] ?? "",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
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
    );
  }

  Widget _buildIconButton(
      IconData icon, String text, Color color, VoidCallback onTap) {
    return Column(
      children: [
        IconButton(
          onPressed: onTap,
          icon: Icon(icon, color: color, size: 24),
        ),
        Text(
          text,
          style: TextStyle(color: Colors.white, fontSize: 12),
        ),
      ],
    );
  }

  Color _getTagColor(String? tag) {
    switch (tag) {
      case "Buy":
        return Colors.green.withOpacity(0.2);
      case "Sell":
        return Colors.red.withOpacity(0.2);
      case "Hold":
        return Colors.orange.withOpacity(0.2);
      default:
        return Colors.grey.withOpacity(0.2);
    }
  }

  Widget _buildLouvainGirvanNewmanTab() {
    return FutureBuilder<void>(
      future: GlobalVariable.fetchAndCacheLGNData(),
      builder: (context, snapshot) {
        // Show a loading indicator while fetching data
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        // Handle errors during fetching
        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Failed to fetch data. Please try again.",
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Louvain Girvan Newman Portfolio",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 10),

                // Portfolio Message
                Text(
                  GlobalVariable.message,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                SizedBox(height: 20),

                // Portfolio Metrics
                Text(
                  "Portfolio Metrics",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 10),
                _buildMetricRow(
                    "Expected Return", GlobalVariable.expectedReturn),
                _buildMetricRow("Sharpe Ratio", GlobalVariable.sharpeRatio),
                _buildMetricRow("Volatility", GlobalVariable.volatility),

                SizedBox(height: 20),

                // Sector Allocation
                Text(
                  "Sector Allocation",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 10),
                _buildSectorAllocation(GlobalVariable.message),
              ],
            ),
          ),
        );
      },
    );
  }

// Helper widget to display portfolio metrics
  Widget _buildMetricRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
          Text(
            value.toStringAsFixed(2),
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
        ],
      ),
    );
  }

// Helper widget to display sector allocation
  Widget _buildSectorAllocation(String message) {
    final sectorData = _parseSectorAllocation(message);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sectorData.map((sector) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Text(
            sector,
            style: TextStyle(color: Colors.white70),
          ),
        );
      }).toList(),
    );
  }

// Helper method to parse sector allocation from the message
  List<String> _parseSectorAllocation(String message) {
    final regex = RegExp(r"• (.+?): ([\d.]+%) \(Cum: ([\d.]+%)\)");
    final matches = regex.allMatches(message);

    return matches.map((match) {
      final sector = match.group(1) ?? "Unknown Sector";
      final percentage = match.group(2) ?? "0%";
      final cumulative = match.group(3) ?? "0%";
      return "$sector: $percentage (Cumulative: $cumulative)";
    }).toList();
  }

  void _openPdfViewer(BuildContext context, String pdfUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewerPage(pdfUrl: pdfUrl),
      ),
    );
  }
}

class PdfViewerPage extends StatefulWidget {
  final String pdfUrl;

  const PdfViewerPage({required this.pdfUrl});

  @override
  _PdfViewerPageState createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  String? localFilePath;

  @override
  void initState() {
    super.initState();
    _downloadPdf();
  }

  Future<void> _downloadPdf() async {
    try {
      final response = await http.get(Uri.parse(widget.pdfUrl));
      final bytes = response.bodyBytes;

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/temp.pdf');
      await file.writeAsBytes(bytes);

      setState(() {
        localFilePath = file.path;
      });
    } catch (e) {
      print("Error loading PDF: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF0D1B2A),
        title: Text("PDF Viewer", style: TextStyle(color: Colors.white)),
      ),
      body: localFilePath == null
          ? Center(child: CircularProgressIndicator())
          : PDFView(
              filePath: localFilePath!,
              enableSwipe: true,
              swipeHorizontal: false,
              autoSpacing: true,
              pageSnap: true,
              fitPolicy: FitPolicy.BOTH,
              onError: (error) {
                print(error);
              },
              onPageError: (page, error) {
                print('Error on page $page: $error');
              },
            ),
    );
  }
}
