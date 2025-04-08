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
    try {
      // Ensure user_id is set correctly before inserting
      final userId = _getCurrentUserId();
      final billData = bill.toMap()
        ..['user_id'] = userId; // Ensure user_id is set

      final response = await _supabaseClient
          .from('bills')
          .insert(billData)
          .select() // Select the inserted row to get the generated ID
          .single(); // Expect exactly one row back

      return BillModel.fromMap(response);
    } on PostgrestException catch (e) {
      // Handle potential database errors (constraints, etc.)
      // Log e.message, e.code, e.details
      throw ServerException('Failed to create bill: ${e.message}');
    } catch (e) {
      // Handle other errors (e.g., network, unexpected)
      throw ServerException(
          'An unexpected error occurred while creating the bill: ${e.runtimeType}');
    }
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
    if (items.isEmpty) return []; // Nothing to save
    try {
      final userId = _getCurrentUserId();
      final itemsData = items
          .map((item) => item.toMap(billId: billId, userId: userId))
          .toList();

      final response = await _supabaseClient
          .from('bill_items')
          .insert(itemsData)
          .select(); // Select the inserted rows

      return (response as List)
          .map((itemData) =>
              BillItemModel.fromMap(itemData as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException('Failed to save bill items: ${e.message}');
    } catch (e) {
      throw ServerException(
          'An unexpected error occurred while saving bill items: ${e.runtimeType}');
    }
  }

  @override
  Future<List<ParticipantModel>> saveParticipants(
      List<ParticipantModel> participants, String billId) async {
    if (participants.isEmpty) return []; // Nothing to save
    try {
      final userId = _getCurrentUserId();
      final participantsData = participants
          .map((p) => p.toMap(billId: billId, userId: userId))
          .toList();

      final response = await _supabaseClient
          .from('participants')
          .insert(participantsData)
          .select(); // Select the inserted rows

      return (response as List)
          .map((pData) =>
              ParticipantModel.fromMap(pData as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException('Failed to save participants: ${e.message}');
    } catch (e) {
      throw ServerException(
          'An unexpected error occurred while saving participants: ${e.runtimeType}');
    }
  }

  // TODO: Implement methods for assignments
}
