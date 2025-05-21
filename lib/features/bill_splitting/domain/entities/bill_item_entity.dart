import 'package:equatable/equatable.dart';
import 'package:hyper_split_bill/features/bill_splitting/domain/entities/bill_item_participant.dart';

// Represents a single item listed on a bill.
class BillItemEntity extends Equatable {
  final String? id; // Optional: ID if stored separately, null for new items
  final String description;
  final int quantity;
  final double unitPrice; // Price per single unit
  final double
      totalPrice; // Total price for this line item (quantity * unitPrice)
  final List<String> participantIds; // IDs of participants sharing this item (for backward compatibility)
  final List<BillItemParticipant> participants; // Participants with their weights

  const BillItemEntity({
    this.id,
    required this.description,
    this.quantity = 1, // Default quantity to 1
    required this.unitPrice,
    required this.totalPrice,
    this.participantIds = const [], // Default to an empty list
    this.participants = const [], // Default to an empty list
  });
  @override
  List<Object?> get props =>
      [id, description, quantity, unitPrice, totalPrice, participantIds, participants];

  // Helper for creating a copy with potential modifications
  BillItemEntity copyWith({
    String? id,
    String? description,
    int? quantity,
    double? unitPrice,
    double? totalPrice,
    List<String>? participantIds,
    List<BillItemParticipant>? participants,
  }) {
    return BillItemEntity(
      id: id ?? this.id,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      participantIds: participantIds ?? this.participantIds,
      participants: participants ?? this.participants,
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
      'participant_ids': participantIds,
      'participants': participants.map((p) => p.toJson()).toList(),
    };
  }
  
  // Helper methods to work with weighted participants
  List<String> get weightedParticipantIds => participants.map((p) => p.participantId).toList();
  
  // Get the weight for a specific participant
  int getParticipantWeight(String participantId) {
    final participant = participants.firstWhere(
      (p) => p.participantId == participantId,
      orElse: () => const BillItemParticipant(participantId: '', weight: 1),
    );
    return participant.participantId.isEmpty ? 1 : participant.weight;
  }
  
  // Get total weight of all participants
  int get totalWeight => participants.fold(0, (sum, p) => sum + p.weight);
  
  // Generate participantIds from participants for backward compatibility
  List<String> generateParticipantIds() {
    return participants.map((p) => p.participantId).toList();
  }
  
  // Generate participants from participantIds with default weight of 1
  List<BillItemParticipant> generateParticipants() {
    return participantIds.map((id) => BillItemParticipant(participantId: id, weight: 1)).toList();
  }
}
