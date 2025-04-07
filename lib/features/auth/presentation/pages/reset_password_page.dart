import 'package:flutter/material.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart'; // Correct import
import 'package:go_router/go_router.dart';
import 'package:hyper_split_bill/core/router/app_router.dart';

class ResetPasswordPage extends StatelessWidget {
  // Potentially receive the access token if needed by your deep link setup
  // final String? accessToken; // Example
  const ResetPasswordPage({super.key /*, this.accessToken */});

  @override
  Widget build(BuildContext context) {
    // Use SupaResetPassword widget
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Password')), // Updated title
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          // --- Use SupaResetPassword ---
          SupaResetPassword(
            // This widget handles the UI for entering the NEW password
            // It internally uses the session fragment from the redirect URL
            // to verify the user before calling `updateUser`.

            // IMPORTANT: The access token from the email link is usually
            // automatically handled by Supabase.initialize when the app
            // resumes from the deep link. SupaResetPassword relies on this
            // session recovery. You don't typically pass the token manually here.
            onSuccess: (UserResponse response) {
              // Receives UserResponse on success
              debugPrint(
                'Password reset successful for user: ${response.user?.id}',
              );
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Password updated successfully! You can now log in.',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              // Navigate back to the login page
              context.go(AppRoutes.login);
            },
            onError: (error) {
              debugPrint('SupaResetPassword Error: $error');
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(
                      error is AuthException
                          ? error.message
                          : 'Failed to update password.',
                    ),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
            },
            // You might need to provide `redirectUrl` if it differs from default setup
            // redirectUrl: 'myapp://login', // Where to go after success/error? Usually handled by context.go above
          ),
        ],
      ),
    );
  }
}
