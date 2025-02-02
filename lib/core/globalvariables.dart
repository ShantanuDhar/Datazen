import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GlobalVariable {
  static const url =
      "https://cad2-2409-40c0-102c-56ac-95f9-ddf0-b434-441b.ngrok-free.app";
  static String url2 = "https://f642-14-142-143-98.ngrok-free.app";
  static String message = "";
  static double expectedReturn = 0.0;
  static double sharpeRatio = 0.0;
  static double volatility = 0.0;

  static Future<void> loadCachedLGNData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    message = prefs.getString("lgn_message") ?? "Fetching latest data...";
    expectedReturn = prefs.getDouble("lgn_expected_return") ?? 0.0;
    sharpeRatio = prefs.getDouble("lgn_sharpe_ratio") ?? 0.0;
    volatility = prefs.getDouble("lgn_volatility") ?? 0.0;
  }

  static Future<void> fetchAndCacheLGNData() async {
    try {
      final response = await http.get(Uri.parse('$url/lgn'));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        message = jsonData["message"] ?? "No message available";
        expectedReturn =
            jsonData["portfolio_metrics"]["expected_return"] ?? 0.0;
        sharpeRatio = jsonData["portfolio_metrics"]["sharpe_ratio"] ?? 0.0;
        volatility = jsonData["portfolio_metrics"]["volatility"] ?? 0.0;

        // Cache data
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString("lgn_message", message);
        prefs.setDouble("lgn_expected_return", expectedReturn);
        prefs.setDouble("lgn_sharpe_ratio", sharpeRatio);
        prefs.setDouble("lgn_volatility", volatility);
      }
    } catch (e) {
      print("Error fetching LGN data: $e");
    }
  }

  static Future<void> initializeLGNData() async {
    await loadCachedLGNData(); // Load cached data instantly
    fetchAndCacheLGNData(); // Fetch new data in background
  }

  static String annualReportsCacheKey = "cached_annual_reports";

  // Load cached annual report data from SharedPreferences
  static Future<List<dynamic>> loadCachedAnnualReportsData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? cachedData = prefs.getString(annualReportsCacheKey);
    if (cachedData != null) {
      try {
        // Assume the cached data is a valid JSON string representing a list of reports
        List<dynamic> reports = json.decode(cachedData);
        return reports;
      } catch (e) {
        print("Error decoding cached annual reports: $e");
      }
    }
    // Return an empty list if no valid cache exists
    return [];
  }

  // Fetch fresh annual report data from the endpoint and cache it
  static Future<List<dynamic>> fetchAndCacheAnnualReportsData() async {
    try {
      final response = await http.get(Uri.parse("$url2/process"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Assume the response JSON contains a "results" array.
        List<dynamic> results = data["results"] ?? [];
        // Cache the fetched data as a JSON string
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString(annualReportsCacheKey, json.encode(results));
        print(results);
        return results;
      }
    } catch (e) {
      print("Error fetching annual reports: $e");
    }
    return [];
  }

  // Initialize the annual report data by first loading cached data, then updating in background.
  static Future<List<dynamic>> initializeAnnualReportsData() async {
    // Load cached data first
    List<dynamic> cachedReports = await loadCachedAnnualReportsData();
    // Fetch new data in the background
    fetchAndCacheAnnualReportsData();
    // Return the cached data immediately
    return cachedReports;
  }
}
