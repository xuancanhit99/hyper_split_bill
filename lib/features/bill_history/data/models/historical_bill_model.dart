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
      currencyCode: json['currency_code'] as String? ?? 'VND',
      billDate: DateTime.parse(json['bill_date'] as String),
      // Dữ liệu OCR có thể null trong bảng bills
      rawOcrJson: json['ocr_extracted_text'] != null
          ? {'text': json['ocr_extracted_text']}
          : null,
      // Tạo finalBillDataJson từ dữ liệu hiện có
      finalBillDataJson: {
        'id': json['id'],
        'description': json['description'],
        'total_amount': json['total_amount'],
        'currency_code': json['currency_code'],
        'bill_date': json['bill_date'],
        'subtotal_amount': json['subtotal_amount'],
        'tax_amount': json['tax_amount'],
        'tip_amount': json['tip_amount'],
        'discount_amount': json['discount_amount'],
        'image_url': json['image_url'],
      },
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  factory HistoricalBillModel.fromJsonWithRelations(Map<String, dynamic> json) {
    // Parse items from bill_items relation
    final List<Map<String, dynamic>> items = [];
    if (json['bill_items'] != null && json['bill_items'] is List) {
      for (var item in json['bill_items']) {
        items.add({
          'id': item['id'],
          'description': item['description'],
          'quantity': item['quantity'],
          'unit_price': item['unit_price'],
          'total_price': item['total_price'],
        });
      }
    }

    // Parse participants from bill_participants relation
    final List<Map<String, dynamic>> participants = [];
    if (json['bill_participants'] != null &&
        json['bill_participants'] is List) {
      for (var participant in json['bill_participants']) {
        participants.add({
          'id': participant['id'],
          'name': participant['name'],
          'amount_owed': participant['amount_owed'],
        });
      }
    }

    return HistoricalBillModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      description: json['description'] as String?,
      totalAmount: (json['total_amount'] as num).toDouble(),
      currencyCode: json['currency_code'] as String? ?? 'VND',
      billDate: DateTime.parse(json['bill_date'] as String),
      // Dữ liệu OCR có thể null trong bảng bills
      rawOcrJson: json['ocr_extracted_text'] != null
          ? {'text': json['ocr_extracted_text']}
          : null,
      // Tạo finalBillDataJson với items và participants
      finalBillDataJson: {
        'id': json['id'],
        'description': json['description'],
        'total_amount': json['total_amount'],
        'currency_code': json['currency_code'],
        'bill_date': json['bill_date'],
        'subtotal_amount': json['subtotal_amount'],
        'tax_amount': json['tax_amount'],
        'tip_amount': json['tip_amount'],
        'discount_amount': json['discount_amount'],
        'image_url': json['image_url'],
        'items': items,
        'participants': participants,
      },
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
      // Lưu raw OCR text vào trường ocr_extracted_text
      'ocr_extracted_text': rawOcrJson != null ? rawOcrJson!['text'] : null,
      // Có thể lưu final_bill_data_json vào một trường JSONB nếu cần
      // Hoặc tách ra thành các trường riêng biệt
      'subtotal_amount': finalBillDataJson['subtotal_amount'],
      'tax_amount': finalBillDataJson['tax_amount'],
      'tip_amount': finalBillDataJson['tip_amount'],
      'discount_amount': finalBillDataJson['discount_amount'],
      'image_url': finalBillDataJson['image_url'],
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
