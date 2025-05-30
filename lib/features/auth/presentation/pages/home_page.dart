import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_split_bill/core/router/app_router.dart'; // Added import for AppRoutes
import 'package:hyper_split_bill/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:hyper_split_bill/features/bill_history/presentation/bloc/bill_history_bloc.dart'; // Import BillHistoryBloc
import 'package:hyper_split_bill/features/settings/presentation/pages/settings_page.dart'; // Import SettingsPage
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import generated localizations
import 'package:provider/provider.dart'; // Import Provider
import 'package:hyper_split_bill/core/providers/theme_provider.dart'; // Import ThemeProvider
import 'package:intl/intl.dart'; // Import for date formatting

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Load bill history when home page is opened
    _loadBillHistory();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload bills when returning to home page
    _loadBillHistory();
  }

  void _loadBillHistory() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final currentState = context.read<BillHistoryBloc>().state;
        print(
            'HomePage: Current BillHistoryBloc state: ${currentState.runtimeType}');

        // Always reload to ensure fresh data
        print('HomePage: Loading bill history...');
        context.read<BillHistoryBloc>().add(LoadBillHistoryEvent());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // Get localizations instance
    // Get user info from AuthBloc state safely
    final authState = context.watch<AuthBloc>().state;
    // Get ThemeProvider instance
    final themeProvider = Provider.of<ThemeProvider>(context);
    // Use the default "Welcome!" text from l10n
    final String welcomeText = l10n.homePageWelcomeDefault;
    String? userEmail; // Make email nullable

    // Get email only if authenticated
    if (authState is AuthAuthenticated) {
      userEmail = authState.user.email; // Get email, might be null
    } else {
      userEmail = null; // No email if not authenticated
    }

    // Determine the correct icon based on the current theme mode
    IconData themeIcon;
    if (themeProvider.themeMode == ThemeMode.light) {
      themeIcon = Icons.dark_mode_outlined; // Show moon to switch to Dark
    } else if (themeProvider.themeMode == ThemeMode.dark) {
      themeIcon = Icons.light_mode_outlined; // Show sun to switch to Light
    } else {
      // System mode
      // In system mode, the icon should reflect the *current* system brightness,
      // and the action will toggle to the *opposite* explicit mode.
      // However, the user wants the icon to show what it will switch TO.
      // So, if system is light, show moon (to switch to dark).
      // If system is dark, show sun (to switch to light).
      final Brightness currentSystemBrightness =
          MediaQuery.of(context).platformBrightness;
      if (currentSystemBrightness == Brightness.dark) {
        themeIcon = Icons
            .light_mode_outlined; // System is Dark, icon to switch to Light
      } else {
        themeIcon =
            Icons.dark_mode_outlined; // System is Light, icon to switch to Dark
      }
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
          // Theme Toggle Icon (placed between Settings and Logout)
          IconButton(
            icon: Icon(themeIcon),
            tooltip:
                l10n.homePageToggleThemeTooltip, // Add localization for tooltip
            onPressed: () {
              if (themeProvider.themeMode == ThemeMode.light) {
                themeProvider.setThemeMode(ThemeMode.dark);
              } else if (themeProvider.themeMode == ThemeMode.dark) {
                themeProvider.setThemeMode(ThemeMode.light);
              } else {
                // ThemeMode.system
                final Brightness currentSystemBrightness =
                    MediaQuery.of(context).platformBrightness;
                if (currentSystemBrightness == Brightness.dark) {
                  // System is Dark, button action is to switch to Light
                  themeProvider.setThemeMode(ThemeMode.light);
                } else {
                  // System is Light, button action is to switch to Dark
                  themeProvider.setThemeMode(ThemeMode.dark);
                }
              }
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
              // Recent Bills Grid or Cat image
              Expanded(
                child: BlocBuilder<BillHistoryBloc, BillHistoryState>(
                  builder: (context, state) {
                    if (state is BillHistoryLoaded && state.bills.isNotEmpty) {
                      // Show recent bills in 2x2 grid
                      final recentBills = state.bills.take(4).toList();
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Text(
                                'Recent Bills',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                            Expanded(
                              child: GridView.builder(
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12.0,
                                  mainAxisSpacing: 12.0,
                                  childAspectRatio: 1,
                                ),
                                itemCount: recentBills.length,
                                itemBuilder: (context, index) {
                                  final bill = recentBills[index];
                                  return Card(
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(8.0),
                                      onTap: () {
                                        context.push(
                                            '${AppRoutes.editBill}/${bill.id}');
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              bill.description ??
                                                  'Unnamed Bill',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                const Icon(Icons.calendar_today,
                                                    size: 12,
                                                    color: Colors.grey),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    DateFormat.yMd()
                                                        .format(bill.billDate),
                                                    style: const TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.grey),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(Icons.save,
                                                    size: 12,
                                                    color: Colors.grey),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    DateFormat.yMd()
                                                        .format(bill.createdAt),
                                                    style: const TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.grey),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const Spacer(),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.green
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                '${NumberFormat('#,##0.00').format(bill.totalAmount)} ${bill.currencyCode}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    } else {
                      // Show message if no bills or loading
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                state is BillHistoryLoading
                                    ? 'Loading your bills...'
                                    : 'No bills yet',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              if (state is! BillHistoryLoading)
                                Text(
                                  'Create your first bill by uploading a receipt!',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Colors.grey[500],
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                            ],
                          ),
                        ),
                      );
                    }
                  },
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
                child: Text('View Full Bill History'),
              ),
              const SizedBox(height: 20), // Add some padding at the bottom
            ],
          ),
        ),
      ),
    );
  }
}
