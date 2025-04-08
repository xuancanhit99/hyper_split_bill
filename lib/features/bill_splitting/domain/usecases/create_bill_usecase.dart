import 'package:fpdart/fpdart.dart';
import 'package:hyper_split_bill/core/error/failures.dart';
import 'package:hyper_split_bill/features/bill_splitting/domain/entities/bill_entity.dart';
import 'package:hyper_split_bill/features/bill_splitting/domain/repositories/bill_repository.dart';
import 'package:injectable/injectable.dart';

// Use case for creating a new bill.
@lazySingleton
class CreateBillUseCase {
  final BillRepository repository;

  CreateBillUseCase(this.repository);

  // Takes the BillEntity to be created.
  // Returns the created BillEntity (potentially with generated ID) or a Failure.
  Future<Either<Failure, BillEntity>> call(BillEntity bill) async {
    // TODO: Add validation logic here if needed before saving
    // e.g., check if total amount is positive, date is valid etc.

    // For now, directly call the repository method
    return await repository.createBill(bill);
    // TODO: After saving the main bill, potentially save items and participants here
    // This might involve getting the ID from the createdBill and then making
    // separate repository calls to save items/participants associated with that ID.
    // This logic might be better suited in the Bloc or a higher-level service
    // depending on transaction needs.
  }
}
