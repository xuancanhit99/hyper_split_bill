// lib/core/router/app_router.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_split_bill/features/auth/presentation/bloc/auth_bloc.dart'; // Import AuthBloc
import 'package:hyper_split_bill/features/auth/presentation/pages/login_page.dart';
import 'package:hyper_split_bill/features/auth/presentation/pages/signup_page.dart'; // Import SignUpPage

import 'package:hyper_split_bill/features/auth/presentation/pages/home_page.dart';


// --- Define Route Paths ---
class AppRoutes {
  static const splash = '/splash'; // Optional loading screen
  static const login = '/login';
  static const signup = '/signup'; // Added signup path
  static const home = '/';
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
      ],

      // --- REDIRECT LOGIC ---
      redirect: (BuildContext context, GoRouterState state) {
        final currentState = authBloc.state; // Get current Bloc state
        final loggingIn = state.matchedLocation == AppRoutes.login;
        final signingUp = state.matchedLocation == AppRoutes.signup;
        final isPublicRoute =
            loggingIn || signingUp; // Add other public routes here if any

        print(
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
            print("Redirecting authenticated user from public route to home");
            return AppRoutes.home;
          }
        }
        // If unauthenticated:
        else if (currentState is AuthUnauthenticated ||
            currentState is AuthFailure) {
          // If user is NOT on a public route, redirect to login
          if (!isPublicRoute) {
            print("Redirecting unauthenticated user to login");
            return AppRoutes.login;
          }
        }

        // No redirect needed
        print("No redirect needed.");
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
