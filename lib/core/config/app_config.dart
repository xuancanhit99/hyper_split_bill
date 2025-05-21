// lib/core/config/app_config.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:injectable/injectable.dart';
import 'package:hyper_split_bill/core/constants/ai_service_types.dart';

@lazySingleton // Make sure to use @LazySingleton instead of camelCase
class AppConfig {
  final String supabaseUrl;
  final String supabaseAnonKey;
  // OCR API Configs
  final String geminiOcrBaseUrl;
  final String grokOcrBaseUrl;
  // Chat API Configs
  final String gigaChatBaseUrl; // Added GigaChat Base URL
  // API Paths
  final String geminiOcrPath;
  final String geminiChatPath;
  final String grokOcrPath;
  final String grokChatPath;
  final String gigaChatChatPath; // Added GigaChat Chat Path
  final String? googleApiKey; // Optional API Key from env
  final String? xaiApiKey; // Optional API Key from env
  final String? gigaChatApiKey; // Added GigaChat API Key
  final String grokChatModel; // Grok Chat Model Name
  final String grokOcrModel; // Grok OCR Model Name
  final String? gigaChatChatModel; // Added GigaChat Chat Model

  // Regular constructor (not private)
  AppConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.grokChatModel,
    required this.grokOcrModel,
    required this.geminiOcrBaseUrl,
    required this.grokOcrBaseUrl,
    required this.gigaChatBaseUrl, // Added GigaChat Base URL
    required this.geminiOcrPath,
    required this.geminiChatPath,
    required this.grokOcrPath,
    required this.grokChatPath,
    required this.gigaChatChatPath, // Added GigaChat Chat Path
    this.googleApiKey,
    this.xaiApiKey,
    this.gigaChatApiKey, // Added GigaChat API Key
    this.gigaChatChatModel, // Added GigaChat Chat Model
  });

  // Add a factory method for DI
  @factoryMethod
  static AppConfig fromEnv() {
    final url = dotenv.env['SUPABASE_URL'];
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'];
    final geminiUrl = dotenv.env['GEMINI_OCR_BASE_URL'];
    final grokUrl = dotenv.env['GROK_OCR_BASE_URL'];
    final gigaChatUrl =
        dotenv.env['GIGACHAT_BASE_URL']; // Read GigaChat Base URL
    final geminiOcrPath = dotenv.env['GEMINI_OCR_PATH'];
    final geminiChatPath = dotenv.env['GEMINI_CHAT_PATH'];
    final grokOcrPath = dotenv.env['GROK_OCR_PATH'];
    final grokChatPath = dotenv.env['GROK_CHAT_PATH'];
    final gigaChatChatPath =
        dotenv.env['GIGACHAT_CHAT_PATH']; // Read GigaChat Chat Path
    final grokOcrModel = dotenv.env['GROK_OCR_MODEL'];
    final grokChatModel = dotenv.env['GROK_CHAT_MODEL'];
    final gigaChatChatModel =
        dotenv.env['GIGACHAT_CHAT_MODEL']; // Read GigaChat Chat Model
    final googleKey = dotenv.env['GOOGLE_API_KEY']; // Optional
    final xaiKey = dotenv.env['XAI_API_KEY']; // Optional
    final gigaChatKey = dotenv.env['GIGACHAT_API_KEY']; // Read GigaChat API Key

    if (url == null || url.isEmpty) {
      throw Exception('SUPABASE_URL not found in .env file');
    }
    if (anonKey == null || anonKey.isEmpty) {
      throw Exception('SUPABASE_ANON_KEY not found in .env file');
    }
    if (geminiUrl == null || geminiUrl.isEmpty) {
      throw Exception('GEMINI_OCR_BASE_URL not found in .env file');
    }
    if (grokUrl == null || grokUrl.isEmpty) {
      throw Exception('GROK_OCR_BASE_URL not found in .env file');
    }
    // Add check for GigaChat Base URL
    if (gigaChatUrl == null || gigaChatUrl.isEmpty) {
      throw Exception('GIGACHAT_BASE_URL not found in .env file');
    }
    if (geminiOcrPath == null || geminiOcrPath.isEmpty) {
      throw Exception('GEMINI_OCR_PATH not found in .env file');
    }
    if (geminiChatPath == null || geminiChatPath.isEmpty) {
      throw Exception('GEMINI_CHAT_PATH not found in .env file');
    }
    if (grokOcrPath == null || grokOcrPath.isEmpty) {
      throw Exception('GROK_OCR_PATH not found in .env file');
    }
    if (grokChatPath == null || grokChatPath.isEmpty) {
      throw Exception('GROK_CHAT_PATH not found in .env file');
    }
    // Add check for GigaChat Chat Path
    if (gigaChatChatPath == null || gigaChatChatPath.isEmpty) {
      throw Exception('GIGACHAT_CHAT_PATH not found in .env file');
    }
    if (grokChatModel == null || grokChatModel.isEmpty) {
      throw Exception('GROK_CHAT_MODEL not found in .env file');
    }
    if (grokOcrModel == null || grokOcrModel.isEmpty) {
      throw Exception('GROK_OCR_MODEL not found in .env file');
    }
    // Add check for GigaChat Chat Model
    // Note: GigaChat Chat Model is not marked required in .env example,
    // but check is good practice if it becomes required.
    // For now, no check, allow null.

    // Add check for GigaChat API Key
    // Note: GigaChat API Key is not marked required in .env example,
    // but check is good practice if it becomes required.
    // For now, no check, allow null.

    return AppConfig(
      supabaseUrl: url,
      supabaseAnonKey: anonKey,
      geminiOcrBaseUrl: geminiUrl,
      grokOcrBaseUrl: grokUrl,
      gigaChatBaseUrl: gigaChatUrl, // Pass GigaChat Base URL
      geminiOcrPath: geminiOcrPath,
      geminiChatPath: geminiChatPath,
      grokOcrPath: grokOcrPath,
      grokChatPath: grokChatPath,
      gigaChatChatPath: gigaChatChatPath, // Pass GigaChat Chat Path
      grokOcrModel: grokOcrModel,
      grokChatModel: grokChatModel,
      gigaChatChatModel: gigaChatChatModel, // Pass GigaChat Chat Model
      googleApiKey: googleKey, // Can be null
      xaiApiKey: xaiKey, // Can be null
      gigaChatApiKey: gigaChatKey, // Can be null
    );
  }

  /// Gets the configuration for the selected OCR service.
  AiServiceConfig getOcrConfig(AiServiceType serviceType) {
    switch (serviceType) {
      case AiServiceType.gemini:
        return AiServiceConfig(
          baseUrl: geminiOcrBaseUrl,
          path: geminiOcrPath,
          apiKey: googleApiKey,
          model:
              null, // Model not explicitly needed for Gemini OCR in this setup
        );
      case AiServiceType.grok:
        return AiServiceConfig(
          baseUrl: grokOcrBaseUrl,
          path: grokOcrPath,
          apiKey: xaiApiKey,
          model: grokOcrModel,
        );
      default:
        // Fallback to default Grok OCR if an unsupported type is requested
        return AiServiceConfig(
          baseUrl: grokOcrBaseUrl,
          path: grokOcrPath,
          apiKey: xaiApiKey,
          model: grokOcrModel,
        );
    }
  }

  /// Gets the configuration for the selected Chat service.
  AiServiceConfig getChatConfig(AiServiceType serviceType) {
    switch (serviceType) {
      case AiServiceType.gemini:
        return AiServiceConfig(
          baseUrl: geminiOcrBaseUrl, // Assuming same base URL for Gemini Chat
          path: geminiChatPath,
          apiKey: googleApiKey,
          model:
              null, // Model not explicitly needed for Gemini Chat in this setup
        );
      case AiServiceType.grok:
        return AiServiceConfig(
          baseUrl: grokOcrBaseUrl, // Assuming same base URL for Grok Chat
          path: grokChatPath,
          apiKey: xaiApiKey,
          model: grokChatModel,
        );
      case AiServiceType.gigachat:
        return AiServiceConfig(
          baseUrl: gigaChatBaseUrl,
          path: gigaChatChatPath,
          apiKey: gigaChatApiKey,
          model: gigaChatChatModel,
        );
      default:
        // Fallback to default Grok Chat if an unsupported type is requested
        return AiServiceConfig(
          baseUrl: grokOcrBaseUrl,
          path: grokChatPath,
          apiKey: xaiApiKey,
          model: grokChatModel,
        );
    }
  }
}

/// Helper class to hold AI service configuration details.
class AiServiceConfig {
  final String baseUrl;
  final String path;
  final String? model;
  final String? apiKey;

  AiServiceConfig({
    required this.baseUrl,
    required this.path,
    this.model,
    this.apiKey,
  });
}
