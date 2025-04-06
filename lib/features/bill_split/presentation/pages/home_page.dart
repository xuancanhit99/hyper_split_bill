import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_split_bill/core/router/app_router.dart'; // Use AppRoutes from router
import 'package:hyper_split_bill/features/auth/presentation/bloc/auth_bloc.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Get user info from AuthBloc state safely
    final authState = context.watch<AuthBloc>().state;
    String userGreeting = 'Welcome!'; // Default greeting
    if (authState is AuthAuthenticated) {
      userGreeting = 'Welcome, ${authState.user.email ?? 'User'}!';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill Splitter'),
        actions: [
          // Only show logout if authenticated
          if (authState is AuthAuthenticated)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Sign Out',
              onPressed: () {
                // Show confirmation dialog before signing out
                showDialog(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Confirm Sign Out'),
                    content: const Text('Are you sure you want to sign out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          // Dispatch sign out event
                          context.read<AuthBloc>().add(AuthSignOutRequested());
                        },
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                userGreeting,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_a_photo_outlined), // Changed icon
                label: const Text('Split a New Bill'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  textStyle: Theme.of(context).textTheme.titleMedium,
                ),
                onPressed: () {
                  // Navigate to the bill upload page using router path/name
                  context.push(AppRoutes.upload);
                },
              ),
              const SizedBox(height: 20),
              // Optional: Button to view history (uncomment when ready)
              // TextButton(
              //   onPressed: () {
              //      context.push(AppRoutes.history);
              //   },
              //   child: const Text('View Bill History'),
              // )
            ],
          ),
        ),
      ),
    );
  }
}