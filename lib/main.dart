import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hyper_split_bill/app.dart';
import 'package:hyper_split_bill/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:hyper_split_bill/injection_container.dart'
    as di; // Dependency Injection
import 'package:hyper_split_bill/core/router/app_router.dart'; // Import GoRouter config

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- Initialize Supabase ---
  // Replace with your actual Supabase URL and Anon Key
  // Consider loading these from environment variables for security
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );

  // --- Initialize Dependency Injection ---
  await di.init();

  // --- Run the App ---
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final _appRouter = AppRouter(); // Initialize GoRouter

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Provide AuthBloc globally if needed across multiple features
        BlocProvider<AuthBloc>(
          create:
              (_) =>
                  di.sl<AuthBloc>()
                    ..add(AuthCheckRequested()), // Check auth status on start
        ),
        // Add other global Blocs if necessary
      ],
      child: MaterialApp.router(
        title: 'Bill Splitter App',
        theme: di.sl<ThemeData>(instanceName: 'lightTheme'),
        // Get themes from DI
        darkTheme: di.sl<ThemeData>(instanceName: 'darkTheme'),
        themeMode: ThemeMode.system,
        // Or allow user selection
        routerConfig: _appRouter.config(), // Use GoRouter configuration
      ),
    );
  }
}

// Helper to access Supabase client instance easily
final supabase = Supabase.instance.client;
