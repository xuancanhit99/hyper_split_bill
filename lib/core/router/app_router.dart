// lib/core/router/app_router.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_split_bill/features/auth/presentation/bloc/auth_bloc.dart'; // Import AuthBloc
import 'package:hyper_split_bill/features/auth/presentation/pages/login_page.dart';

import 'package:hyper_split_bill/features/auth/presentation/pages/home_page.dart';
import 'package:hyper_split_bill/features/auth/presentation/pages/reset_password_page.dart'; // Added import

// --- Define Route Paths ---
class AppRoutes {
  static const splash = '/splash'; // Optional loading screen
  static const login = '/login';
  static const signup = '/signup'; // Added signup path
  static const home = '/';
  static const upload = '/upload'; // Added route
  static const history = '/history'; // Added route
  static const resetPassword =
      '/reset-password'; // Added route for password reset page
}

class AppRouter {
  final AuthBloc authBloc; // Receive AuthBloc instance

  AppRouter(this.authBloc); // Constructor

  static String get loginPath => AppRoutes.login;
  static String get signupPath => AppRoutes.signup;

  GoRouter config() {
    return GoRouter(
      // Start at home, redirect logic will handle auth state
      initialLocation: AppRoutes.home,
      // Refresh stream listens to AuthBloc state changes for automatic redirection
      refreshListenable: GoRouterRefreshStream(authBloc.stream),
      routes: [
        // Public routes
        GoRoute(
          path: AppRoutes.login,
          name: AppRoutes.login, // Optional: Use names for navigation
          builder: (context, state) => const LoginPage(),
        ),
        // GoRoute(
        //   path: AppRoutes.signup,
        //   name: AppRoutes.signup,
        //   builder: (context, state) => const SignUpPage(),
        // ),
        // Authenticated routes (add more here)
        GoRoute(
          path: AppRoutes.home,
          name: AppRoutes.home,
          builder: (context, state) => const HomePage(),
        ),
        // TODO: Replace with actual page widgets once created
        GoRoute(
          path: AppRoutes.upload,
          name: AppRoutes.upload,
          builder:
              (context, state) => const Scaffold(
                body: Center(child: Text('Upload Page Placeholder')),
              ), // Placeholder
        ),
        GoRoute(
          path: AppRoutes.history,
          name: AppRoutes.history,
          builder:
              (context, state) => const Scaffold(
                body: Center(child: Text('History Page Placeholder')),
              ), // Placeholder
        ),
        GoRoute(
          path: AppRoutes.resetPassword,
          name: AppRoutes.resetPassword,
          // This page is typically reached via deep link
          builder: (context, state) {
            // Potentially extract token/params from state.uri if needed,
            // but SupaResetPassword usually handles it automatically via session recovery.
            // Ensure ResetPasswordPage is imported.
            // Assuming ResetPasswordPage is in:
            // import 'package:hyper_split_bill/features/auth/presentation/pages/reset_password_page.dart';
            // If not, add the import at the top of the file.
            return const ResetPasswordPage();
          },
        ),
      ],

      // --- REDIRECT LOGIC ---
      redirect: (BuildContext context, GoRouterState state) {
        final currentState = authBloc.state; // Get current Bloc state
        final loggingIn = state.matchedLocation == AppRoutes.login;
        final signingUp = state.matchedLocation == AppRoutes.signup;
        final resettingPassword =
            state.matchedLocation ==
            AppRoutes.resetPassword; // Check for reset page
        final isPublicRoute =
            loggingIn ||
            signingUp ||
            resettingPassword; // Add resetPassword as a public-accessible route (via deep link)

        debugPrint(
          "Redirect Check: Current State: ${currentState.runtimeType}, Location: ${state.matchedLocation}, IsPublic: $isPublicRoute",
        ); // Debugging

        // If checking auth state initially, stay put (or show splash)
        if (currentState is AuthInitial || currentState is AuthLoading) {
          // Could redirect to a dedicated splash screen: return AppRoutes.splash;
          return null; // Stay on current route while loading/checking
        }

        // If authenticated:
        if (currentState is AuthAuthenticated) {
          // If user is on login or signup page, redirect to home
          if (isPublicRoute) {
            debugPrint(
              "Redirecting authenticated user from public route to home",
            );
            return AppRoutes.home;
          }
        }
        // If unauthenticated:
        else if (currentState is AuthUnauthenticated ||
            currentState is AuthFailure) {
          // If user is NOT on a public route, redirect to login
          if (!isPublicRoute) {
            debugPrint("Redirecting unauthenticated user to login");
            return AppRoutes.login;
          }
        }

        // No redirect needed
        debugPrint("No redirect needed.");
        return null;
      },
      errorBuilder:
          (context, state) => Scaffold(
            // Basic error page
            body: Center(child: Text('Page not found: ${state.error}')),
          ),
    );
  }
}

// Helper class to trigger GoRouter refresh on Bloc stream changes
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
