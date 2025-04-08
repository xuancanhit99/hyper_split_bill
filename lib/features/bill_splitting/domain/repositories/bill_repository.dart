import 'package:fpdart/fpdart.dart';
import 'package:hyper_split_bill/core/error/failures.dart';
import 'package:hyper_split_bill/features/bill_splitting/domain/entities/bill_entity.dart';
// TODO: Import other necessary entities like BillItemEntity, ParticipantEntity later

// Abstract contract for managing bill data.
abstract class BillRepository {
  // Retrieves a list of bills for the current user.
  // Might add pagination parameters later.
  Future<Either<Failure, List<BillEntity>>> getBills();

  // Retrieves the details of a specific bill by its ID.
  Future<Either<Failure, BillEntity>> getBillDetails(String billId);

  // Creates a new bill record.
  // The BillEntity passed might only contain initial data (e.g., from OCR).
  Future<Either<Failure, BillEntity>> createBill(BillEntity bill);

  // Updates an existing bill record.
  Future<Either<Failure, BillEntity>> updateBill(BillEntity bill);

  // Deletes a bill record by its ID.
  Future<Either<Failure, void>> deleteBill(String billId);

  // TODO: Add methods for managing bill items, participants, assignments later
  // e.g., Future<Either<Failure, void>> addBillItem(String billId, BillItemEntity item);
  // e.g., Future<Either<Failure, void>> assignItemToParticipant(...);
}
