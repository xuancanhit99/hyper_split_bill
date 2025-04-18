// lib/main.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hyper_split_bill/app.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hyper_split_bill/injection_container.dart' as di;
import 'package:hyper_split_bill/core/config/app_config.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(fileName: ".env");

    // Manually create AppConfig to test its factory method
    final AppConfig appConfig;
    try {
      appConfig = AppConfig.fromEnv();
      debugPrint('AppConfig manually created successfully.');
      debugPrint(
          'Supabase URL from manual config: ${appConfig.supabaseUrl}'); // Example print
    } catch (e) {
      debugPrint('Error manually creating AppConfig: $e');
      // Re-throw or handle as appropriate, maybe show error UI
      throw Exception('Failed to create AppConfig from .env: $e');
    }

    // Now configure GetIt dependencies
    await di.configureDependencies();

    // Initialize Supabase using the manually created config
    await Supabase.initialize(
      url: appConfig.supabaseUrl, // Use manually created instance
      anonKey: appConfig.supabaseAnonKey, // Use manually created instance
    );
    runApp(const MyApp());
  } catch (e) {
    debugPrint('Error initializing app: $e');
    runApp(
      MaterialApp(
        home: Scaffold(body: Center(child: Text('Error initializing app: $e'))),
      ),
    );
  }
}

// Helper to access Supabase client instance easily
final supabase = Supabase.instance.client;
