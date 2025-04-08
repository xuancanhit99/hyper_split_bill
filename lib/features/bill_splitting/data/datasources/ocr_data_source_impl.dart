import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart'; // Import mime package
import 'package:http_parser/http_parser.dart'; // Import for MediaType
import 'package:hyper_split_bill/core/config/app_config.dart'; // To get API base URL
import 'package:hyper_split_bill/core/error/exceptions.dart';
import 'package:hyper_split_bill/features/bill_splitting/data/datasources/ocr_data_source.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: OcrDataSource) // Register with GetIt
class OcrDataSourceImpl implements OcrDataSource {
  final http.Client httpClient;
  final AppConfig appConfig; // Inject AppConfig to get base URLs

  // TODO: Decide which OCR service to use (Gemini or Grok) or make it configurable
  // For now, let's assume Gemini is the default.
  late final String _ocrBaseUrl;
  // late final String _apiKey; // Optional: Get API key from AppConfig if needed per request

  OcrDataSourceImpl({required this.httpClient, required this.appConfig}) {
    // TODO: Get the correct base URL from AppConfig based on selection/config
    // Example: _ocrBaseUrl = appConfig.geminiOcrBaseUrl;
    // Example: _apiKey = appConfig.googleApiKey; // If needed
    _ocrBaseUrl = appConfig
        .geminiOcrBaseUrl; // Assuming geminiOcrBaseUrl exists in AppConfig
  }

  @override
  Future<String> extractTextFromImage({
    required File imageFile,
    String? prompt,
    // String? modelName, // Optional model override
  }) async {
    final endpoint = '/ocr/extract-text'; // As per API doc
    final uri = Uri.parse('$_ocrBaseUrl$endpoint');

    try {
      final request = http.MultipartRequest('POST', uri);

      // Add headers if API key needs to be sent per request
      // if (_apiKey.isNotEmpty) {
      //   request.headers['X-API-Key'] = _apiKey;
      // }

      // Add the file
      request.files.add(await http.MultipartFile.fromPath(
        'file', // Field name from API doc
        imageFile.path,
        // Determine content type using mime package
        contentType: MediaType.parse(
            lookupMimeType(imageFile.path) ?? 'application/octet-stream'),
      ));

      // Add optional fields
      if (prompt != null && prompt.isNotEmpty) {
        request.fields['prompt'] = prompt;
      }
      // if (modelName != null && modelName.isNotEmpty) {
      //   request.fields['model_name'] = modelName;
      // }

      final streamedResponse = await httpClient.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final decodedResponse =
            json.decode(response.body) as Map<String, dynamic>;
        if (decodedResponse.containsKey('extracted_text')) {
          return decodedResponse['extracted_text'] as String;
        } else {
          throw const ServerException(
              'OCR API response missing "extracted_text" field.');
        }
      } else {
        // Attempt to parse error detail
        String detail = 'HTTP Error ${response.statusCode}';
        try {
          final errorBody = json.decode(response.body) as Map<String, dynamic>;
          if (errorBody.containsKey('detail')) {
            detail = errorBody['detail'].toString();
          }
        } catch (_) {
          // Ignore parsing error, use default detail
          print(
              "OCR Error Response Body: ${response.body}"); // Log raw error body
        }
        // Consider mapping status codes to more specific exceptions if needed
        throw ServerException('OCR request failed: $detail');
      }
    } on SocketException catch (e, s) {
      print("OCR SocketException: $e\nStackTrace: $s");
      throw NetworkException(
          'Network error: Could not connect to OCR service.');
    } on http.ClientException catch (e, s) {
      print("OCR ClientException: $e\nStackTrace: $s");
      throw NetworkException('Network error during OCR request: ${e.message}');
    } catch (e, s) {
      print("OCR Unexpected Error: $e\nStackTrace: $s");
      throw ServerException(
          'An unexpected error occurred during OCR processing: ${e.runtimeType}');
    }
  }
}
