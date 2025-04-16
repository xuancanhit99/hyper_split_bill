import 'package:equatable/equatable.dart';

// Represents a participant in a bill split.
class ParticipantEntity extends Equatable {
  final String?
      id; // Optional: ID if stored separately, null for new participants
  final String name;
  final String? linkedProfileId; // Optional: Link to a user profile in the app
  final double?
      percentage; // Optional: Percentage of the bill this participant pays
  final bool
      isPercentageLocked; // Whether the user has manually set and locked this percentage

  const ParticipantEntity({
    this.id,
    required this.name,
    this.linkedProfileId,
    this.percentage,
    this.isPercentageLocked = false, // Default to false
  });

  @override
  List<Object?> get props =>
      [id, name, linkedProfileId, percentage, isPercentageLocked];

  // Helper for creating a copy with potential modifications
  ParticipantEntity copyWith({
    String? id,
    String? name,
    String? linkedProfileId,
    double? percentage,
    bool? isPercentageLocked,
    bool setLinkedProfileIdToNull = false,
    bool setPercentageToNull = false, // Explicit flag to clear percentage
  }) {
    return ParticipantEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      linkedProfileId: setLinkedProfileIdToNull
          ? null
          : (linkedProfileId ?? this.linkedProfileId),
      percentage: setPercentageToNull ? null : (percentage ?? this.percentage),
      isPercentageLocked: isPercentageLocked ?? this.isPercentageLocked,
    );
  }

  // Method to convert ParticipantEntity to a JSON map
  Map<String, dynamic> toJson() {
    return {
      // 'id': id,
      'name': name,
      'linked_profile_id': linkedProfileId,
      'percentage': percentage,
      'is_percentage_locked': isPercentageLocked,
    };
  }
}
