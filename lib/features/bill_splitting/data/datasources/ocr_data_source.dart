import 'dart:io'; // Required for File type

// Abstract contract for interacting with an OCR service.
abstract class OcrDataSource {
  // Extracts text from an image file using the specified OCR service.
  // Takes the image file and an optional prompt.
  // Returns the extracted text content.
  Future<String> extractTextFromImage({
    required File imageFile,
    String? prompt,
    // Optional: Add parameters for specific model selection if needed
    // String? modelName,
  });
}
