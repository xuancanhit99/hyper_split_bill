// lib/features/auth/presentation/bloc/auth_bloc.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Using Supabase User directly
import 'package:hyper_split_bill/features/auth/domain/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

@injectable // Register for DI (usually as factory)
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  StreamSubscription<User?>? _authStateSubscription;

  AuthBloc(this._authRepository) : super(AuthInitial()) {
    // Listen to auth state changes immediately
    _authStateSubscription = _authRepository.authStateChanges.listen(
          (user) => add(_AuthUserChanged(user)), // Add internal event on change
    );

    // Register event handlers
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthSignInRequested>(_onSignInRequested);
    on<AuthSignUpRequested>(_onSignUpRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
    on<_AuthUserChanged>(_onAuthUserChanged);
    on<AuthRecoverPasswordRequested>(_onRecoverPasswordRequested); // Register new handler
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel(); // IMPORTANT: Cancel subscription
    return super.close();
  }

  // Handler for checking initial auth status
  Future<void> _onAuthCheckRequested(
      AuthCheckRequested event, Emitter<AuthState> emit) async {
    // No need to emit loading here, stream handles initial state
    final result = await _authRepository.getCurrentUser();
    result.fold(
          (failure) => emit(AuthFailure(failure.message)), // Should ideally not fail here
          (user) => emit(user != null ? AuthAuthenticated(user) : AuthUnauthenticated()),
    );
    // If already authenticated/unauthenticated by the stream, this might be redundant
    // but ensures initial state is set correctly if stream is slow.
  }

  // Handler for internal user change events from the stream
  void _onAuthUserChanged(_AuthUserChanged event, Emitter<AuthState> emit) {
    print("Auth State Changed: ${event.user?.email ?? 'Logged Out'}");
    // If user logs in while success message is shown, transition to authenticated
    emit(event.user != null ? AuthAuthenticated(event.user!) : AuthUnauthenticated());
  }


  // Handler for Sign In attempts
  Future<void> _onSignInRequested(
      AuthSignInRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await _authRepository.signInWithPassword(
      email: event.email,
      password: event.password,
    );
    result.fold(
            (failure) => emit(AuthFailure(failure.message)),
            (user) {
          // Don't emit Authenticated here directly, let the _AuthUserChanged handler do it
          // This avoids potential race conditions if the stream updates quickly.
          // If sign-in is successful, the stream *will* emit the new user.
          // If the stream is reliable, we might not even need to emit anything here on success.
          // However, if there's a noticeable delay, emitting AuthLoading might feel incomplete.
          // Let's trust the stream for now. If issues arise, reconsider emitting Authenticated here.
          print("Sign In successful for ${user.email}, waiting for stream update.");
        }
    );
    // Ensure state isn't stuck in Loading if stream doesn't update immediately after error
    if (state is AuthLoading && result.isLeft()) {
      result.fold(
            (failure) => emit(AuthFailure(failure.message)),
            (_) {}, // Should not happen if isLeft() is true
      );
    } else if (state is AuthLoading && result.isRight() && _authRepository.currentUser != null) {
      // If somehow the stream hasn't fired but login succeeded and user is available sync
      emit(AuthAuthenticated(_authRepository.currentUser!));
    } else if (state is AuthLoading && result.isRight() && _authRepository.currentUser == null) {
      // This case shouldn't happen with successful login, maybe emit unauthenticated?
      emit(AuthUnauthenticated());
    }
  }

  // Handler for Sign Up attempts
  Future<void> _onSignUpRequested(
      AuthSignUpRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await _authRepository.signUpWithPassword(
      email: event.email,
      password: event.password,
    );
    result.fold(
            (failure) => emit(AuthFailure(failure.message)),
            (user) {
          // Sign up might require email verification. The user object exists,
          // but session might be null. `onAuthStateChange` handles this.
          // If email verification is NOT enabled, this should trigger AuthAuthenticated via stream.
          // If email verification IS enabled, user stays technically unauthenticated until verification.
          // We might need a different state like AuthVerificationPending.
          // For now, assume no email verification or let stream handle it.
          print("Sign Up successful for ${user.email}, waiting for stream update.");
          // Check if email verification is needed (can check user.emailConfirmedAt == null)
          // if(user.emailConfirmedAt == null && user.session == null) { emit(AuthVerificationPending()); } // Example
        }
    );
    // Handle loading state similar to SignIn
    if (state is AuthLoading && result.isLeft()) {
      result.fold(
            (failure) => emit(AuthFailure(failure.message)),
            (_) {},
      );
    } // No automatic emit Authenticated on sign up, usually needs verification or triggers stream.
  }

  Future<void> _onRecoverPasswordRequested(
      AuthRecoverPasswordRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading()); // Show loading
    final result = await _authRepository.recoverPassword(event.email);
    result.fold(
          (failure) => emit(AuthFailure(failure.message)), // Emit failure on error
          (_) => emit(AuthPasswordResetEmailSent()), // Emit success state
    );
    // Transition back from success/failure state after a delay? Or let UI handle it.
    // For simplicity, we can just stay in AuthPasswordResetEmailSent/AuthFailure until next action.
  }

  // Handler for Sign Out attempts
  Future<void> _onSignOutRequested(
      AuthSignOutRequested event, Emitter<AuthState> emit) async {
    // Optimistic update: Assume signout works locally first for faster UI feedback
    // emit(AuthUnauthenticated()); // Or emit Loading first for consistency
    emit(AuthLoading());
    final result = await _authRepository.signOut();
    result.fold(
            (failure) {
          // If signout failed, revert state? Maybe just show error.
          // The stream should still reflect the actual state.
          print("Sign Out failed: ${failure.message}");
          // Re-check current user and emit appropriate state
          final currentUser = _authRepository.currentUser;
          emit(currentUser != null ? AuthAuthenticated(currentUser) : AuthUnauthenticated());
          // Then show error message on top
          emit(AuthFailure(failure.message)); // This might overwrite the state above, maybe use a separate mechanism for transient errors
        },
            (_) {
          // Success: Stream should emit null user, triggering AuthUnauthenticated via _AuthUserChanged
          print("Sign Out successful, waiting for stream update.");
        }
    );
    // Handle loading state if stream is slow
    if (state is AuthLoading && result.isRight()) {
      emit(AuthUnauthenticated());
    }
  }
}