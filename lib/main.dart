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
    final appConfig = di.sl<AppConfig>();
    await Supabase.initialize(
      url: appConfig.supabaseUrl,
      anonKey: appConfig.supabaseAnonKey,
    );
    await di.configureDependencies();
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
