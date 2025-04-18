import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_split_bill/core/router/app_router.dart'; // Added import for AppRoutes
import 'package:hyper_split_bill/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:hyper_split_bill/features/settings/presentation/pages/settings_page.dart'; // Import SettingsPage
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import generated localizations

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // Get localizations instance
    // Get user info from AuthBloc state safely
    final authState = context.watch<AuthBloc>().state;
    String userGreeting;
    if (authState is AuthAuthenticated) {
      // Use placeholder for user email, provide default if null
      userGreeting = l10n.homePageWelcomeUser(authState.user.email ?? 'User');
    } else {
      userGreeting = l10n.homePageWelcomeDefault;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.homePageTitle),
        actions: [
          // Settings Icon
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: l10n.homePageSettingsTooltip,
            onPressed: () {
              context.push(SettingsPage.routeName);
            },
          ),
          // Only show logout if authenticated
          if (authState is AuthAuthenticated)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: l10n.homePageSignOutTooltip,
              onPressed: () {
                // Show confirmation dialog before signing out
                showDialog(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: Text(l10n.homePageSignOutDialogTitle),
                    content: Text(l10n.homePageSignOutDialogContent),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: Text(l10n.buttonCancel), // Reusing existing key
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          // Dispatch sign out event
                          context.read<AuthBloc>().add(
                                AuthSignOutRequested(),
                              );
                        },
                        child: Text(l10n.homePageSignOutDialogConfirmButton),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: SafeArea(
        // Added SafeArea
        child: Center(
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
                  label: Text(l10n.homePageSplitNewBillButton),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                    textStyle: Theme.of(context).textTheme.titleMedium,
                  ),
                  onPressed: () {
                    // Navigate to the bill upload page using router path/name
                    context.push(AppRoutes.upload); // Uncommented
                  },
                ),
                const SizedBox(height: 20),
                // Optional: Button to view history (uncomment when ready)
                TextButton(
                  // Uncommented
                  onPressed: () {
                    // Uncommented
                    context.push(AppRoutes.history); // Uncommented
                  }, // Uncommented
                  child: Text(l10n.homePageViewHistoryButton), // Uncommented
                ), // Removed comment marker
              ],
            ),
          ),
        ),
      ),
    );
  }
}
