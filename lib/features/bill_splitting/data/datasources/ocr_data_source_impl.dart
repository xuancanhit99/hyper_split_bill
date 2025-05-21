import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart'; // Import mime package
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart'; // Import mime package
import 'package:http_parser/http_parser.dart'; // Import for MediaType
import 'package:injectable/injectable.dart';
import 'package:hyper_split_bill/core/config/app_config.dart'; // To get API base URL
import 'package:hyper_split_bill/core/config/settings_service.dart'; // Import SettingsService
import 'package:hyper_split_bill/core/constants/ai_service_types.dart'; // Import AiServiceType
import 'package:hyper_split_bill/core/error/exceptions.dart';
import 'package:hyper_split_bill/features/bill_splitting/data/datasources/ocr_data_source.dart';

@LazySingleton(as: OcrDataSource) // Register with GetIt
class OcrDataSourceImpl implements OcrDataSource {
  final http.Client httpClient;
  final AppConfig appConfig; // Inject AppConfig
  final SettingsService settingsService; // Inject SettingsService

  OcrDataSourceImpl({
    required this.httpClient,
    required this.appConfig,
    required this.settingsService, // Add SettingsService to constructor
  });

  @override
  Future<String> extractTextFromImage({
    required File imageFile,
    String? prompt,
  }) async {
    // Get the selected OCR service from settings
    final selectedOcrService = settingsService.selectedOcrService;

    // Get the configuration for the selected service
    final ocrConfig = appConfig.getOcrConfig(selectedOcrService);

    final endpoint = ocrConfig.path;
    final baseUrl = ocrConfig.baseUrl;
    final apiKey = ocrConfig.apiKey;
    final model = ocrConfig.model;

    final queryParameters = <String, String>{};
    if (prompt != null && prompt.isNotEmpty) {
      queryParameters['prompt'] = prompt;
    }
    // Add model if available for the service
    if (model != null && model.isNotEmpty) {
      queryParameters['model_name'] = model;
    }

    final uri = Uri.parse('$baseUrl$endpoint').replace(
      queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
    );
    print(
        "Sending OCR request to URI: $uri using $selectedOcrService"); // Log the final URI and service

    try {
      final request = http.MultipartRequest('POST', uri);

      // Add API Key if available for the service
      if (apiKey != null && apiKey.isNotEmpty) {
        // Determine header name based on service type if needed,
        // but for now assume a common header or check based on service.
        // Based on AppConfig structure, googleApiKey and xaiApiKey are used.
        // We'll need to handle the correct header name here.
        // Let's assume X-API-Key for now and refine if needed.
        String headerName = 'X-API-Key'; // Default header name
        if (selectedOcrService == AiServiceType.gemini) {
          // Gemini often uses 'x-goog-api-key' or passed in URL query
          // Need to confirm the header name for Gemini if not query param.
          // Assuming X-API-Key for now based on Grok example.
          // If Gemini requires different handling (e.g., query param),
          // this part needs adjustment.
        }
        // Using X-API-Key for both Grok and potentially others
        request.headers[headerName] = apiKey;
      }

      // Add the file
      final String? mimeType = lookupMimeType(imageFile.path);
      print("Detected MIME type for ${imageFile.path}: $mimeType");

      // Note: Mime type restriction might vary by service.
      // Currently hardcoded for Grok. Need to make this dynamic if needed.
      // For simplicity, let's keep the current restriction for now.
      if (mimeType != 'image/jpeg' && mimeType != 'image/png') {
        throw ServerException(
            'Chỉ hỗ trợ định dạng JPEG và PNG cho OCR. Định dạng hiện tại: $mimeType');
      }

      request.files.add(await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        contentType: MediaType.parse(mimeType!),
      ));

      final streamedResponse = await httpClient.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        print(
            "OCR Response Status 200. Body Bytes Length: ${response.bodyBytes.length}");
        final utf8DecodedBody =
            utf8.decode(response.bodyBytes, allowMalformed: true);
        print("UTF-8 Decoded Body:\n>>>\n$utf8DecodedBody\n<<<");
        print("OCRDataSourceImpl returning full decoded body to UseCase.");
        return utf8DecodedBody;
      } else {
        String detail = 'HTTP Error ${response.statusCode}';
        String errorBodyUtf8 = '';
        try {
          errorBodyUtf8 = utf8.decode(response.bodyBytes, allowMalformed: true);
          print("OCR Error Response Body (UTF-8 Decoded): $errorBodyUtf8");
          try {
            final errorBodyJson =
                json.decode(errorBodyUtf8) as Map<String, dynamic>;
            if (errorBodyJson.containsKey('detail')) {
              detail = errorBodyJson['detail'].toString();
            } else {
              detail = errorBodyUtf8;
            }
          } catch (jsonError) {
            print(
                "Failed to parse error body as JSON: $jsonError. Using raw decoded body as detail.");
            detail = errorBodyUtf8;
          }
        } catch (decodeError) {
          print(
              "Failed to decode error body: $decodeError. Using default detail: $detail");
        }
        throw ServerException(
            'OCR request failed: $detail (Service: $selectedOcrService)');
      }
    } on SocketException catch (e, s) {
      print("OCR SocketException: $e\nStackTrace: $s");
      throw NetworkException('Lỗi mạng: Không thể kết nối đến dịch vụ OCR.');
    } on http.ClientException catch (e, s) {
      print("OCR ClientException: $e\nStackTrace: $s");
      throw NetworkException(
          'Lỗi mạng trong quá trình gửi yêu cầu OCR: ${e.message}');
    } catch (e, s) {
      print("OCR Unexpected Error: $e\nStackTrace: $s");
      throw ServerException(
          'Đã xảy ra lỗi không mong muốn trong quá trình xử lý OCR: ${e.runtimeType} (Service: $selectedOcrService)');
    }
  }
}
