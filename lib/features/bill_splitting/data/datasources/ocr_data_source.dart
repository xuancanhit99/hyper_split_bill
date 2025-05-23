import 'dart:io'; // Required for File type
import 'dart:typed_data'; // Required for Uint8List

// Abstract contract for interacting with an OCR service.
abstract class OcrDataSource {
  // Extracts text from an image file or web image bytes using the specified OCR service.
  // Takes either the image file (for native platforms) or image bytes (for web) and an optional prompt.
  // Returns the extracted text content.
  Future<String> extractTextFromImage({
    File? imageFile,
    Uint8List? webImageBytes,
    String? prompt,
    // Optional: Add parameters for specific model selection if needed
    // String? modelName,
  });
  
  // Checks if the OCR API is available and accessible.
  // Particularly useful for web platforms to check connectivity before attempting OCR.
  // Returns true if the API is available, false otherwise.
  Future<bool> checkOcrApiAvailability();
}
