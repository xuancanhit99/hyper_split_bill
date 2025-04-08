import 'package:fpdart/fpdart.dart';
import 'package:hyper_split_bill/core/error/exceptions.dart';
import 'package:hyper_split_bill/core/error/failures.dart';
import 'package:hyper_split_bill/features/bill_splitting/data/datasources/chat_data_source.dart';
import 'package:injectable/injectable.dart';

// Use case for structuring raw OCR text into bill data using a Chat API.
@lazySingleton
class StructureBillDataUseCase {
  final ChatDataSource chatDataSource;

  StructureBillDataUseCase(this.chatDataSource);

  // Takes the raw OCR text.
  // Returns a structured representation (e.g., JSON string) or a Failure.
  Future<Either<Failure, String>> call({required String ocrText}) async {
    // --- Define the Prompt ---
    const String detailedPrompt = """
Analyze the following bill text extracted via OCR. Return ONLY a valid JSON object with the structured data.
NO explanatory text, NO markdown code blocks.
JSON fields MUST be:
- "bill_date": (string, YYYY-MM-DD or null)
- "description": (string or null)
- "currency_code": (string, e.g., "USD", "RUB", "VND", infer or default to "USD")
- "subtotal_amount": (number or null)
- "tax_amount": (number or null)
- "tip_amount": (number or null)
- "discount_amount": (number or null)
- "total_amount": (number, MUST be present)
- "items": (array of objects: {"description": string, "quantity": number, "unit_price": number, "total_price": number})

Extract items with description, quantity (default 1), unit_price (if available), and total_price. Estimate where necessary.
If total_amount cannot be parsed, return {"error": "Could not determine total amount"}.
""";

    try {
      // Send the prompt to the Chat API
      final structuredJsonString = await chatDataSource.sendMessage(
        message:
            "$detailedPrompt\n\nOCR Text:\n```\n$ocrText\n```\n\nJSON Output:", // Re-add OCR text context clearly
        // modelName: 'gemini-pro' // Or specify a model suitable for JSON output
      );

      // --- Clean and Extract JSON ---
      print(
          "Raw response from Chat API before cleaning:\n>>>\n$structuredJsonString\n<<<");
      String potentialJson = structuredJsonString.trim();
      bool foundMarkdown = false;

      // 1. Try to find JSON within markdown code blocks first (making 'json' optional)
      final RegExp jsonBlockRegex =
          RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```', multiLine: true);
      final match = jsonBlockRegex.firstMatch(potentialJson);

      if (match != null && match.groupCount >= 1) {
        potentialJson = match.group(1)!.trim();
        foundMarkdown = true;
        print("Extracted JSON from markdown block:\n>>>\n$potentialJson\n<<<");
      } else {
        print("No markdown block found in Chat API response.");
      }

      // 2. If no markdown block was found OR if after removing markdown it's still not valid JSON,
      //    try finding the first '{' and last '}' as a fallback.
      if (!foundMarkdown ||
          !(potentialJson.startsWith('{') && potentialJson.endsWith('}'))) {
        print(
            "Attempting to extract JSON by finding first/last braces '{...}'");
        int firstBrace = potentialJson.indexOf('{');
        int lastBrace = potentialJson.lastIndexOf('}');

        if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
          potentialJson = potentialJson.substring(firstBrace, lastBrace + 1);
          print("JSON extracted by finding braces:\n>>>\n$potentialJson\n<<<");
        } else {
          // If still no valid structure found, return error
          print(
              "Error: Could not find valid JSON structure ({...}) even after cleaning attempts. Raw:\n>>>\n$structuredJsonString\n<<<");
          return Left(ServerFailure(
              'Could not extract valid JSON object from the Chat API response. Raw: $structuredJsonString'));
        }
      }

      // 3. Final check and return
      if (potentialJson.startsWith('{') && potentialJson.endsWith('}')) {
        print("Final potential JSON to return:\n>>>\n$potentialJson\n<<<");
        return Right(potentialJson);
      } else {
        print(
            "Error: Final cleaned string does not appear to be a valid JSON object. Cleaned:\n>>>\n$potentialJson\n<<< Raw:\n>>>\n$structuredJsonString\n<<<");
        return Left(ServerFailure(
            'Final cleaned content does not appear to be a valid JSON object. Raw: $structuredJsonString'));
      }
    } on ServerException catch (e, s) {
      print(
          "StructureBillDataUseCase caught ServerException: $e\nStackTrace: $s");
      return Left(
          ServerFailure('Chat API Error for Structuring: ${e.message}'));
    } on NetworkException catch (e, s) {
      print(
          "StructureBillDataUseCase caught NetworkException: $e\nStackTrace: $s");
      return Left(
          NetworkFailure('Chat Network Error for Structuring: ${e.message}'));
    } catch (e, s) {
      print(
          "StructureBillDataUseCase caught Unexpected Error: $e\nStackTrace: $s");
      return Left(ServerFailure(
          'Unexpected error structuring bill data: ${e.runtimeType}'));
    }
  }
}
