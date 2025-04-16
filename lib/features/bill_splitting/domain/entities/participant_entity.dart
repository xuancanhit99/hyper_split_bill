import 'package:equatable/equatable.dart';

// Represents a participant in a bill split.
class ParticipantEntity extends Equatable {
  final String?
      id; // Optional: ID if stored separately, null for new participants
  final String name;
  final String? linkedProfileId; // Optional: Link to a user profile in the app

  const ParticipantEntity({
    this.id,
    required this.name,
    this.linkedProfileId,
  });

  @override
  List<Object?> get props => [id, name, linkedProfileId];

  // Helper for creating a copy with potential modifications
  ParticipantEntity copyWith({
    String? id,
    String? name,
    String? linkedProfileId, // Allow clearing the link
    bool setLinkedProfileIdToNull = false, // Explicit flag to set null
  }) {
    return ParticipantEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      linkedProfileId: setLinkedProfileIdToNull
          ? null
          : (linkedProfileId ?? this.linkedProfileId),
    );
  }

  // Method to convert ParticipantEntity to a JSON map
  Map<String, dynamic> toJson() {
    return {
      // 'id': id, // Usually not needed when sending data *to* backend
      'name': name,
      'linked_profile_id': linkedProfileId,
    };
  }
}
