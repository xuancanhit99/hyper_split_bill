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

  // Takes the image file and an optional prompt.
  // Returns the extracted text or a Failure.
  Future<Either<Failure, String>> call({
    required File imageFile,
    String? prompt,
  }) async {
    try {
      final extractedText = await ocrDataSource.extractTextFromImage(
        imageFile: imageFile,
        prompt: prompt,
      );
      // TODO: Add any domain-level processing/validation of the extracted text if needed.
      return Right(extractedText);
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
