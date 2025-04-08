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
Analyze the following bill text extracted via OCR and return ONLY a valid JSON object containing the structured data.
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
