import 'dart:convert'; // For jsonDecode
import 'dart:io';
import 'package:fpdart/fpdart.dart';
import 'package:hyper_split_bill/core/error/exceptions.dart'; // Import exceptions for specific handling
import 'package:hyper_split_bill/core/error/failures.dart';
import 'package:hyper_split_bill/features/bill_splitting/data/datasources/ocr_data_source.dart'; // Use OcrDataSource directly for now
import 'package:injectable/injectable.dart';

// Use case for processing a bill image using OCR.
@lazySingleton // Register with GetIt
// Removed duplicate annotation
class ProcessBillOcrUseCase {
  // Inject OcrDataSource directly. Alternatively, create an OcrRepository.
  final OcrDataSource ocrDataSource;

  ProcessBillOcrUseCase(this.ocrDataSource);

  // Takes the image file.
  // Returns a structured JSON representation of the bill or a Failure.
  Future<Either<Failure, String>> call({required File imageFile}) async {
    // --- Define the Detailed Prompt for OCR API ---
    // Requesting JSON output directly from the OCR Vision model.
    const String detailedPrompt = """
Analyze the following bill image and Return ONLY a valid JSON object with the structured data.
NO explanatory text, NO markdown code blocks.

If a field cannot be inferred, the value is the EMPTY STRING: ""

JSON fields MUST be:
- "bill_date": (string, YYYY-MM-DD, bill date or payment date)
- "description": (string, store name or a general description)
- "currency_code": (string, e.g., "USD", "RUB", "VND", based on the main language of the bill)
- "subtotal_amount": (number, subtotal before tax/tip/discount)
- "tax_amount": (number, total tax amount)
- "tip_amount": (number, total tip amount)
- "discount_amount": (number, total discount amount)
- "total_amount": (number, the final total amount paid)
- "items": (array of objects: {"description": string, "quantity": number, "unit_price": number, "total_price": number})

Extract the items listed on the bill. For each item, determine its description, quantity (default to 1 if not specified), unit price (if available), and total price. If only the total price for an item line is available, use that for "total_price" and potentially estimate "unit_price" if quantity is known. If quantity or unit price is ambiguous, make a reasonable guess or omit the field. Ensure the sum of "total_price" for all items is reasonably close to the "subtotal_amount" if available.
""";

    try {
      // Call OCR DataSource with the detailed prompt
      final structuredJsonString = await ocrDataSource.extractTextFromImage(
        imageFile: imageFile,
        prompt: detailedPrompt, // Pass the detailed prompt
      );

      // --- Attempt to Parse and Validate the received string ---
      String receivedString = structuredJsonString.trim();
      print("ProcessBillOcrUseCase received string: $receivedString");

      // Remove potential markdown fences first
      final RegExp jsonBlockRegex = RegExp(r'```json\s*([\s\S]*?)\s*```');
      final match = jsonBlockRegex.firstMatch(receivedString);
      if (match != null && match.groupCount >= 1) {
        print("Found and removed markdown fences.");
        receivedString = match.group(1)!.trim();
      }

      try {
        // Try to decode the string as JSON
        final decodedJson = json.decode(receivedString);

        // Check if it's a Map (expected structure)
        if (decodedJson is Map<String, dynamic>) {
          print("Successfully decoded response as JSON Map.");
          // Check for the presence of key fields we expect in the structured output
          // Ưu tiên kiểm tra lỗi do API báo cáo trước
          if (decodedJson.containsKey('error')) {
            print(
                "Warning: API returned JSON containing an error field: ${decodedJson['error']}");
            return Left(ServerFailure(
                'OCR API reported an error: ${decodedJson['error']}'));
          }
          // Kiểm tra xem có đúng cấu trúc JSON mong đợi không
          else if (decodedJson.containsKey('total_amount') &&
              decodedJson.containsKey('items')) {
            print("ProcessBillOcrUseCase returning structured JSON.");
            return Right(receivedString);
          }
          // Kiểm tra xem có phải JSON cấu trúc nằm trong extracted_text không
          else if (decodedJson.containsKey('extracted_text')) {
            final extractedText =
                decodedJson['extracted_text'] as String? ?? '';
            print(
                "Found 'extracted_text'. Attempting to parse its content as JSON.");
            try {
              final innerJson = json.decode(extractedText);
              if (innerJson is Map<String, dynamic> &&
                  innerJson.containsKey('total_amount') &&
                  innerJson.containsKey('items')) {
                print(
                    "Successfully parsed structured JSON from 'extracted_text'.");
                // Trả về chuỗi JSON bên trong
                return Right(extractedText);
              } else {
                print(
                    "Warning: Content of 'extracted_text' is not the expected structured JSON.");
                return Left(OcrParsingFailure(
                    'OCR model returned JSON inside extracted_text, but it lacks expected fields. Content: $extractedText'));
              }
            } catch (e) {
              print("Error parsing content of 'extracted_text' as JSON: $e.");
              // Lỗi này chỉ ra JSON bên trong extracted_text không hợp lệ
              return Left(OcrParsingFailure(
                  'Failed to parse JSON content within extracted_text. Invalid format received from OCR API. Content: $extractedText'));
            }
          }
          // Trường hợp JSON không có cấu trúc mong đợi và cũng không phải lỗi hay text thô
          else {
            print(
                "Warning: API returned JSON with unexpected structure. Keys found: ${decodedJson.keys.join(', ')}");
            return Left(ServerFailure(
                'API returned an unexpected JSON structure. Content: $receivedString'));
          }
        } else {
          // Decoded successfully, but it's not a Map (e.g., just a string, number, or list)
          print(
              "Warning: API response decoded as JSON, but it's not a Map: ${decodedJson.runtimeType}");
          return Left(ServerFailure(
              'API returned unexpected JSON type (${decodedJson.runtimeType}). Content: $receivedString'));
        }
      } on FormatException catch (e) {
        // If jsonDecode fails, it means the string wasn't valid JSON at all.
        print(
            "Error: Failed to decode API response as JSON. Error: $e. Raw string: $receivedString");
        // Treat this as a failure.
        return Left(ServerFailure(
            'API did not return valid JSON. Raw response: $receivedString'));
      }
    } on ServerException catch (e, s) {
      print("ProcessBillOcrUseCase caught ServerException: $e\nStackTrace: $s");
      return Left(ServerFailure('OCR Service Error: ${e.message}'));
    } on NetworkException catch (e, s) {
      print(
          "ProcessBillOcrUseCase caught NetworkException: $e\nStackTrace: $s");
      return Left(NetworkFailure('OCR Network Error: ${e.message}'));
    } catch (e, s) {
      print(
          "ProcessBillOcrUseCase caught Unexpected Error: $e\nStackTrace: $s");
      return Left(
          ServerFailure('Unexpected OCR processing error: ${e.runtimeType}'));
    }
  }
}
