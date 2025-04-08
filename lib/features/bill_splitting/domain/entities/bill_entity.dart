import 'package:equatable/equatable.dart';
import 'package:hyper_split_bill/features/bill_splitting/domain/entities/bill_item_entity.dart'; // Import BillItemEntity

// Represents a single bill to be split.
class BillEntity extends Equatable {
  final String id; // Unique identifier for the bill
  final double totalAmount; // The total amount of the bill
  final DateTime date; // The date the bill was issued
  final String? description; // Optional description or name for the bill
  final String payerUserId; // ID of the user who paid the bill initially
  final List<BillItemEntity>? items; // List of items on the bill
  // TODO: Add fields for items, participants, image URL etc. later

  const BillEntity({
    required this.id,
    required this.totalAmount,
    required this.date,
    this.description,
    required this.payerUserId,
    this.items, // Make items optional in constructor
  });

  @override
  List<Object?> get props =>
      [id, totalAmount, date, description, payerUserId, items];

  // Optional: Add copyWith method for easier updates
  BillEntity copyWith({
    String? id,
    double? totalAmount,
    DateTime? date,
    String? description,
    String? payerUserId,
    List<BillItemEntity>? items,
  }) {
    return BillEntity(
      id: id ?? this.id,
      totalAmount: totalAmount ?? this.totalAmount,
      date: date ?? this.date,
      description: description ?? this.description,
      payerUserId: payerUserId ?? this.payerUserId,
      items: items ?? this.items,
    );
  }
}
