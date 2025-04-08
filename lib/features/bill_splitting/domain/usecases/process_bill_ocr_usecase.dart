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
Analyze the following bill image and return ONLY a valid JSON object containing the structured data.
Do not include any explanatory text before or after the JSON object.
Do not use markdown code blocks (like ```json).
The JSON object MUST have the following fields:
- "bill_date": (string, format YYYY-MM-DD, try to infer from text, otherwise null)
- "description": (string, optional, try to infer store name or a general description)
- "currency_code": (string, e.g., "USD", "VND", try to infer, default to "USD" if unsure)
- "subtotal_amount": (number, subtotal before tax/tip/discount, null if not found)
- "tax_amount": (number, total tax amount, null if not found)
- "tip_amount": (number, total tip amount, null if not found)
- "discount_amount": (number, total discount amount, null if not found)
- "total_amount": (number, the final total amount paid, should be present)
- "items": (array of objects, each with "description": string, "quantity": number, "unit_price": number, "total_price": number)

Extract the items listed on the bill. For each item, determine its description, quantity (default to 1 if not specified), unit price (if available), and total price. If only the total price for an item line is available, use that for "total_price" and potentially estimate "unit_price" if quantity is known. If quantity or unit price is ambiguous, make a reasonable guess or omit the field. Ensure the sum of "total_price" for all items is reasonably close to the "subtotal_amount" if available.

If any required numeric field (like total_amount) cannot be found or parsed, return a JSON object with an "error" field describing the issue, e.g., {"error": "Could not determine total amount"}.
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
          if (decodedJson.containsKey('total_amount') &&
              decodedJson.containsKey('items')) {
            // API returned the expected structured JSON. Return it.
            print("ProcessBillOcrUseCase returning structured JSON.");
            return Right(receivedString);
          } else if (decodedJson.containsKey('extracted_text')) {
            // API returned the simple {extracted_text: ...} structure.
            // Return the raw text itself for the next step (structuring).
            final rawText = decodedJson['extracted_text'] as String? ?? '';
            print(
                "ProcessBillOcrUseCase returning raw extracted text for structuring.");
            // NOTE: The success value now represents RAW TEXT in this case.
            // The Bloc needs to handle this and call the structuring use case.
            return Right(rawText);
          } else if (decodedJson.containsKey('error')) {
            // Handle the case where the API itself reported an error in the JSON
            print(
                "Warning: API returned JSON containing an error field: ${decodedJson['error']}");
            return Left(ServerFailure(
                'OCR API reported an error: ${decodedJson['error']}'));
          } else {
            print(
                "Warning: API returned JSON, but it lacks expected fields (total_amount, items) or known alternatives (extracted_text, error).");
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
