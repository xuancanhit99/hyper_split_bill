import 'package:fpdart/fpdart.dart';
import 'package:hyper_split_bill/core/error/exceptions.dart';
import 'package:hyper_split_bill/core/error/failures.dart';
import 'package:hyper_split_bill/features/bill_history/data/datasources/bill_history_remote_data_source.dart';
import 'package:hyper_split_bill/features/bill_history/data/models/historical_bill_model.dart';
import 'package:hyper_split_bill/features/bill_history/domain/entities/historical_bill_entity.dart';
import 'package:hyper_split_bill/features/bill_history/domain/repositories/bill_history_repository.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: BillHistoryRepository)
class BillHistoryRepositoryImpl implements BillHistoryRepository {
  final BillHistoryRemoteDataSource remoteDataSource;
  // final NetworkInfo networkInfo; // Assuming you have a NetworkInfo class

  BillHistoryRepositoryImpl({
    required this.remoteDataSource,
    // required this.networkInfo,
  });

  @override
  Future<Either<Failure, HistoricalBillEntity>> saveBillToHistory(
      HistoricalBillEntity bill) async {
    // if (await networkInfo.isConnected) { // Check network connectivity
    try {
      final historicalBillModel = bill is HistoricalBillModel
          ? bill
          : HistoricalBillModel.fromEntity(bill);
      final savedBill =
          await remoteDataSource.saveBillToHistory(historicalBillModel);
      return Right(savedBill);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
    // } else {
    //   return Left(NetworkFailure('No internet connection'));
    // }
  }

  @override
  Future<Either<Failure, List<HistoricalBillEntity>>> getBillHistory() async {
    // if (await networkInfo.isConnected) {
    try {
      final remoteHistory = await remoteDataSource.getBillHistory();
      return Right(remoteHistory);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
    // } else {
    //   return Left(NetworkFailure('No internet connection'));
    // }
  }

  @override
  Future<Either<Failure, HistoricalBillEntity>> getBillDetailsFromHistory(
      String billId) async {
    // if (await networkInfo.isConnected) {
    try {
      final billDetails =
          await remoteDataSource.getBillDetailsFromHistory(billId);
      return Right(billDetails);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
    // } else {
    //   return Left(NetworkFailure('No internet connection'));
    // }
  }

  @override
  Future<Either<Failure, HistoricalBillEntity>> updateBillInHistory(
      HistoricalBillEntity bill) async {
    // if (await networkInfo.isConnected) {
    try {
      final historicalBillModel = bill is HistoricalBillModel
          ? bill
          : HistoricalBillModel.fromEntity(bill);
      final updatedBill =
          await remoteDataSource.updateBillInHistory(historicalBillModel);
      return Right(updatedBill);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
    // } else {
    //   return Left(NetworkFailure('No internet connection'));
    // }
  }

  @override
  Future<Either<Failure, void>> deleteBillFromHistory(String billId) async {
    // if (await networkInfo.isConnected) {
    try {
      await remoteDataSource.deleteBillFromHistory(billId);
      return const Right(null); // Or Right(unit) with fpdart
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
    // } else {
    //   return Left(NetworkFailure('No internet connection'));
    // }
  }
}
