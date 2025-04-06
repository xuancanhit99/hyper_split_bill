// lib/features/auth/domain/entities/user_entity.dart
import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String? email; // Supabase user might have email

  const UserEntity({required this.id, this.email});

  @override
  List<Object?> get props => [id, email];
}