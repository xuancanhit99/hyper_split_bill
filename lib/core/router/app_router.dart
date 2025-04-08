// lib/core/router/app_router.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_split_bill/features/auth/presentation/bloc/auth_bloc.dart'; // Import AuthBloc
import 'package:hyper_split_bill/features/auth/presentation/pages/auth_page.dart';

import 'package:hyper_split_bill/features/auth/presentation/pages/home_page.dart';
import 'package:hyper_split_bill/features/bill_splitting/presentation/pages/bill_upload_page.dart'; // Import upload page
import 'package:hyper_split_bill/features/bill_splitting/presentation/pages/image_crop_page.dart'; // Import crop page
import 'package:hyper_split_bill/features/bill_splitting/presentation/pages/bill_edit_page.dart'; // Import edit page
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
          builder: (context, state) =>
              const BillUploadPage(), // Link to the actual page
        ),
        GoRoute(
          path: AppRoutes.cropImage,
          name: AppRoutes.cropImage,
          builder: (context, state) {
            // Extract the image path passed as extra data
            final imagePath = state.extra as String?;
            if (imagePath == null) {
              // Handle error: navigate back or show error page if path is missing
              // For simplicity, redirect back to upload for now
              // Consider a dedicated error page or message
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.go(AppRoutes.upload); // Or show an error
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
          builder: (context, state) {
            // Extract the OCR result text passed as extra data
            final ocrResult = state.extra as String?;
            if (ocrResult == null) {
              // Handle error if OCR result is missing
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context
                    .go(AppRoutes.upload); // Go back to upload if data missing
              });
              return const Scaffold(
                  body: Center(child: Text("Error: OCR result missing")));
            }
            return BillEditPage(ocrResult: ocrResult);
          },
        ),
        GoRoute(
          path: AppRoutes.history,
          name: AppRoutes.history,
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('History Page Placeholder')),
          ), // Placeholder
        ),
        // GoRoute(
        //   path: AppRoutes.resetPassword,
        //   name: AppRoutes.resetPassword,
        //   // This page is typically reached via deep link
        //   builder: (context, state) {
        //     // Potentially extract token/params from state.uri if needed,
        //     // but SupaResetPassword usually handles it automatically via session recovery.
        //     // Ensure ResetPasswordPage is imported.
        //     // Assuming ResetPasswordPage is in:
        //     // import 'package:hyper_split_bill/features/auth/presentation/pages/reset_password_page.dart';
        //     // If not, add the import at the top of the file.
        //     return const ResetPasswordPage();
        //   },
        // ),
      ],

      // --- REDIRECT LOGIC ---
      redirect: (BuildContext context, GoRouterState state) {
        final currentState = authBloc.state; // Get current Bloc state
        final loggingIn = state.matchedLocation == AppRoutes.login;
        final signingUp = state.matchedLocation == AppRoutes.signup;
        // Removed resettingPassword check
        final isPublicRoute =
            loggingIn || signingUp; // Only login and signup are public now

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
