import 'package:hyper_split_bill/features/bill_history/data/models/historical_bill_model.dart';
import 'package:hyper_split_bill/features/bill_history/domain/entities/historical_bill_entity.dart';

abstract class BillHistoryRemoteDataSource {
  /// Saves a bill to the history.
  ///
  /// Throws a [ServerException] for all error codes.
  Future<HistoricalBillModel> saveBillToHistory(HistoricalBillEntity bill);

  /// Gets the bill history for the current user.
  ///
  /// Returns a list of [HistoricalBillModel].
  /// Throws a [ServerException] for all error codes.
  Future<List<HistoricalBillModel>> getBillHistory();

  /// Gets the details of a specific bill from history.
  ///
  /// Throws a [ServerException] if the bill is not found or for other error codes.
  Future<HistoricalBillModel> getBillDetailsFromHistory(String billId);

  /// Updates an existing bill in the history.
  ///
  /// Throws a [ServerException] for all error codes.
  Future<HistoricalBillModel> updateBillInHistory(HistoricalBillEntity bill);

  /// Deletes a bill from the history.
  ///
  /// Throws a [ServerException] for all error codes.
  Future<void> deleteBillFromHistory(String billId);
}
