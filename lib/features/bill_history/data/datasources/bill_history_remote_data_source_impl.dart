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

  static const String _tableName = 'bill_history';

  @override
  Future<HistoricalBillModel> saveBillToHistory(
      HistoricalBillEntity bill) async {
    try {
      // Ensure the entity is converted to a model if it's not already
      final model = bill is HistoricalBillModel
          ? bill
          : HistoricalBillModel.fromEntity(
              bill as HistoricalBillEntity); // Cast to ensure type safety

      final response = await supabase
          .from(_tableName)
          .insert(model.toJson())
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
  Future<List<HistoricalBillModel>> getBillHistory() async {
    try {
      final response = await supabase
          .from(_tableName)
          .select()
          .order('created_at', ascending: false); // Order by newest first
      return response
          .map((item) => HistoricalBillModel.fromJson(item))
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
      final response =
          await supabase.from(_tableName).select().eq('id', billId).single();
      return HistoricalBillModel.fromJson(response);
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

      final response = await supabase
          .from(_tableName)
          .update(model.toJson()
            ..remove('id')
            ..remove('user_id')
            ..remove(
                'created_at')) // ID, user_id, created_at should not be updated directly
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
