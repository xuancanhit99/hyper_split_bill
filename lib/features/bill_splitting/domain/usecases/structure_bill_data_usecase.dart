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
    // This prompt guides the Chat API to extract and structure the data.
    // It should specify the desired output format (e.g., JSON) and fields.
    // TODO: Refine this prompt for better accuracy and handling complex bills.
    final prompt = """
Analyze the following bill text extracted via OCR and return a JSON object containing the structured data.
The JSON object should have the following fields:
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

If any required numeric field (like total_amount) cannot be found or parsed, return an error structure or indicate failure clearly in the response.

OCR Text:
```
$ocrText
```

JSON Output:
""";

    try {
      // Send the prompt to the Chat API
      final structuredJsonString = await chatDataSource.sendMessage(
        message: prompt,
        // No history needed for this specific task usually
        // modelName: 'gemini-pro' // Or specify a model suitable for JSON output
      );

      // --- Clean and Extract JSON ---
      String cleanedString = structuredJsonString.trim();

      // 1. Remove markdown code block fences if present
      final RegExp jsonBlockRegex = RegExp(r'```json\s*([\s\S]*?)\s*```');
      final match = jsonBlockRegex.firstMatch(cleanedString);
      if (match != null && match.groupCount >= 1) {
        cleanedString = match.group(1)!.trim();
      }

      // 2. Sometimes the model might start directly with '{' or '['
      // Find the first '{' or '[' and the last '}' or ']'
      int firstBracket = cleanedString.indexOf(RegExp(r'[{[]'));
      int lastBracket = cleanedString.lastIndexOf(RegExp(r'[}\]]'));

      if (firstBracket != -1 &&
          lastBracket != -1 &&
          lastBracket > firstBracket) {
        // Extract the potential JSON part
        cleanedString = cleanedString.substring(firstBracket, lastBracket + 1);
      } else {
        // If no brackets found, or invalid range, likely not JSON
        print(
            "Warning: Could not reliably find JSON structure in Chat API response.");
        // Return Left or the potentially non-JSON string based on requirements
        return Left(ServerFailure(
            'Could not extract valid JSON structure from Chat API response. Raw: $structuredJsonString'));
        // Or: return Right(cleanedString); // If you want to attempt parsing anyway
      }

      // 3. Basic validation (starts with { or [ and ends with } or ])
      if ((cleanedString.startsWith('{') && cleanedString.endsWith('}')) ||
          (cleanedString.startsWith('[') && cleanedString.endsWith(']'))) {
        print("Extracted potential JSON: $cleanedString");
        return Right(cleanedString);
      } else {
        print(
            "Warning: Extracted string doesn't look like valid JSON start/end. Raw: $structuredJsonString");
        return Left(ServerFailure(
            'Extracted content does not appear to be valid JSON. Raw: $structuredJsonString'));
        // Code already returns Left(ServerFailure(...)) above this else block
      }
    } on ServerException catch (e) {
      return Left(
          ServerFailure('Chat API Error for Structuring: ${e.message}'));
    } on NetworkException catch (e) {
      return Left(
          NetworkFailure('Chat Network Error for Structuring: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure(
          'Unexpected error structuring bill data: ${e.runtimeType}'));
    }
  }
}
