// lib/features/auth/data/repositories/auth_repository_impl.dart

import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hyper_split_bill/core/error/failures.dart';
import 'package:hyper_split_bill/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:hyper_split_bill/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  User? get currentUser => remoteDataSource.currentUser;

  @override
  Stream<User?> get authStateChanges => remoteDataSource.authStateChanges;

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      final user = await remoteDataSource.getCurrentUser();
      return Right(user);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      final user = await remoteDataSource.signInWithPassword(
        email: email,
        password: password,
      );
      return Right(user);
    } catch (e) {
      return Left(AuthCredentialsFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> signUpWithPassword({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    try {
      final user = await remoteDataSource.signUpWithPassword(
        email: email,
        password: password,
        data: data,
      );
      return Right(user);
    } catch (e) {
      return Left(AuthCredentialsFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await remoteDataSource.signOut();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}