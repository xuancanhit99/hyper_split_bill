import 'package:hyper_split_bill/core/error/exceptions.dart';
import 'package:hyper_split_bill/features/bill_history/data/datasources/bill_history_remote_data_source.dart';
import 'package:hyper_split_bill/features/bill_history/data/models/historical_bill_model.dart';
import 'package:hyper_split_bill/features/bill_history/domain/entities/historical_bill_entity.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@LazySingleton(as: BillHistoryRemoteDataSource)
class BillHistoryRemoteDataSourceImpl implements BillHistoryRemoteDataSource {
  final SupabaseClient supabase;

  BillHistoryRemoteDataSourceImpl({required this.supabase});

  static const String _tableName = 'bills';

  @override
  Future<HistoricalBillModel> saveBillToHistory(
      HistoricalBillEntity bill) async {
    try {
      // Với giải pháp này, chúng ta không thực sự "lưu" bill vào history
      // mà chỉ trả về bill đã tồn tại trong bảng bills
      // Kiểm tra xem bill có tồn tại hay không
      final response =
          await supabase.from(_tableName).select().eq('id', bill.id).single();

      return HistoricalBillModel.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        // Bill không tồn tại, có thể bill chưa được lưu
        throw ServerException('Bill not found in database. Code: ${e.code}');
      }
      throw ServerException('Code: ${e.code} - ${e.message}');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<HistoricalBillModel>> getBillHistory() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        // Handle case where user is not logged in
        // For history, it's expected user is logged in. Throwing an exception might be appropriate.
        throw ServerException('User not authenticated');
      }

      final response = await supabase
          .from(_tableName)
          .select('''
            *,
            bill_items!inner(*),
            bill_participants!inner(*)
          ''')
          .eq('user_id', userId) // Filter by user ID
          .order('created_at', ascending: false); // Order by newest first

      return response
          .map((item) => HistoricalBillModel.fromJsonWithRelations(item))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException('Code: ${e.code} - ${e.message}');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<HistoricalBillModel> getBillDetailsFromHistory(String billId) async {
    try {
      final response = await supabase.from(_tableName).select('''
            *,
            bill_items!inner(*),
            bill_participants!inner(*)
          ''').eq('id', billId).single();
      return HistoricalBillModel.fromJsonWithRelations(response);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        // "PGRST116: Query result has no rows"
        throw ServerException('Bill not found. Code: ${e.code}');
      }
      throw ServerException('Code: ${e.code} - ${e.message}');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<HistoricalBillModel> updateBillInHistory(
      HistoricalBillEntity bill) async {
    try {
      final model = bill is HistoricalBillModel
          ? bill
          : HistoricalBillModel.fromEntity(bill as HistoricalBillEntity);

      final updateData = model.toJson()
        ..remove('id')
        ..remove('user_id')
        ..remove(
            'created_at'); // ID, user_id, created_at should not be updated directly

      final response = await supabase
          .from(_tableName)
          .update(updateData)
          .eq('id', model.id)
          .select()
          .single();
      return HistoricalBillModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException('Code: ${e.code} - ${e.message}');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> deleteBillFromHistory(String billId) async {
    try {
      await supabase.from(_tableName).delete().eq('id', billId);
    } on PostgrestException catch (e) {
      throw ServerException('Code: ${e.code} - ${e.message}');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
