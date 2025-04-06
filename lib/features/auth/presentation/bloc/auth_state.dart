// lib/features/auth/presentation/bloc/auth_state.dart
part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

// Initial state before checking
class AuthInitial extends AuthState {}

// When checking auth status or performing login/signup/logout
class AuthLoading extends AuthState {}

// User is logged in
class AuthAuthenticated extends AuthState {
  final User user; // Expose Supabase User object directly

  const AuthAuthenticated(this.user);

  @override
  List<Object> get props => [user];
}

// User is not logged in
class AuthUnauthenticated extends AuthState {}

// User has requested a password reset
class AuthPasswordResetEmailSent extends AuthState {}

// An error occurred during an auth operation
class AuthFailure extends AuthState {
  final String message;
  const AuthFailure(this.message);

  @override
  List<Object> get props => [message];
}