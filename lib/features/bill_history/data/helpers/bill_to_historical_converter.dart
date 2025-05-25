import 'package:hyper_split_bill/features/bill_splitting/domain/entities/bill_entity.dart';
import 'package:hyper_split_bill/features/bill_history/domain/entities/historical_bill_entity.dart';

class BillToHistoricalConverter {
  static HistoricalBillEntity convertBillToHistorical(
    BillEntity bill, {
    Map<String, dynamic>? rawOcrJson,
    Map<String, dynamic>? additionalData,
  }) {
    // Tạo finalBillDataJson từ BillEntity
    final finalBillDataJson = {
      'id': bill.id,
      'description': bill.description,
      'total_amount': bill.totalAmount,
      'currency_code': bill.currencyCode,
      'bill_date': bill.date.toIso8601String().split('T').first,
      'user_id': bill.payerUserId,
      'items': bill.items?.map((item) => item.toJson()).toList() ?? [],
      'participants': bill.participants
              ?.map((p) => {
                    'id': p.id,
                    'name': p.name,
                    'amount_owed': p.amountOwed,
                  })
              .toList() ??
          [],
      // Thêm dữ liệu bổ sung nếu có
      if (additionalData != null) ...additionalData,
    };

    return HistoricalBillEntity(
      id: bill.id, // Sử dụng cùng ID với BillEntity
      userId: bill.payerUserId,
      description: bill.description,
      totalAmount: bill.totalAmount,
      currencyCode: bill.currencyCode ?? 'VND',
      billDate: bill.date,
      rawOcrJson: rawOcrJson,
      finalBillDataJson: finalBillDataJson,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
