// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:hyper_split_bill/core/router/app_router.dart';
import 'package:hyper_split_bill/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:hyper_split_bill/injection_container.dart'; // Import GetIt instance
import 'package:hyper_split_bill/features/bill_history/presentation/bloc/bill_history_bloc.dart'; // Import BillHistoryBloc
import 'package:flutter_localizations/flutter_localizations.dart'; // Add localization delegates
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import generated localizations
import 'package:hyper_split_bill/core/providers/locale_provider.dart'; // Import LocaleProvider
import 'package:hyper_split_bill/core/providers/theme_provider.dart'; // Import ThemeProvider

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Provide AuthBloc, LocaleProvider and ThemeProvider globally
    return MultiProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => sl<AuthBloc>()..add(AuthCheckRequested()),
        ),
        ChangeNotifierProvider(
          create: (_) => sl<LocaleProvider>(),
        ),
        ChangeNotifierProvider(
          create: (_) => sl<ThemeProvider>(), // Get ThemeProvider from GetIt
        ),
        BlocProvider<BillHistoryBloc>(
          // Add BillHistoryBloc provider
          create: (_) => sl<BillHistoryBloc>(),
        ),
      ],
      child: Builder(builder: (context) {
        // Get the AppRouter instance (which now has AuthBloc) from GetIt
        final appRouter = sl<AppRouter>();
        final localeProvider = Provider.of<LocaleProvider>(context);
        final themeProvider =
            Provider.of<ThemeProvider>(context); // Get ThemeProvider
        return MaterialApp.router(
          debugShowCheckedModeBanner: false, // Add this line
          onGenerateTitle: (context) => AppLocalizations.of(context)!.appName,
          theme: sl<ThemeData>(instanceName: 'lightTheme'),
          darkTheme: sl<ThemeData>(instanceName: 'darkTheme'),
          themeMode:
              themeProvider.themeMode, // Use themeMode from ThemeProvider
          locale: localeProvider.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: appRouter.config(),
        );
      }),
    );
  }
}
