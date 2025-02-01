import 'package:datazen/core/theme/app_pallete.dart';
import 'package:flutter/material.dart';


class AppTheme {
  static final appTheme = ThemeData.dark().copyWith(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      useMaterial3: true,
      // Blue : #3A5A81
      primaryColor: Color.fromRGBO(58, 90, 129, 1),
      // Red : #D31336
      shadowColor: Color.fromRGBO(211, 19, 54, 1),
      // Black : #252131
      canvasColor: Color.fromRGBO(37, 33, 49, 1),
      //White
      focusColor: Colors.white);

  static final inputDecoration = InputDecoration(
    contentPadding: const EdgeInsets.all(15),
    filled: true,
    fillColor: Colors.transparent, // Match ProfilePage text fields
    hintStyle: TextStyle(color: Colors.grey), // Grey hint for consistency
    disabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Pallete.inactiveColor, width: 1.5),
      borderRadius: BorderRadius.circular(30), // Rounded to match button style
    ),
    focusedBorder: OutlineInputBorder(
      borderSide:
          BorderSide(color: Colors.white, width: 1.5), // White border on focus
      borderRadius: BorderRadius.circular(30),
    ),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(
          color: Pallete.primaryColor, width: 1.5), // Primary color border
      borderRadius: BorderRadius.circular(30),
    ),
  );
}
