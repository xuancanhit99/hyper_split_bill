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
    // Use the default "Welcome!" text from l10n
    final String welcomeText = l10n.homePageWelcomeDefault;
    String? userEmail; // Make email nullable

    // Get email only if authenticated
    if (authState is AuthAuthenticated) {
      userEmail = authState.user.email; // Get email, might be null
    } else {
      userEmail = null; // No email if not authenticated
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch, // Stretch children horizontally
            children: [
              // Welcome message and email top-left
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.only(
                      bottom: 20.0), // Add some space below
                  child: Column(
                    // Use Column for vertical layout
                    crossAxisAlignment:
                        CrossAxisAlignment.start, // Align text left
                    children: [
                      Row(
                        // Use Row for icon and welcome text
                        mainAxisSize:
                            MainAxisSize.min, // Prevent Row from expanding
                        children: [
                          const Icon(Icons.waving_hand, size: 20.0), // Add icon
                          const SizedBox(
                              width: 8.0), // Space between icon and text
                          Text(
                            welcomeText, // Display only the welcome part
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold, // Make it bold
                                ),
                          ),
                        ],
                      ),
                      if (userEmail != null) // Only show email if available
                        Padding(
                          padding: const EdgeInsets.only(
                              top: 4.0), // Space above email
                          child: Text(
                            userEmail, // Display email on new line
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge, // Larger style for email
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Cat image in the center (expanded to take available space)
              Expanded(
                child: Center(
                  // Center the image within the Expanded space
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0), // Add vertical padding
                    child: Image.asset(
                      'assets/images/A-Cat-With-Bill.png', // Assuming this path
                      height: 500, // Adjust height as needed
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              // Buttons at the bottom
              ElevatedButton.icon(
                icon: const Icon(Icons.add_a_photo_outlined),
                label: Text(l10n.homePageSplitNewBillButton),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                  textStyle: Theme.of(context).textTheme.titleMedium,
                ),
                onPressed: () {
                  context.push(AppRoutes.upload);
                },
              ),
              const SizedBox(height: 15), // Adjusted spacing
              TextButton(
                onPressed: () {
                  context.push(AppRoutes.history);
                },
                child: Text(l10n.homePageViewHistoryButton),
              ),
              const SizedBox(height: 20), // Add some padding at the bottom
            ],
          ),
        ),
      ),
    );
  }
}
