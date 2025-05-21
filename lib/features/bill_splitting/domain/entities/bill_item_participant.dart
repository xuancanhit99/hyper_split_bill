import 'package:equatable/equatable.dart';

// Represents a relationship between a bill item and a participant,
// including the weight of their participation
class BillItemParticipant extends Equatable {
  final String participantId; // The ID of the participant
  final int weight; // Weight of participation, default is 1, must be ≥ 1

  const BillItemParticipant({
    required this.participantId,
    this.weight = 1,
  });

  @override
  List<Object?> get props => [participantId, weight];

  // Helper for creating a copy with potential modifications
  BillItemParticipant copyWith({
    String? participantId,
    int? weight,
  }) {
    return BillItemParticipant(
      participantId: participantId ?? this.participantId,
      weight: weight ?? this.weight,
    );
  }

  // Method to convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'participant_id': participantId,
      'weight': weight,
    };
  }

  // Method to create from JSON map
  factory BillItemParticipant.fromJson(Map<String, dynamic> json) {
    return BillItemParticipant(
      participantId: json['participant_id'] as String,
      weight: json['weight'] as int,
    );
  }
}
