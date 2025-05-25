import 'package:hyper_split_bill/features/bill_splitting/data/models/bill_item_model.dart';
import 'package:hyper_split_bill/features/bill_splitting/data/models/bill_model.dart';
import 'package:hyper_split_bill/features/bill_splitting/data/models/participant_model.dart';
import 'package:hyper_split_bill/features/bill_splitting/domain/entities/bill_item_entity.dart';
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

  // Saves multiple bill items associated with a billId.
  Future<List<BillItemModel>> saveBillItems(
      List<BillItemModel> items, String billId);

  // Saves multiple participants associated with a billId.
  Future<List<ParticipantModel>> saveParticipants(
      List<ParticipantModel> participants, String billId);
      
  // Deletes existing bill items for a specific bill ID.
  Future<void> deleteBillItems(String billId);
    // Deletes existing participants for a specific bill ID.
  Future<void> deleteParticipants(String billId);

  // Deletes existing item-participant assignments for a specific bill ID
  Future<void> deleteItemAssignments(String billId);
  
  // Saves item-participant assignments for items
  Future<void> saveItemAssignments(List<BillItemEntity> items);
}
