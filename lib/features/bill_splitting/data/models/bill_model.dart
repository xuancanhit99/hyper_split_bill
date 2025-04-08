import 'package:hyper_split_bill/features/bill_splitting/domain/entities/bill_entity.dart';

// Data Transfer Object (DTO) or Model for Bill data, used in the Data layer.
// Extends BillEntity to inherit fields and Equatable implementation.
class BillModel extends BillEntity {
  const BillModel({
    required super.id,
    required super.totalAmount,
    required super.date,
    super.description,
    required super.payerUserId,
    super.currencyCode,
    // Add any additional fields specific to the data source if needed
  });

  // Factory constructor to create a BillModel from a Map (e.g., from Supabase)
  factory BillModel.fromMap(Map<String, dynamic> map) {
    // Basic validation or default values can be added here
    if (map['id'] == null ||
        map['total_amount'] == null ||
        map['bill_date'] == null ||
        map['user_id'] == null) {
      // Consider throwing a specific ParsingException or returning a default/error state
      // For now, let's throw an ArgumentError for missing required fields
      throw ArgumentError('Missing required fields in BillModel.fromMap: $map');
    }

    return BillModel(
      id: map['id'] as String,
      // Ensure numeric types are parsed correctly
      totalAmount: (map['total_amount'] as num).toDouble(),
      date: DateTime.parse(map['bill_date'] as String),
      description: map['description'] as String?,
      payerUserId: map['user_id']
          as String, // Assuming 'user_id' from DB maps to payerUserId
      currencyCode: map['currency_code'] as String?, // Map currency_code
      // TODO: Map other fields like subtotal, tax, tip, discount, image_url, ocr_extracted_text
    );
  }

  // Method to convert BillModel instance to a Map (e.g., for sending to Supabase)
  Map<String, dynamic> toMap() {
    return {
      // 'id' is usually generated by the DB, so often excluded on insert/update
      // but might be needed for updates. Handle accordingly in the repository.
      // 'id': id,
      'user_id': payerUserId, // Map back to the database column name
      'total_amount': totalAmount,
      'bill_date': date
          .toIso8601String()
          .split('T')
          .first, // Format as YYYY-MM-DD for 'date' type
      'description': description,
      'currency_code': currencyCode, // Map currency_code back
      // TODO: Map other fields back to DB columns
      // 'subtotal_amount': subtotalAmount,
      // 'tax_amount': taxAmount,
      // 'tip_amount': tipAmount,
      // 'discount_amount': discountAmount,
      // 'image_url': imageUrl,
      // 'ocr_extracted_text': ocrExtractedText,
      // 'created_at' is usually handled by the DB default
    };
  }

  // Optional: Convert BillEntity to BillModel (useful in repository implementation)
  factory BillModel.fromEntity(BillEntity entity) {
    return BillModel(
      id: entity.id,
      totalAmount: entity.totalAmount,
      date: entity.date,
      description: entity.description,
      payerUserId: entity.payerUserId,
      currencyCode: entity.currencyCode,
    );
  }
}
