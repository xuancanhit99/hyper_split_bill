import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:hyper_split_bill/core/config/app_config.dart';
import 'package:hyper_split_bill/core/config/settings_service.dart'; // Import SettingsService
import 'package:hyper_split_bill/core/constants/ai_service_types.dart'; // Import AiServiceType
import 'package:hyper_split_bill/core/error/exceptions.dart';
import 'package:hyper_split_bill/features/bill_splitting/data/datasources/chat_data_source.dart';

@LazySingleton(as: ChatDataSource)
class ChatDataSourceImpl implements ChatDataSource {
  final http.Client httpClient;
  final AppConfig appConfig;
  final SettingsService settingsService; // Inject SettingsService

  ChatDataSourceImpl({
    required this.httpClient,
    required this.appConfig,
    required this.settingsService, // Add SettingsService to constructor
  });

  @override
  Future<String> sendMessage({
    required String message,
    List<Map<String, String>>? history,
    String? modelName,
  }) async {
    // Get the selected Chat service from settings
    final selectedChatService = settingsService.selectedChatService;

    // Get the configuration for the selected service
    final chatConfig = appConfig.getChatConfig(selectedChatService);

    final endpoint = chatConfig.path;
    final baseUrl = chatConfig.baseUrl;
    final apiKey = chatConfig.apiKey;
    final model = chatConfig.model;

    final uri = Uri.parse('$baseUrl$endpoint');

    final headers = {
      'Content-Type': 'application/json',
    };

    // Add API Key header if available for the service.
    if (apiKey != null && apiKey.isNotEmpty) {
      String headerName = 'X-API-Key'; // Default header name
      // Based on AppConfig and .env, Grok and GigaChat likely use X-API-Key.
      // If Gemini uses a different header ('x-goog-api-key') or query param,
      // this logic needs to be more sophisticated. For now, stick with X-API-Key
      // as it's used by Grok and potentially GigaChat on the backend.
      headers[headerName] = apiKey;
    }

    final body = json.encode({
      'message': message,
      if (history != null) 'history': history,
      // Use the model from config if available, otherwise fallback to the provided modelName
      'model_name': model ?? modelName, // Use config model > provided model
    });

    print(
        "Sending Chat request to URI: $uri using $selectedChatService"); // Log the final URI and service

    try {
      final response = await httpClient.post(
        uri,
        headers: headers,
        body: body,
      );

      // Decode response body explicitly using UTF-8
      final responseBody = utf8.decode(response.bodyBytes);

      if (response.statusCode == 200) {
        final decodedResponse =
            json.decode(responseBody) as Map<String, dynamic>;
        if (decodedResponse.containsKey('response_text')) {
          return decodedResponse['response_text'] as String;
        } else {
          throw const ServerException(
              'Chat API response missing "response_text" field.');
        }
      } else {
        String detail = 'HTTP Error ${response.statusCode}';
        try {
          final errorBody = json.decode(responseBody) as Map<String, dynamic>;
          if (errorBody.containsKey('detail')) {
            detail = errorBody['detail'].toString();
          }
        } catch (_) {
          print(
              "Chat Error Response Body (non-JSON or parse failed): $responseBody");
        }
        throw ServerException('Chat request failed: $detail');
      }
    } on SocketException {
      throw const NetworkException(
          'Network error: Could not connect to Chat service.');
    } on http.ClientException catch (e) {
      throw NetworkException('Network error during Chat request: ${e.message}');
    } catch (e) {
      throw ServerException(
          'An unexpected error occurred during Chat request: ${e.runtimeType}');
    }
  }
}
