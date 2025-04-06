// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // Prevent instantiation
  AppTheme._();

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true, // Enable Material 3 features
    brightness: Brightness.light,
    primarySwatch: Colors.deepPurple, // Base color swatch
    primaryColor: Colors.deepPurple[600], // More specific primary color
    scaffoldBackgroundColor: Colors.grey[100],
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.deepPurple[600],
      foregroundColor: Colors.white, // Title and icon color
      elevation: 4.0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple[500],
        foregroundColor: Colors.white, // Text color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.grey[400]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.deepPurple[600]!, width: 2.0),
      ),
      labelStyle: TextStyle(color: Colors.grey[700]),
    ),
    // Add other theme properties as needed (textTheme, cardTheme, etc.)
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      brightness: Brightness.light,
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primarySwatch: Colors.deepPurple,
    primaryColor: Colors.deepPurple[300],
    scaffoldBackgroundColor: Colors.grey[900],
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.grey[850],
      foregroundColor: Colors.deepPurple[200],
      elevation: 4.0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple[400],
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.grey[700]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.deepPurple[300]!, width: 2.0),
      ),
      labelStyle: TextStyle(color: Colors.grey[400]),
      hintStyle: TextStyle(color: Colors.grey[500]),
      // Ensure prefix/suffix icon colors contrast well
      iconColor: Colors.grey[400],
      prefixIconColor: Colors.grey[400],
      suffixIconColor: Colors.grey[400],

    ),
    // Add other theme properties
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      brightness: Brightness.dark,
      // Adjust specific dark theme colors if needed
      background: Colors.grey[900]!,
      surface: Colors.grey[850]!,
      onPrimary: Colors.black,
      onBackground: Colors.white,
      onSurface: Colors.white,
    ),
  );
}