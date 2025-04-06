// lib/features/auth/data/datasources/auth_remote_data_source.dart
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hyper_split_bill/core/error/exceptions.dart';

abstract class AuthRemoteDataSource {
  User? get currentUser;
  Stream<User?> get authStateChanges;

  Future<User> signInWithPassword({
    required String email,
    required String password,
  });

  Future<User> signUpWithPassword({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  });

  Future<void> recoverPassword(String email);

  Future<void> signOut();
}

@LazySingleton(as: AuthRemoteDataSource)
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient _supabaseClient;

  AuthRemoteDataSourceImpl(this._supabaseClient);

  @override
  User? get currentUser => _supabaseClient.auth.currentUser;

  @override
  Stream<User?> get authStateChanges => _supabaseClient.auth.onAuthStateChange
      .map((event) => event.session?.user);

  @override
  Future<User> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final response = await _supabaseClient.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception('Failed to sign in');
    }

    return response.user!;
  }

  @override
  Future<User> signUpWithPassword({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    final response = await _supabaseClient.auth.signUp(
      email: email,
      password: password,
      data: data,
    );

    if (response.user == null) {
      throw Exception('Failed to sign up');
    }

    return response.user!;
  }

  @override
  Future<void> recoverPassword(String email) async {
    try {
      // Use the email redirect URL configured in your Supabase Auth settings
      await _supabaseClient.auth.resetPasswordForEmail(email);
      // Note: You might need to configure redirectTo in Supabase project settings
      // await _supabaseClient.auth.resetPasswordForEmail(email, redirectTo: 'your-app://reset-password');
    } on AuthException catch (e) {
      print("Supabase RecoverPassword Error: ${e.message}");
      throw AuthServerException(e.message); // Throw custom exception
    } catch (e) {
      print("Unknown RecoverPassword Error: $e");
      throw ServerException('An unexpected error occurred during password recovery.');
    }
  }

  @override
  Future<void> signOut() async {
    await _supabaseClient.auth.signOut();
  }
}