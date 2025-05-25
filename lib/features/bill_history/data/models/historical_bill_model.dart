import 'package:hyper_split_bill/features/bill_history/domain/entities/historical_bill_entity.dart';

class HistoricalBillModel extends HistoricalBillEntity {
  const HistoricalBillModel({
    required super.id,
    required super.userId,
    super.description,
    required super.totalAmount,
    required super.currencyCode,
    required super.billDate,
    super.rawOcrJson,
    required super.finalBillDataJson,
    required super.createdAt,
    required super.updatedAt,
  });

  factory HistoricalBillModel.fromJson(Map<String, dynamic> json) {
    return HistoricalBillModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      description: json['description'] as String?,
      totalAmount: (json['total_amount'] as num).toDouble(),
      currencyCode: json['currency_code'] as String,
      billDate: DateTime.parse(json['bill_date'] as String),
      rawOcrJson: json['raw_ocr_json'] as Map<String, dynamic>?,
      finalBillDataJson: json['final_bill_data_json'] as Map<String, dynamic>,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'description': description,
      'total_amount': totalAmount,
      'currency_code': currencyCode,
      'bill_date': billDate
          .toIso8601String()
          .substring(0, 10), // Format YYYY-MM-DD for DATE type
      'raw_ocr_json': rawOcrJson,
      'final_bill_data_json': finalBillDataJson,
      // 'created_at' and 'updated_at' are typically handled by the database
    };
  }

  // Optional: if you need to convert from Entity to Model
  factory HistoricalBillModel.fromEntity(HistoricalBillEntity entity) {
    return HistoricalBillModel(
      id: entity.id,
      userId: entity.userId,
      description: entity.description,
      totalAmount: entity.totalAmount,
      currencyCode: entity.currencyCode,
      billDate: entity.billDate,
      rawOcrJson: entity.rawOcrJson,
      finalBillDataJson: entity.finalBillDataJson,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
