import 'package:flutter/material.dart';

import 'colors.dart';

/// Единая тема приложения: белый фон экранов, синий AppBar.
ThemeData crgAppTheme() {
  return ThemeData(
    primarySwatch: Colors.blue,
    scaffoldBackgroundColor: whiteprColor,
    canvasColor: whiteprColor,
    dialogBackgroundColor: whiteprColor,
    useMaterial3: false,
    appBarTheme: const AppBarTheme(
      backgroundColor: blueaccentColor,
      foregroundColor: whiteprColor,
      elevation: 0,
      iconTheme: IconThemeData(color: whiteprColor),
      titleTextStyle: TextStyle(
        color: whiteprColor,
        fontSize: 20,
        fontWeight: FontWeight.w500,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: whiteprColor,
    ),
  );
}
