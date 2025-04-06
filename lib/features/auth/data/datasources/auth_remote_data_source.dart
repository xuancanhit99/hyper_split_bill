// lib/features/auth/data/datasources/auth_remote_data_source.dart
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  Future<void> signOut() async {
    await _supabaseClient.auth.signOut();
  }
}