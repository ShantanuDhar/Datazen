import 'dart:io';

import 'package:datazen/core/globalvariables.dart';
import 'package:datazen/pages/piechart.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

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
    _annualReportsFuture = GlobalVariable.initializeAnnualReportsData();
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

  Future<List<dynamic>>? _annualReportsFuture;

  // Helper method to open PDF viewer (implement your own logic here).
  // void _openPdfViewer(BuildContext context, String pdfUrl) {
  //   // Replace the print statement with your actual PDF viewer logic.
  //   print("Opening PDF: $pdfUrl");
  // }

  // Helper widget to build an icon button.
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

  // Helper method to choose a color for the recommendation tag.
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

  Widget _buildAnnualReportTab(BuildContext context) {
    Future<List<dynamic>> _initializeReports() {
      return GlobalVariable.initializeAnnualReportsData();
    }

    return FutureBuilder<List<dynamic>>(
      future: _initializeReports(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show a loading indicator while waiting for data
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          // Display an error message if something went wrong
          return Center(
            child: Text(
              "Error loading reports",
              style: TextStyle(color: Colors.white),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          // Display a message if no reports are available
          return Center(
            child: Text(
              "No annual reports available",
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        // When data is available, build the list of report cards
        List<dynamic> reports = snapshot.data!;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView.builder(
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              final analysis = report['analysis'] ?? {};
              final buySell = report['buy_sell_analysis'] ?? {};
              final recommendation = buySell['Auditor_Opinion'] ?? "N/A";
              final verification =
                  (recommendation == "Buy" || recommendation == "Hold")
                      ? "Verified"
                      : "Hoax";
              String pdfUrl = report['pdf_url'] ?? "";
              if (!pdfUrl.toLowerCase().startsWith("http")) {
                pdfUrl = "${GlobalVariable.url2}/$pdfUrl";
              }

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
                              "Annual Report #${index + 1}",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: verification == "Verified"
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              verification,
                              style: TextStyle(
                                color: verification == "Verified"
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        ],
                      ),
                      SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          _openPdfViewer(context, pdfUrl);
                        },
                        child: Container(
                          height: 150,
                          width: double.infinity,
                          color: Colors.white,
                          child: Center(
                            child: Text(
                              "Tap to view PDF",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      _buildAnalysisSection(
                          "Auditor Opinion", analysis['Auditor_Opinion']),
                      //_buildAnalysisSection("MD&A", analysis['MD&A']),
                      _buildAnalysisSection(
                          "Risk Factors", analysis['Risk_Factors']),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'Recommendation: ',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          SizedBox(width: 4),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getTagColor(recommendation),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              recommendation,
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
      },
    );
  }

  Widget _buildAnalysisSection(String title, Map<String, dynamic>? analysis) {
    if (analysis == null) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 4),
        Text(
          "Negative: ${analysis['insights']['negative']?.join(", ") ?? 'None'}",
          style: TextStyle(color: Colors.red, fontSize: 12),
        ),
        Text(
          "Neutral: ${analysis['insights']['neutral']?.join(", ") ?? 'None'}",
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
        Text(
          "Positive: ${analysis['insights']['positive']?.join(", ") ?? 'None'}",
          style: TextStyle(color: Colors.green, fontSize: 12),
        ),
      ],
    );
  }

// void _openPdfViewer(BuildContext context, String pdfUrl) {
//   // Implement your logic to open PDF viewer
//   print("Opening PDF: $pdfUrl");
// }

  Widget _buildLouvainGirvanNewmanTab() {
    return FutureBuilder<void>(
      future: GlobalVariable.initializeLGNData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(
            child: Text(
              "Failed to fetch data. Please try again.",
              style: TextStyle(color: Colors.red, fontSize: 18),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                const Text(
                  "Louvain Girvan Newman Portfolio",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 4.0,
                        color: Colors.black54,
                        offset: Offset(2.0, 2.0),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Portfolio Message (displayed in white70)
                Text(
                  GlobalVariable.message,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 24),

                // Portfolio Metrics Section
                const Text(
                  "Portfolio Metrics",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                _buildMetricsBarChart(),
                const SizedBox(height: 24),

                // Sector Allocation Chart Section
                const Text(
                  "Sector Allocation (Chart)",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                InteractiveSectorPieChart(),
                const SizedBox(height: 24),

                // Generate Sector Allocation Table from parsed message.
                const Text(
                  "Sector Allocation (Table)",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                _buildSectorAllocationTable(),
              ],
            ),
          ),
        );
      },
    );
  }

  // Bar Chart for Portfolio Metrics using dynamic global variables.
  Widget _buildMetricsBarChart() {
    final metrics = [
      {'label': 'Return', 'value': GlobalVariable.expectedReturn},
      {'label': 'Sharpe', 'value': GlobalVariable.sharpeRatio},
      {'label': 'Volatility', 'value': GlobalVariable.volatility},
    ];

    return Container(
      height: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            offset: Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: true, drawVerticalLine: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < metrics.length) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        metrics[index]['label'].toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }
                  return Container();
                },
              ),
            ),
          ),
          barGroups: metrics.asMap().entries.map(
            (entry) {
              return BarChartGroupData(
                x: entry.key,
                barRods: [
                  BarChartRodData(
                    toY: double.parse(entry.value['value'].toString()),
                    color: Colors.blueAccent,
                    width: 20,
                    borderRadius: BorderRadius.circular(6),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: 100, // example max value for background bars
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              );
            },
          ).toList(),
        ),
      ),
    );
  }

  // Build a DataTable for Key Holdings by parsing the message.
  Widget _buildKeyHoldingsTable() {
    // Parse key holdings from the message
    final keyHoldings = _parseKeyHoldings(GlobalVariable.message);

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            offset: Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(Colors.grey[800]),
        columnSpacing: 20,
        columns: const [
          DataColumn(
            label: Text(
              'Holding',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
          DataColumn(
            label: Text(
              'Percentage',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ],
        rows: keyHoldings.map((entry) {
          return DataRow(
            cells: [
              DataCell(Text(
                entry['holding']!,
                style: const TextStyle(color: Colors.white),
              )),
              DataCell(Text(
                entry['percentage']!,
                style: const TextStyle(color: Colors.white),
              )),
            ],
          );
        }).toList(),
      ),
    );
  }

  // Build a DataTable for Sector Allocation by parsing the message.
  Widget _buildSectorAllocationTable() {
    // Parse sector allocation from the message.
    final sectorAllocations =
        _parseSectorAllocationWithCum(GlobalVariable.message);

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            offset: Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(Colors.grey[800]),
        columnSpacing: 20,
        columns: const [
          DataColumn(
            label: Text(
              'Sector',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
          DataColumn(
            label: Text(
              'Percentage',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
          DataColumn(
            label: Text(
              'Cumulative',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ],
        rows: sectorAllocations.map((entry) {
          return DataRow(
            cells: [
              DataCell(Text(
                entry['sector']!,
                style: const TextStyle(color: Colors.white),
              )),
              DataCell(Text(
                entry['percentage']!,
                style: const TextStyle(color: Colors.white),
              )),
              DataCell(Text(
                entry['cumulative']!,
                style: const TextStyle(color: Colors.white),
              )),
            ],
          );
        }).toList(),
      ),
    );
  }

  // Helper: Parse key holdings from the message.
  // Expected Key Holdings section format:
  // "💼 Key Holdings (>1%):\n• TRENT: 15.0%\n• BHARTIARTL: 15.0%\n..."
  List<Map<String, String>> _parseKeyHoldings(String message) {
    List<Map<String, String>> holdings = [];
    // Split by lines and locate the key holdings section.
    final lines = message.split('\n');
    bool inHoldingsSection = false;
    for (var line in lines) {
      if (line.contains("Key Holdings")) {
        inHoldingsSection = true;
        continue;
      }
      if (inHoldingsSection) {
        // End the section when a blank line or a new section is encountered.
        if (line.startsWith("🏢") || line.trim().isEmpty) break;
        // Expecting lines starting with "• "
        if (line.startsWith("• ")) {
          // Remove the bullet (•) and trim
          line = line.substring(2).trim();
          // Split on colon to separate holding and percentage.
          final parts = line.split(":");
          if (parts.length >= 2) {
            holdings.add({
              'holding': parts[0].trim(),
              'percentage': parts[1].trim(),
            });
          }
        }
      }
    }
    return holdings;
  }

  // Helper: Parse sector allocation for the pie chart.
  // Uses regex to capture lines like: "• Pharma: 22.4% (Cum: 22.4%)"
  List<String> _parseSectorAllocation(String message) {
    final regex = RegExp(r"• (.+?): ([\d.]+%) \(Cum: [\d.]+%\)");
    final matches = regex.allMatches(message);
    return matches.map((match) {
      final sector = match.group(1) ?? "Unknown Sector";
      final percentage = match.group(2) ?? "0%";
      return "$sector: $percentage";
    }).toList();
  }

  // Helper: Parse sector allocation for the table including cumulative values.
  // Returns a list of maps with keys: sector, percentage, cumulative.
  List<Map<String, String>> _parseSectorAllocationWithCum(String message) {
    List<Map<String, String>> sectors = [];
    // Split by lines and locate the sector allocation section.
    final lines = message.split('\n');
    bool inSectorSection = false;
    for (var line in lines) {
      if (line.contains("Sector Allocation")) {
        inSectorSection = true;
        continue;
      }
      if (inSectorSection) {
        // End section when it reaches a blank line or a new section.
        if (line.trim().isEmpty || line.contains("Strong Performance")) break;
        if (line.startsWith("• ")) {
          line = line.substring(2).trim();
          // Regex to capture "Sector: xx% (Cum: yy%)"
          final regex = RegExp(r"(.+?): ([\d.]+%) \(Cum: ([\d.]+%)\)");
          final match = regex.firstMatch(line);
          if (match != null) {
            sectors.add({
              'sector': match.group(1) ?? "",
              'percentage': match.group(2) ?? "",
              'cumulative': match.group(3) ?? "",
            });
          }
        }
      }
    }
    return sectors;
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
  late final WebViewController _webViewController;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    final pdfUrl = Uri.encodeFull(
        widget.pdfUrl); // Encode URL to handle special characters.
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) => print("Page started loading: $url"),
          onPageFinished: (url) => print("Page finished loading: $url"),
          onWebResourceError: (error) => print("Error loading page: $error"),
        ),
      )
      ..loadRequest(Uri.parse("https://docs.google.com/viewer?url=$pdfUrl"));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        title: const Text("PDF Viewer", style: TextStyle(color: Colors.white)),
      ),
      body: WebViewWidget(
        controller: _webViewController,
        gestureRecognizers: {},
      ),
    );
  }
}
