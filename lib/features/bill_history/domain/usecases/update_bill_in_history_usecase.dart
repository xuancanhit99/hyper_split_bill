import 'package:fpdart/fpdart.dart';
import 'package:hyper_split_bill/core/error/failures.dart';
import 'package:hyper_split_bill/core/usecases/usecase.dart';
import 'package:hyper_split_bill/features/bill_history/domain/entities/historical_bill_entity.dart';
import 'package:hyper_split_bill/features/bill_history/domain/repositories/bill_history_repository.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class UpdateBillInHistoryUseCase
    implements UseCase<HistoricalBillEntity, HistoricalBillEntity> {
  // Params is HistoricalBillEntity
  final BillHistoryRepository repository;

  UpdateBillInHistoryUseCase(this.repository);

  @override
  Future<Either<Failure, HistoricalBillEntity>> call(
      HistoricalBillEntity params) async {
    // params is the bill to update
    return await repository.updateBillInHistory(params);
  }
}
