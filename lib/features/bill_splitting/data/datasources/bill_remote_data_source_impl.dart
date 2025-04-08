import 'package:hyper_split_bill/core/error/exceptions.dart';
import 'package:hyper_split_bill/features/bill_splitting/data/datasources/bill_remote_data_source.dart';
import 'package:hyper_split_bill/features/bill_splitting/data/models/bill_item_model.dart';
import 'package:hyper_split_bill/features/bill_splitting/data/models/bill_model.dart';
import 'package:hyper_split_bill/features/bill_splitting/data/models/participant_model.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@LazySingleton(as: BillRemoteDataSource) // Register with GetIt
class BillRemoteDataSourceImpl implements BillRemoteDataSource {
  final SupabaseClient _supabaseClient;

  BillRemoteDataSourceImpl(this._supabaseClient);

  // Helper to get current user ID, throws AuthServerException if not logged in
  String _getCurrentUserId() {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) {
      throw const AuthServerException('User not authenticated.');
    }
    return user.id;
  }

  @override
  Future<BillModel> createBill(BillModel bill) async {
    // --- MOCK IMPLEMENTATION: Simulate success without calling DB ---
    print(
        "MOCK: Simulating successful bill creation for user ${bill.payerUserId}");
    // Adding a small delay to simulate network latency
    await Future.delayed(const Duration(milliseconds: 100));
    // Return the input bill as if it was saved (ID might be empty)
    return bill;
  }

  @override
  Future<void> deleteBill(String billId) async {
    try {
      await _supabaseClient.from('bills').delete().match({
        'id': billId,
        'user_id': _getCurrentUserId()
      }); // Ensure user owns the bill
      // No return value needed, success means no exception
    } on PostgrestException catch (e) {
      throw ServerException('Failed to delete bill: ${e.message}');
    } catch (e) {
      throw ServerException(
          'An unexpected error occurred while deleting the bill: ${e.runtimeType}');
    }
  }

  @override
  Future<BillModel> getBillDetails(String billId) async {
    try {
      final response = await _supabaseClient.from('bills').select().match({
        'id': billId,
        'user_id': _getCurrentUserId()
      }) // Ensure user owns the bill
          .single(); // Expect one bill or PostgrestException

      return BillModel.fromMap(response);
    } on PostgrestException catch (e) {
      // Handle cases like bill not found (e.code == 'PGRST116') or other DB errors
      if (e.code == 'PGRST116') {
        // code for "JSON object requested, multiple (or no) rows returned"
        throw ServerException('Bill not found or access denied.');
      }
      throw ServerException('Failed to get bill details: ${e.message}');
    } catch (e) {
      throw ServerException(
          'An unexpected error occurred while fetching bill details: ${e.runtimeType}');
    }
  }

  @override
  Future<List<BillModel>> getBills() async {
    try {
      final response = await _supabaseClient
          .from('bills')
          .select()
          .eq('user_id', _getCurrentUserId()) // Filter by current user
          .order('created_at', ascending: false); // Order by creation date

      final bills = (response as List)
          .map(
              (billData) => BillModel.fromMap(billData as Map<String, dynamic>))
          .toList();
      return bills;
    } on PostgrestException catch (e) {
      throw ServerException('Failed to get bills: ${e.message}');
    } catch (e) {
      throw ServerException(
          'An unexpected error occurred while fetching bills: ${e.runtimeType}');
    }
  }

  @override
  Future<BillModel> updateBill(BillModel bill) async {
    try {
      // Ensure user_id is not accidentally updated if present in the map
      final billData = bill.toMap()
        ..remove('user_id')
        ..remove('id')
        ..remove('created_at');

      final response = await _supabaseClient
          .from('bills')
          .update(billData)
          .match({
            'id': bill.id,
            'user_id': _getCurrentUserId()
          }) // Ensure user owns the bill
          .select()
          .single();

      return BillModel.fromMap(response);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        // No rows updated/returned
        throw ServerException('Bill not found or update failed.');
      }
      throw ServerException('Failed to update bill: ${e.message}');
    } catch (e) {
      throw ServerException(
          'An unexpected error occurred while updating the bill: ${e.runtimeType}');
    }
  }

  @override
  Future<List<BillItemModel>> saveBillItems(
      List<BillItemModel> items, String billId) async {
    // --- MOCK IMPLEMENTATION: Simulate success ---
    print("MOCK: Simulating successful bill items save for bill $billId");
    // Adding a small delay to simulate network latency
    await Future.delayed(const Duration(milliseconds: 50));
    // Return the input items list as if they were saved
    return items;
  }

  @override
  Future<List<ParticipantModel>> saveParticipants(
      List<ParticipantModel> participants, String billId) async {
    // --- MOCK IMPLEMENTATION: Simulate success ---
    print("MOCK: Simulating successful participants save for bill $billId");
    // Adding a small delay to simulate network latency
    await Future.delayed(const Duration(milliseconds: 50));
    // Return the input participants list as if they were saved
    return participants;
  }

  // TODO: Implement methods for assignments
}
