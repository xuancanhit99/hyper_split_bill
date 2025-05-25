import 'package:fpdart/fpdart.dart';
import 'package:hyper_split_bill/core/error/failures.dart';
import 'package:hyper_split_bill/features/bill_history/domain/entities/historical_bill_entity.dart';

abstract class BillHistoryRepository {
  Future<Either<Failure, HistoricalBillEntity>> saveBillToHistory(
      HistoricalBillEntity bill);

  Future<Either<Failure, List<HistoricalBillEntity>>> getBillHistory();

  Future<Either<Failure, HistoricalBillEntity>> getBillDetailsFromHistory(
      String billId);

  Future<Either<Failure, HistoricalBillEntity>> updateBillInHistory(
      HistoricalBillEntity bill);

  Future<Either<Failure, void>> deleteBillFromHistory(String billId);
}
