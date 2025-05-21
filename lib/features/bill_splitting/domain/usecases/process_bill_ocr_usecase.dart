import 'dart:convert'; // For jsonDecode
import 'dart:io';
import 'package:fpdart/fpdart.dart';
import 'package:hyper_split_bill/core/error/exceptions.dart'; // Import exceptions for specific handling
import 'package:hyper_split_bill/core/error/failures.dart';
import 'package:hyper_split_bill/features/bill_splitting/data/datasources/ocr_data_source.dart'; // Use OcrDataSource directly for now
import 'package:injectable/injectable.dart';

import 'package:hyper_split_bill/core/prompts/ocr_prompts.dart';

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

    try {
      // Call OCR DataSource with the detailed prompt
      final structuredJsonString = await ocrDataSource.extractTextFromImage(
        imageFile: imageFile,
        prompt: ocrPrompt, // Pass the detailed prompt
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
