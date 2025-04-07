// lib/injection_container.dart
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:hyper_split_bill/core/theme/app_theme.dart';
import 'package:hyper_split_bill/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:hyper_split_bill/core/router/app_router.dart';
import 'package:hyper_split_bill/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:hyper_split_bill/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:hyper_split_bill/features/auth/domain/repositories/auth_repository.dart';
import 'package:hyper_split_bill/core/config/app_config.dart';

import 'injection_container.config.dart';

final sl = GetIt.instance;

@InjectableInit()
Future<void> configureDependencies() async {

  sl.init();

  // Register external dependencies first
  _registerExternalDependencies();


  // Register manual dependencies that might not work with @injectable
  _registerThemes();

  // Register AppRouter after AuthBloc is available
  sl.registerLazySingleton(() => AppRouter(sl<AuthBloc>()));
}


void _registerExternalDependencies() {
  // Register Supabase client - this must be available via GetIt for other dependencies
  sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);
  sl.registerLazySingleton(() => http.Client());
}

void _registerThemes() {
  sl.registerLazySingleton<ThemeData>(
        () => AppTheme.lightTheme,
    instanceName: 'lightTheme',
  );
  sl.registerLazySingleton<ThemeData>(
        () => AppTheme.darkTheme,
    instanceName: 'darkTheme',
  );
}