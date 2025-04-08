// lib/core/config/app_config.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:injectable/injectable.dart';

@lazySingleton // Make sure to use @LazySingleton instead of camelCase
class AppConfig {
  final String supabaseUrl;
  final String supabaseAnonKey;
  // OCR API Configs
  final String geminiOcrBaseUrl;
  final String grokOcrBaseUrl;
  final String? googleApiKey; // Optional API Key from env
  final String? xaiApiKey; // Optional API Key from env

  // Regular constructor (not private)
  AppConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.geminiOcrBaseUrl,
    required this.grokOcrBaseUrl,
    this.googleApiKey,
    this.xaiApiKey,
  });

  // Add a factory method for DI
  @factoryMethod
  static AppConfig fromEnv() {
    final url = dotenv.env['SUPABASE_URL'];
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'];
    final geminiUrl = dotenv.env['GEMINI_OCR_BASE_URL'];
    final grokUrl = dotenv.env['GROK_OCR_BASE_URL'];
    final googleKey = dotenv.env['GOOGLE_API_KEY']; // Optional
    final xaiKey = dotenv.env['XAI_API_KEY']; // Optional

    if (url == null || url.isEmpty) {
      throw Exception('SUPABASE_URL not found in .env file');
    }
    if (anonKey == null || anonKey.isEmpty) {
      throw Exception('SUPABASE_ANON_KEY not found in .env file');
    }
    if (geminiUrl == null || geminiUrl.isEmpty) {
      // Defaulting or throwing based on requirement
      // For now, let's throw if not found, assuming it's required
      throw Exception('GEMINI_OCR_BASE_URL not found in .env file');
    }
    if (grokUrl == null || grokUrl.isEmpty) {
      // Defaulting or throwing based on requirement
      throw Exception('GROK_OCR_BASE_URL not found in .env file');
    }

    return AppConfig(
      supabaseUrl: url,
      supabaseAnonKey: anonKey,
      geminiOcrBaseUrl: geminiUrl,
      grokOcrBaseUrl: grokUrl,
      googleApiKey: googleKey, // Can be null
      xaiApiKey: xaiKey, // Can be null
    );
  }
}
