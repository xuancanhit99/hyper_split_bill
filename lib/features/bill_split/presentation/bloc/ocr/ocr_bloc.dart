// import 'dart:async';
// import 'dart:io';
// import 'package:bloc/bloc.dart';
// import 'package:equatable/equatable.dart';
// import 'package:injectable/injectable.dart';
// import 'package:hyper_split_bill/features/bill_split/data/datasources/ocr_api_service.dart';
//
// part 'ocr_event.dart';
// part 'ocr_state.dart';
//
// @injectable // Make sure this Bloc can be injected
// class OcrBloc extends Bloc<OcrEvent, OcrState> {
//   final OcrApiService _ocrApiService;
//
//   OcrBloc(this._ocrApiService) : super(OcrInitial()) {
//     on<OcrRequested>(_onOcrRequested);
//     on<OcrReset>(_onOcrReset);
//   }
//
//   Future<void> _onOcrRequested(
//       OcrRequested event, Emitter<OcrState> emit) async {
//     emit(OcrLoading());
//     try {
//       // IMPORTANT: Define your sophisticated prompt here for structured data!
//       // This prompt is CRUCIAL for getting the JSON structure defined in OcrState.
//       const String structuredPrompt = """
// Analyze this restaurant receipt image. Extract the following details:
// 1.  Line items: For each item, extract its name, quantity (default to 1 if not specified), and total price for that line.
// 2.  Subtotal: The total cost before tax and tip.
// 3.  Tax: The total tax amount.
// 4.  Discount: Any discount amount applied.
// 5.  Grand Total: The final amount payable.
//
// Format the output strictly as a JSON object with the following keys:
// - "items": An array of objects, where each object has "name" (string), "quantity" (integer), and "price" (number).
// - "subtotal": A number representing the subtotal.
// - "tax": A number representing the tax amount.
// - "discount": A number representing the discount amount.
// - "total": A number representing the grand total.
//
// Example Item: {"name": "Burger", "quantity": 1, "price": 12.50}
// If a value (like discount or tax) is not present, use null or 0.00.
// Return ONLY the JSON object.
// """;
//
//       final result = await _ocrApiService.extractTextFromImage(
//         event.imageFile,
//         prompt: event.prompt ?? structuredPrompt, // Use custom prompt or the structured one
//       );
//
//       // --- CRITICAL PARSING STEP ---
//       // Assuming the API returns the full response including your structured data under a specific key
//       // Adjust 'extracted_data' key if your API returns it differently!
//       final Map<String, dynamic>? extractedJson = result['extracted_data'] as Map<String, dynamic>?;
//
//       if (extractedJson != null) {
//         final parsedData = ExtractedBillData.fromJson(extractedJson);
//         print("OCR Success - Parsed Data: $parsedData"); // Debugging
//         emit(OcrSuccess(parsedData));
//       } else {
//         // Handle cases where the API response was 200 OK, but the expected data structure wasn't found
//         // This might happen if the Gemini prompt didn't quite work as expected.
//         print("OCR Warning: API success, but 'extracted_data' key missing or null in response: $result");
//         emit(const OcrFailure("Failed to parse structured data from the receipt. The format might be unexpected."));
//       }
//
//     } catch (e) {
//       print("OCR Bloc Error: $e"); // Log the error
//       emit(OcrFailure("Failed to process receipt: ${e.toString()}"));
//     }
//   }
//
//   void _onOcrReset(OcrReset event, Emitter<OcrState> emit) {
//     emit(OcrInitial());
//   }
// }