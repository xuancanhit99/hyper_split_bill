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

  late final String _ocrBaseUrl;
  late final String? _apiKey;

  OcrDataSourceImpl({required this.httpClient, required this.appConfig}) {
    // Sử dụng Grok OCR service
    _ocrBaseUrl = appConfig.grokOcrBaseUrl;
    _apiKey = appConfig.xaiApiKey;
  }

  @override
  Future<String> extractTextFromImage({
    required File imageFile,
    String? prompt,
    // String? modelName, // Optional model override
  }) async {
    final endpoint = '/ocr/extract-text';
    final queryParameters = <String, String>{};
    if (prompt != null && prompt.isNotEmpty) {
      queryParameters['prompt'] = prompt;
    }
    // Luôn gửi model_name mặc định hoặc model được chỉ định (nếu có)
    queryParameters['model_name'] =
        'grok-2-vision-1212'; // Sử dụng model mặc định

    final uri = Uri.parse('$_ocrBaseUrl$endpoint').replace(
      queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
    );
    print("Sending OCR request to URI: $uri"); // Log the final URI

    try {
      final request = http.MultipartRequest('POST', uri);

      // Thêm XAI API Key cho Grok service nếu có
      if (_apiKey != null && _apiKey!.isNotEmpty) {
        request.headers['X-API-Key'] = _apiKey!;
      }

      // Add the file - Grok chỉ chấp nhận image/jpeg và image/png
      final String? mimeType = lookupMimeType(imageFile.path);
      print("Detected MIME type for ${imageFile.path}: $mimeType");

      if (mimeType != 'image/jpeg' && mimeType != 'image/png') {
        throw ServerException(
            'Grok OCR chỉ hỗ trợ định dạng JPEG và PNG. Định dạng hiện tại: $mimeType');
      }

      request.files.add(await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        contentType: MediaType.parse(mimeType!),
      ));

      // Không cần thêm prompt và model_name vào fields nữa vì đã gửi qua query params
      final streamedResponse = await httpClient.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // Read raw bytes and decode explicitly using UTF-8
        print(
            "OCR Response Status 200. Body Bytes Length: ${response.bodyBytes.length}");
        // print("Raw Body Bytes (first 100): ${response.bodyBytes.take(100).toList()}"); // Optional: Log raw bytes for deep debug
        final utf8DecodedBody = utf8.decode(response.bodyBytes,
            allowMalformed: true); // Allow malformed to see potential issues
        print("UTF-8 Decoded Body:\n>>>\n$utf8DecodedBody\n<<<");

        // Don't assume the structure here. Return the full decoded body string.
        // The UseCase will be responsible for trying to parse it as the expected JSON.
        print("OCRDataSourceImpl returning full decoded body to UseCase.");
        return utf8DecodedBody;
      } else {
        // Attempt to parse error detail
        String detail = 'HTTP Error ${response.statusCode}';
        String errorBodyUtf8 = ''; // Declare ONCE outside try block
        try {
          // Decode error body using UTF-8 for logging/details
          errorBodyUtf8 = // Assign value inside try block
              utf8.decode(response.bodyBytes, allowMalformed: true);
          print("OCR Error Response Body (UTF-8 Decoded): $errorBodyUtf8");

          // Try to parse the decoded error body as JSON
          try {
            final errorBodyJson =
                json.decode(errorBodyUtf8) as Map<String, dynamic>;
            // If 'detail' key exists in JSON, use its value
            if (errorBodyJson.containsKey('detail')) {
              detail = errorBodyJson['detail'].toString();
            } else {
              // If 'detail' key is missing, use the full decoded string as detail
              detail = errorBodyUtf8;
            }
          } catch (jsonError) {
            // If parsing the error body as JSON fails, use the full decoded string as detail
            print(
                "Failed to parse error body as JSON: $jsonError. Using raw decoded body as detail.");
            detail = errorBodyUtf8;
          }
        } catch (decodeError) {
          // If even decoding the error body fails, keep the default HTTP error message
          print(
              "Failed to decode error body: $decodeError. Using default detail: $detail");
          // errorBodyUtf8 will be empty here, so detail remains the default HTTP error
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
