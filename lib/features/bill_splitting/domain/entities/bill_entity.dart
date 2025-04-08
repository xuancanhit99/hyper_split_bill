import 'package:equatable/equatable.dart';
import 'package:hyper_split_bill/features/bill_splitting/domain/entities/bill_item_entity.dart';
import 'package:hyper_split_bill/features/bill_splitting/domain/entities/participant_entity.dart'; // Import ParticipantEntity

// Represents a single bill to be split.
class BillEntity extends Equatable {
  final String id; // Unique identifier for the bill
  final double totalAmount; // The total amount of the bill
  final DateTime date; // The date the bill was issued
  final String? description; // Optional description or name for the bill
  final String payerUserId; // ID of the user who paid the bill initially
  final List<BillItemEntity>? items; // List of items on the bill
  final List<ParticipantEntity>? participants; // List of participants
  final String? currencyCode; // e.g., "USD", "VND", "RUB"
  // TODO: Add fields for image URL etc. later

  const BillEntity({
    required this.id,
    required this.totalAmount,
    required this.date,
    this.description,
    required this.payerUserId,
    this.items,
    this.participants, // Make participants optional
    this.currencyCode,
  });

  @override
  List<Object?> get props => [
        id,
        totalAmount,
        date,
        description,
        payerUserId,
        items,
        participants,
        currencyCode
      ]; // Add participants to props

  // Optional: Add copyWith method for easier updates
  BillEntity copyWith({
    String? id,
    double? totalAmount,
    DateTime? date,
    String? description,
    String? payerUserId,
    List<BillItemEntity>? items,
    List<ParticipantEntity>? participants,
    String? currencyCode,
  }) {
    return BillEntity(
      id: id ?? this.id,
      totalAmount: totalAmount ?? this.totalAmount,
      date: date ?? this.date,
      description: description ?? this.description,
      payerUserId: payerUserId ?? this.payerUserId,
      items: items ?? this.items,
      participants: participants ?? this.participants,
      currencyCode: currencyCode ?? this.currencyCode,
    );
  }
}
