import  'package:fpdart/fpdart.dart';
import 'package:equatable/equatable.dart';
import 'package:hyper_split_bill/core/error/failures.dart';
import 'package:hyper_split_bill/core/usecases/usecase.dart';
import 'package:hyper_split_bill/features/bill_splitting/domain/entities/bill_entity.dart';
import 'package:hyper_split_bill/features/bill_splitting/domain/repositories/bill_repository.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class UpdateBillUseCase implements UseCase<BillEntity, UpdateBillParams> {
  final BillRepository repository;

  UpdateBillUseCase(this.repository);

  @override
  Future<Either<Failure, BillEntity>> call(UpdateBillParams params) async {
    return await repository.updateBill(params.bill);
  }
}

class UpdateBillParams extends Equatable {
  final BillEntity bill;

  const UpdateBillParams({required this.bill});

  @override
  List<Object?> get props => [bill];
}
