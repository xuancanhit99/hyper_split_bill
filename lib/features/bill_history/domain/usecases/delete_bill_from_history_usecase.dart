import 'package:fpdart/fpdart.dart';
import 'package:hyper_split_bill/core/error/failures.dart';
import 'package:hyper_split_bill/core/usecases/usecase.dart';
import 'package:hyper_split_bill/features/bill_history/domain/repositories/bill_history_repository.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class DeleteBillFromHistoryUseCase implements UseCase<void, String> {
  // Type is void, Params is String (billId)
  final BillHistoryRepository repository;

  DeleteBillFromHistoryUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String params) async {
    // params is billId
    return await repository.deleteBillFromHistory(params);
  }
}
