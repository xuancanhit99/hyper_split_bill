import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hyper_split_bill/core/providers/locale_provider.dart'; // Import LocaleProvider
import 'package:hyper_split_bill/core/config/settings_service.dart'; // Import SettingsService
import 'package:hyper_split_bill/core/providers/theme_provider.dart'; // Import ThemeProvider

// This module tells GetIt how to create instances of external dependencies
// that are needed by other injectable classes.
@module
abstract class RegisterModule {
  // Provides the SupabaseClient instance.
  // Assumes Supabase.initialize() has been called before GetIt setup.
  @lazySingleton
  SupabaseClient get supabaseClient => Supabase.instance.client;

  // Provides an http.Client instance.
  @lazySingleton
  http.Client get httpClient => http.Client();

  // Provides the SharedPreferences instance
  @preResolve
  Future<SharedPreferences> get sharedPreferences =>
      SharedPreferences.getInstance();

  // Provides the LocaleProvider instance
  @lazySingleton
  LocaleProvider localeProvider(SharedPreferences sharedPreferences) =>
      LocaleProvider(sharedPreferences);

  // Provides the ThemeProvider instance
  @lazySingleton
  ThemeProvider themeProvider() => ThemeProvider();

  // Provides the SettingsService instance
  @lazySingleton
  SettingsService settingsService(SharedPreferences sharedPreferences) =>
      SettingsService(sharedPreferences);
}
