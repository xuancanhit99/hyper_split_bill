// lib/core/router/app_router.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_split_bill/features/auth/presentation/bloc/auth_bloc.dart'; // Import AuthBloc
import 'package:hyper_split_bill/features/auth/presentation/pages/auth_page.dart';

import 'package:hyper_split_bill/features/auth/presentation/pages/home_page.dart';
import 'package:hyper_split_bill/features/bill_splitting/presentation/pages/bill_upload_page.dart'; // Import upload page
import 'package:hyper_split_bill/features/bill_splitting/presentation/pages/image_crop_page.dart';
import 'package:hyper_split_bill/features/bill_splitting/presentation/pages/bill_edit_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Import BlocProvider
import 'package:hyper_split_bill/features/bill_splitting/presentation/bloc/bill_splitting_bloc.dart'; // Import the Bloc
import 'package:hyper_split_bill/injection_container.dart'; // Import sl
// Removed import for reset_password_page.dart

// --- Define Route Paths ---
class AppRoutes {
  static const splash = '/splash'; // Optional loading screen
  static const login = '/login';
  static const signup = '/signup'; // Added signup path
  static const home = '/';
  static const upload = '/upload'; // Added route
  static const history = '/history'; // Added route
  static const cropImage = '/crop-image'; // Added route for image cropping
  static const editBill = '/edit-bill'; // Added route for editing bill details
  static const resetPassword =
      '/reset-password'; // Path kept for potential future use, but route removed
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
          // Use builder for LoginPage as it doesn't need BillSplittingBloc directly
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
        // Bill Splitting Feature Routes (Authenticated)
        GoRoute(
          path: AppRoutes.upload,
          name: AppRoutes.upload,
          // Provide BillSplittingBloc to the route and its descendants
          pageBuilder: (context, state) => MaterialPage(
            key: state.pageKey, // Important for state preservation if needed
            child: BlocProvider.value(
              value: sl<BillSplittingBloc>(), // Provide the singleton instance
              child: const BillUploadPage(),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.cropImage,
          name: AppRoutes.cropImage,
          // Crop page might not need the Bloc directly, but subsequent pages will
          // If it needed the bloc, we would use pageBuilder here too.
          builder: (context, state) {
            final imagePath = state.extra as String?;
            if (imagePath == null) {
              // Redirect immediately if possible, avoid building placeholder
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.go(AppRoutes.upload);
              });
              return const Scaffold(
                  body: Center(child: Text("Error: Image path missing")));
            }
            return ImageCropPage(imagePath: imagePath);
          },
        ),
        GoRoute(
          path: AppRoutes.editBill,
          name: AppRoutes.editBill,
          // Provide BillSplittingBloc to the route and its descendants
          pageBuilder: (context, state) {
            final ocrResult = state.extra as String?;
            if (ocrResult == null) {
              // Redirect immediately if possible
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.go(AppRoutes.upload);
              });
              return const MaterialPage(
                  child: Scaffold(
                      body: Center(child: Text("Error: OCR result missing"))));
            }
            return MaterialPage(
              key: state.pageKey,
              child: BlocProvider.value(
                value:
                    sl<BillSplittingBloc>(), // Provide the singleton instance
                child: BillEditPage(ocrResult: ocrResult),
              ),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.history,
          name: AppRoutes.history,
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('History Page Placeholder')),
          ), // Placeholder
        ),
        // Removed GoRoute for resetPassword
      ],

      // --- REDIRECT LOGIC ---
      redirect: (BuildContext context, GoRouterState state) {
        final currentState = authBloc.state; // Get current Bloc state
        final loggingIn = state.matchedLocation == AppRoutes.login;
        final signingUp = state.matchedLocation == AppRoutes.signup;
        // Removed resettingPassword check
        final isPublicRoute =
            loggingIn || signingUp; // Only login and signup are public now

        // Don't redirect during initial check or if already on a public route when unauthenticated
        if (currentState is AuthInitial || currentState is AuthLoading) {
          return null; // Stay put while checking
        }

        final isAuthenticated = currentState is AuthAuthenticated;

        // If authenticated and trying to access login/signup, redirect to home
        if (isAuthenticated && isPublicRoute) {
          debugPrint(
              "Redirecting authenticated user from public route to home");
          return AppRoutes.home;
        }

        // If unauthenticated and trying to access a protected route, redirect to login
        if (!isAuthenticated && !isPublicRoute) {
          // Check if the target route is protected (add more protected routes here)
          final isProtected = state.matchedLocation == AppRoutes.home ||
              state.matchedLocation == AppRoutes.upload ||
              state.matchedLocation == AppRoutes.cropImage ||
              state.matchedLocation == AppRoutes.editBill ||
              state.matchedLocation == AppRoutes.history;
          if (isProtected) {
            debugPrint(
                "Redirecting unauthenticated user to login from ${state.matchedLocation}");
            return AppRoutes.login;
          }
        }

        // No redirect needed
        return null;
      },
      errorBuilder: (context, state) => Scaffold(
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
