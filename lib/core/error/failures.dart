// lib/core/error/failures.dart
import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

// General failures
class ServerFailure extends Failure {
  const ServerFailure(String message) : super(message);
}

class CacheFailure extends Failure {
  const CacheFailure(String message) : super(message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(String message) : super(message);
}

// Specific Auth Failures can be added if needed, mapping from Supabase errors
class AuthCredentialsFailure extends Failure {
  const AuthCredentialsFailure(String message) : super(message);
}

class AuthServerFailure extends Failure {
  const AuthServerFailure(String message) : super(message);
}