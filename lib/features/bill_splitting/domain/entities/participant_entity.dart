import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart'; // Import for Color

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
  final double? amountOwed; // Amount this participant owes after calculation
  final Color? color; // Color for UI representation (e.g., chips)

  const ParticipantEntity({
    this.id,
    required this.name,
    this.linkedProfileId,
    this.percentage,
    this.isPercentageLocked = false, // Default to false
    this.amountOwed, // Can be null initially
    this.color,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        linkedProfileId,
        percentage,
        isPercentageLocked,
        amountOwed,
        color // Added color to props
      ];

  // Helper for creating a copy with potential modifications
  ParticipantEntity copyWith({
    String? id,
    String? name,
    String? linkedProfileId,
    double? percentage,
    bool? isPercentageLocked,
    double? amountOwed,
    Color? color, // Added color
    bool setLinkedProfileIdToNull = false,
    bool setPercentageToNull = false, // Explicit flag to clear percentage
    bool setAmountOwedToNull = false, // Explicit flag to clear amountOwed
    bool setColorToNull = false, // Explicit flag to clear color
  }) {
    return ParticipantEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      linkedProfileId: setLinkedProfileIdToNull
          ? null
          : (linkedProfileId ?? this.linkedProfileId),
      percentage: setPercentageToNull ? null : (percentage ?? this.percentage),
      isPercentageLocked: isPercentageLocked ?? this.isPercentageLocked,
      amountOwed: setAmountOwedToNull ? null : (amountOwed ?? this.amountOwed),
      color: setColorToNull ? null : (color ?? this.color), // Added color logic
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
      'amount_owed': amountOwed,
      // 'color': color?.value, // Color is not serialized for now
    };
  }
  // Factory method for creating ParticipantEntity from JSON is not strictly needed
  // if we don't store color and assign it at runtime.
  // If needed later, it would look like:
  /*
  factory ParticipantEntity.fromJson(Map<String, dynamic> json) {
    return ParticipantEntity(
      id: json['id'] as String?,
      name: json['name'] as String,
      linkedProfileId: json['linked_profile_id'] as String?,
      percentage: (json['percentage'] as num?)?.toDouble(),
      isPercentageLocked: json['is_percentage_locked'] as bool? ?? false,
      amountOwed: (json['amount_owed'] as num?)?.toDouble(),
      // color: json['color'] != null ? Color(json['color'] as int) : null,
    );
  }
  */
}
