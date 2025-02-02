import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GlobalVariable {
  static const url =
      "https://580b-2409-40c0-18-c343-7be2-2c64-9b57-a18f.ngrok-free.app";
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
        expectedReturn = jsonData["portfolio_metrics"]["expected_return"] ?? 0.0;
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
}
