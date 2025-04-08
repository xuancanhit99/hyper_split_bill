import 'package:fpdart/fpdart.dart';
import 'package:hyper_split_bill/core/error/failures.dart';
import 'package:hyper_split_bill/features/bill_splitting/domain/entities/bill_entity.dart';
import 'package:hyper_split_bill/features/bill_splitting/domain/repositories/bill_repository.dart';
import 'package:injectable/injectable.dart';

// Use case for fetching the list of bills for the current user.
@lazySingleton
class GetBillsUseCase {
  final BillRepository repository;

  GetBillsUseCase(this.repository);

  // The 'call' method allows the use case instance to be called like a function.
  // Takes no parameters for now, but could accept filters/pagination later.
  Future<Either<Failure, List<BillEntity>>> call() async {
    return await repository.getBills();
  }
}
