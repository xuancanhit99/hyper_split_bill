import 'package:hyper_split_bill/features/bill_splitting/data/models/bill_model.dart';
// TODO: Import other necessary models later

// Abstract contract for interacting with remote bill data (e.g., Supabase).
abstract class BillRemoteDataSource {
  Future<List<BillModel>> getBills();

  Future<BillModel> getBillDetails(String billId);

  // Creates a new bill record in the remote database.
  // Returns the created bill data including the generated ID.
  Future<BillModel> createBill(BillModel bill);

  // Updates an existing bill record.
  Future<BillModel> updateBill(BillModel bill);

  // Deletes a bill record.
  Future<void> deleteBill(String billId);

  // TODO: Add methods for managing items, participants, assignments remotely
}
