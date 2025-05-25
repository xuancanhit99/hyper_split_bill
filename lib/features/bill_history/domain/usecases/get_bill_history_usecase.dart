import 'package:fpdart/fpdart.dart';
import 'package:hyper_split_bill/core/error/failures.dart';
import 'package:hyper_split_bill/core/usecases/usecase.dart';
import 'package:hyper_split_bill/features/bill_history/domain/entities/historical_bill_entity.dart';
import 'package:hyper_split_bill/features/bill_history/domain/repositories/bill_history_repository.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class GetBillHistoryUseCase
    implements UseCase<List<HistoricalBillEntity>, NoParams> {
  final BillHistoryRepository repository;

  GetBillHistoryUseCase(this.repository);

  @override
  Future<Either<Failure, List<HistoricalBillEntity>>> call(
      NoParams params) async {
    return await repository.getBillHistory();
  }
}
