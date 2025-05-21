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

If a field cannot be inferred, the value is the EMPTY STRING: "" for strings, or 0 for numbers where applicable (like tax, tip, discount), or an empty array [] for items.
First, determine if the image is a receipt/bill/invoice. Set "is_receipt" accordingly. If it is NOT a receipt, provide a brief category description in "image_category" and leave other bill-related fields empty or with default values (0, "", []). If it IS a receipt, extract all other fields as accurately as possible and you can omit "image_category".

JSON fields MUST be:
- "is_receipt": (boolean, true if the document is likely a bill/invoice/receipt, false otherwise)
- "image_category": (string, if is_receipt is true then determine what category: "bill", "invoice", "receipt". If is_receipt is false then briefly describe the main content of the image and put an emoji before the description. If unable to determine 'unknown')
- "bill_date": (string, YYYY-MM-DD, bill date or payment date)
- "description": (string, store name or a general description)
- "currency_code": (string, e.g., "USD", "RUB", "VND", based on the main language of the bill)
- "subtotal_amount": (number, subtotal before tax/tip/discount, 0 if not found)
- "tax_amount": (number, total tax amount, 0 if not found)
- "tip_amount": (number, total tip amount, 0 if not found)
- "discount_amount": (number, total discount amount, 0 if not found)
- "total_amount": (number, the final total amount paid, 0 if not found)
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

          // --- Updated Validation Logic ---
          // 1. Check for API-reported error first
          if (decodedJson.containsKey('error') &&
              decodedJson['error'] != null) {
            print(
                "API returned JSON containing an error field: ${decodedJson['error']}");
            return Left(ServerFailure(
                'OCR API reported an error: ${decodedJson['error']}'));
          }

          // 2. Check if the top-level JSON contains 'is_receipt' (our primary indicator)
          if (decodedJson.containsKey('is_receipt')) {
            print(
                "Found 'is_receipt' in top-level JSON. Returning structured JSON.");
            final decodedJson = json.decode(receivedString);
            final encoder =
                JsonEncoder.withIndent('  '); // Use 2 spaces for indentation
            final formattedJson = encoder.convert(decodedJson);
            print("Returning formatted JSON string (top-level).");
            return Right(formattedJson); // Return the formatted JSON string
          }

          // 3. Check if 'extracted_text' contains JSON with 'is_receipt'
          if (decodedJson.containsKey('extracted_text')) {
            final extractedText =
                decodedJson['extracted_text'] as String? ?? '';
            print(
                "Found 'extracted_text'. Attempting to parse its content as JSON.");
            try {
              final innerJson = json.decode(extractedText);
              if (innerJson is Map<String, dynamic> &&
                  innerJson.containsKey('is_receipt')) {
                // Check for 'is_receipt' inside
                print(
                    "Successfully parsed JSON with 'is_receipt' from 'extracted_text'.");
                // Return the INNER JSON string, as this is the actual structured data
                final innerJson = json.decode(extractedText);
                final encoder = JsonEncoder.withIndent(
                    '  '); // Use 2 spaces for indentation
                final formattedInnerJson = encoder.convert(innerJson);
                print("Returning formatted JSON string (from extracted_text).");
                return Right(
                    formattedInnerJson); // Return the formatted INNER JSON string
              } else {
                print(
                    "Warning: Content of 'extracted_text' is JSON but lacks 'is_receipt' field.");
                return Left(OcrParsingFailure(
                    "OCR model returned JSON inside extracted_text, but it lacks the 'is_receipt' field. Content: $extractedText"));
              }
            } catch (e) {
              print("Error parsing content of 'extracted_text' as JSON: $e.");
              return Left(OcrParsingFailure(
                  'Failed to parse JSON content within extracted_text. Invalid format received from OCR API. Content: $extractedText'));
            }
          }

          // 4. If none of the above, the structure is unexpected
          print(
              "Warning: API returned JSON without 'error', 'is_receipt', or valid 'extracted_text' containing 'is_receipt'. Keys found: ${decodedJson.keys.join(', ')}");
          return Left(ServerFailure(
              'API returned an unexpected JSON structure. Content: $receivedString'));
          // --- End Updated Validation Logic ---
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
