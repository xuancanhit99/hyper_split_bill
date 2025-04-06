// lib/features/auth/presentation/bloc/auth_event.dart
part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

// Triggered on app start to check current auth status
class AuthCheckRequested extends AuthEvent {}

// Triggered by UI to sign in
class AuthSignInRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthSignInRequested({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

// Triggered by UI to sign up
class AuthSignUpRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthSignUpRequested({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

class AuthRecoverPasswordRequested extends AuthEvent {
  final String email;
  const AuthRecoverPasswordRequested(this.email);

  @override
  List<Object> get props => [email];
}


// Triggered by UI to sign out
class AuthSignOutRequested extends AuthEvent {}

// Internal event triggered by the auth state stream listener
class _AuthUserChanged extends AuthEvent {
  final User? user; // Supabase User object
  const _AuthUserChanged(this.user);

  @override
  List<Object?> get props => [user];
}