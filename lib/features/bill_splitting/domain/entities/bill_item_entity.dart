import 'package:equatable/equatable.dart';

// Represents a single item listed on a bill.
class BillItemEntity extends Equatable {
  final String? id; // Optional: ID if stored separately, null for new items
  final String description;
  final int quantity;
  final double unitPrice; // Price per single unit
  final double
      totalPrice; // Total price for this line item (quantity * unitPrice)

  const BillItemEntity({
    this.id,
    required this.description,
    this.quantity = 1, // Default quantity to 1
    required this.unitPrice,
    required this.totalPrice,
  });

  @override
  List<Object?> get props => [id, description, quantity, unitPrice, totalPrice];

  // Helper for creating a copy with potential modifications
  BillItemEntity copyWith({
    String? id,
    String? description,
    int? quantity,
    double? unitPrice,
    double? totalPrice,
  }) {
    return BillItemEntity(
      id: id ?? this.id,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
    );
  }

  // Method to convert BillItemEntity to a JSON map
  Map<String, dynamic> toJson() {
    return {
      // 'id': id, // Usually not needed when sending data *to* backend unless updating
      'description': description,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
    };
  }
}
