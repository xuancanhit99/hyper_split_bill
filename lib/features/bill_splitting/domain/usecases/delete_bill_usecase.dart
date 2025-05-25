import 'package:fpdart/fpdart.dart';
import 'package:equatable/equatable.dart';
import 'package:hyper_split_bill/core/error/failures.dart';
import 'package:hyper_split_bill/core/usecases/usecase.dart';
import 'package:hyper_split_bill/features/bill_splitting/domain/repositories/bill_repository.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class DeleteBillUseCase implements UseCase<void, DeleteBillParams> {
  final BillRepository repository;

  DeleteBillUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteBillParams params) async {
    return await repository.deleteBill(params.billId);
  }
}

class DeleteBillParams extends Equatable {
  final String billId;

  const DeleteBillParams({required this.billId});

  @override
  List<Object?> get props => [billId];
}
