import 'dart:io'; // For File type in potential future OCR integration within repo

import 'package:fpdart/fpdart.dart';
import 'package:hyper_split_bill/core/error/exceptions.dart';
import 'package:hyper_split_bill/core/error/failures.dart';
import 'package:hyper_split_bill/features/bill_splitting/data/datasources/bill_remote_data_source.dart';
// import 'package:hyper_split_bill/features/bill_splitting/data/datasources/ocr_data_source.dart'; // Import if OCR logic is handled here
import 'package:hyper_split_bill/features/bill_splitting/data/models/bill_item_model.dart';
import 'package:hyper_split_bill/features/bill_splitting/data/models/bill_model.dart';
import 'package:hyper_split_bill/features/bill_splitting/domain/entities/bill_item_entity.dart'; // Import entity
import 'package:hyper_split_bill/features/bill_splitting/domain/entities/participant_entity.dart'; // Import entity
import 'package:hyper_split_bill/features/bill_splitting/data/models/participant_model.dart';
import 'package:hyper_split_bill/features/bill_splitting/domain/entities/bill_entity.dart';
import 'package:hyper_split_bill/features/bill_splitting/domain/repositories/bill_repository.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: BillRepository) // Register with GetIt
class BillRepositoryImpl implements BillRepository {
  final BillRemoteDataSource remoteDataSource;
  // final OcrDataSource ocrDataSource; // Inject OCR source if needed directly

  BillRepositoryImpl({
    required this.remoteDataSource,
    // required this.ocrDataSource,
  });

  // Helper function to handle common try-catch logic for remote calls
  Future<Either<Failure, T>> _handleRemoteCall<T>(
      Future<T> Function() call) async {
    try {
      // TODO: Add network connectivity check here if needed
      // if (!await networkInfo.isConnected) {
      //   return Left(NetworkFailure('No internet connection'));
      // }
      final result = await call();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on AuthServerException catch (e) {
      // Handle auth errors if applicable
      return Left(AuthServerFailure(e.message));
    } catch (e) {
      // Log the error e.toString()
      return Left(
          ServerFailure('An unexpected error occurred: ${e.runtimeType}'));
    }
  }

  @override
  Future<Either<Failure, BillEntity>> createBill(BillEntity bill) async {
    // Convert main entity and lists to models
    final billModel = BillModel.fromEntity(bill);
    final itemModels = (bill.items ?? [])
        .map((item) => BillItemModel.fromEntity(item))
        .toList();
    final participantModels = (bill.participants ?? [])
        .map((p) => ParticipantModel.fromEntity(p))
        .toList();

    return _handleRemoteCall<BillEntity>(() async {
      // 1. Create the main bill record and get its ID
      final createdBillModel = await remoteDataSource.createBill(billModel);
      final billId = createdBillModel.id; // Get the generated ID

      // 2. Save items associated with the new bill ID
      List<BillItemModel> savedItemModels = [];
      if (itemModels.isNotEmpty) {
        savedItemModels =
            await remoteDataSource.saveBillItems(itemModels, billId);
      }

      // 3. Save participants associated with the new bill ID
      List<ParticipantModel> savedParticipantModels = [];
      if (participantModels.isNotEmpty) {
        savedParticipantModels =
            await remoteDataSource.saveParticipants(participantModels, billId);
      }

      // 4. Return the complete BillEntity (including saved items/participants if needed)
      // Convert saved models back to entities
      final savedItems = savedItemModels.cast<BillItemEntity>().toList();
      final savedParticipants =
          savedParticipantModels.cast<ParticipantEntity>().toList();

      // Return the original created bill entity but potentially updated with saved items/participants
      // Note: BillModel extends BillEntity, so direct cast is possible.
      // We might want to return a copyWith the saved lists if the original entity didn't have them.
      return (createdBillModel as BillEntity).copyWith(
        items: savedItems.isNotEmpty ? savedItems : null,
        participants: savedParticipants.isNotEmpty ? savedParticipants : null,
      );
    });
  }

  @override
  Future<Either<Failure, void>> deleteBill(String billId) async {
    return _handleRemoteCall(() => remoteDataSource.deleteBill(billId));
  }

  @override
  Future<Either<Failure, BillEntity>> getBillDetails(String billId) async {
    return _handleRemoteCall(() async {
      final billModel = await remoteDataSource.getBillDetails(billId);
      return billModel as BillEntity; // BillModel extends BillEntity
    });
  }

  @override
  Future<Either<Failure, List<BillEntity>>> getBills() async {
    return _handleRemoteCall(() async {
      final billModels = await remoteDataSource.getBills();
      // Convert List<BillModel> to List<BillEntity>
      // Since BillModel extends BillEntity, direct casting works if needed,
      // but explicit mapping can be safer if subtypes have differences.
      return billModels.cast<BillEntity>().toList();
    });
  }

  @override
  Future<Either<Failure, BillEntity>> updateBill(BillEntity bill) async {
    final billModel = BillModel.fromEntity(bill);
    return _handleRemoteCall(() async {
      final updatedBillModel = await remoteDataSource.updateBill(billModel);
      return updatedBillModel as BillEntity; // BillModel extends BillEntity
    });
  }

  // TODO: Implement methods for items, participants, assignments by calling remoteDataSource
  // TODO: Implement OCR logic if needed (might be better in a UseCase)
  // Example:
  // Future<Either<Failure, String>> extractBillText(File imageFile) async {
  //   try {
  //     final extractedText = await ocrDataSource.extractTextFromImage(imageFile: imageFile);
  //     return Right(extractedText);
  //   } on ServerException catch (e) {
  //     return Left(ServerFailure(e.message));
  //   } catch (e) {
  //     return Left(ServerFailure('OCR processing failed: ${e.runtimeType}'));
  //   }
  // }
}
