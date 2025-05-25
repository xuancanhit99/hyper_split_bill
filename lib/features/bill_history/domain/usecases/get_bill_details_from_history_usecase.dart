import 'package:fpdart/fpdart.dart';
import 'package:hyper_split_bill/core/error/failures.dart';
import 'package:hyper_split_bill/core/usecases/usecase.dart';
import 'package:hyper_split_bill/features/bill_history/domain/entities/historical_bill_entity.dart';
import 'package:hyper_split_bill/features/bill_history/domain/repositories/bill_history_repository.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class GetBillDetailsFromHistoryUseCase
    implements UseCase<HistoricalBillEntity, String> {
  // Params is String (billId)
  final BillHistoryRepository repository;

  GetBillDetailsFromHistoryUseCase(this.repository);

  @override
  Future<Either<Failure, HistoricalBillEntity>> call(String params) async {
    // params is billId
    return await repository.getBillDetailsFromHistory(params);
  }
}
