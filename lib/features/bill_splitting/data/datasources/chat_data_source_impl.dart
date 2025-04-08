import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:hyper_split_bill/core/config/app_config.dart';
import 'package:hyper_split_bill/core/error/exceptions.dart';
import 'package:hyper_split_bill/features/bill_splitting/data/datasources/chat_data_source.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: ChatDataSource)
class ChatDataSourceImpl implements ChatDataSource {
  final http.Client httpClient;
  final AppConfig appConfig;

  // TODO: Decide which Chat service to use (Gemini or Grok) or make it configurable
  late final String _chatBaseUrl;
  late final String? _apiKey; // Optional API Key from env

  ChatDataSourceImpl({required this.httpClient, required this.appConfig}) {
    // TODO: Get the correct base URL and API key from AppConfig
    // Example: _chatBaseUrl = appConfig.geminiChatBaseUrl; // Assuming geminiChatBaseUrl exists
    // Example: _apiKey = appConfig.googleApiKey;
    _chatBaseUrl = appConfig
        .geminiOcrBaseUrl; // Reuse OCR base URL for now if chat is on same service
    _apiKey = appConfig.googleApiKey;
  }

  @override
  Future<String> sendMessage({
    required String message,
    List<Map<String, String>>? history,
    String? modelName,
  }) async {
    final endpoint = '/chat/'; // As per API doc
    final uri = Uri.parse('$_chatBaseUrl$endpoint');

    final headers = {
      'Content-Type': 'application/json',
      // Add API key header if provided via config and not empty
      if (_apiKey != null && _apiKey!.isNotEmpty) 'X-API-Key': _apiKey!,
    };

    final body = json.encode({
      'message': message,
      if (history != null) 'history': history,
      if (modelName != null) 'model_name': modelName,
    });

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
          // Try decoding error body as UTF-8 as well
          final errorBody = json.decode(responseBody)
              as Map<String, dynamic>; // Use responseBody here too
          if (errorBody.containsKey('detail')) {
            detail = errorBody['detail'].toString();
          }
        } catch (_) {
          print(
              "Chat Error Response Body (non-JSON or parse failed): $responseBody");
          /* Ignore parsing error */
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
