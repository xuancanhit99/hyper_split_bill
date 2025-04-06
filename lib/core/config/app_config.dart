// lib/core/config/app_config.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:injectable/injectable.dart';

@lazySingleton // Register this class with GetIt
class AppConfig {
  // Make them final fields initialized in the constructor or via a load method
  final String supabaseUrl;
  final String supabaseAnonKey;
  // Add other config values here later
  // final String ocrApiBaseUrl;

  // Private constructor ensures loading happens via factory or static method
  AppConfig._({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    // required this.ocrApiBaseUrl,
  });

  // Factory constructor or static method to load from dotenv
  // This ensures dotenv is loaded *before* AppConfig is created.
  // Call this method *after* dotenv.load() in main.dart
  factory AppConfig.fromEnv() {
    final url = dotenv.env['SUPABASE_URL'];
    final key = dotenv.env['SUPABASE_ANON_KEY'];
    // final ocrUrl = dotenv.env['OCR_API_URL']; // Example for later

    if (url == null || url.isEmpty) {
      throw Exception('SUPABASE_URL not found in .env file');
    }
    if (key == null || key.isEmpty) {
      throw Exception('SUPABASE_ANON_KEY not found in .env file');
    }
    // if (ocrUrl == null || ocrUrl.isEmpty) {
    //   throw Exception('OCR_API_URL not found in .env file');
    // }

    return AppConfig._(
      supabaseUrl: url,
      supabaseAnonKey: key,
      // ocrApiBaseUrl: ocrUrl,
    );
  }
}