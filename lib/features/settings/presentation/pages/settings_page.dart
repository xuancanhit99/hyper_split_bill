import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Added import
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import generated localizations
import 'package:hyper_split_bill/features/auth/presentation/bloc/auth_bloc.dart'; // Added import
import '../../../../core/providers/locale_provider.dart'; // Import LocaleProvider
import '../../../../core/config/settings_service.dart'; // Import SettingsService
import '../../../../core/constants/ai_service_types.dart'; // Import AiServiceType
import '../../../../core/providers/theme_provider.dart'; // Import ThemeProvider
import '../../../../injection_container.dart'; // Import GetIt

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.settingsService, // Inject SettingsService
  });

  final SettingsService settingsService;

  static const String routeName = '/settings'; // Define route name

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late SettingsService _settingsService;
  late AiServiceType _selectedOcrService;
  late AiServiceType _selectedChatService;

  final List<AiServiceType> _availableOcrServices = [
    AiServiceType.gemini,
    AiServiceType.grok,
  ];

  final List<AiServiceType> _availableChatServices = [
    AiServiceType.gemini,
    AiServiceType.grok,
    AiServiceType.gigachat,
  ];

  @override
  void initState() {
    super.initState();
    // Accessing GetIt instance directly
    _settingsService = sl.get<SettingsService>();
    _selectedOcrService = _settingsService.selectedOcrService;
    _selectedChatService = _settingsService.selectedChatService;
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final currentLocale = localeProvider.locale;
    final supportedLocales = localeProvider.supportedLocales;
    final themeProvider =
        Provider.of<ThemeProvider>(context); // Get ThemeProvider
    final localizations = AppLocalizations.of(context)!; // Get localizations

    // Helper to get language name from locale
    String getLanguageName(Locale locale) {
      final localizations = AppLocalizations.of(context)!;
      switch (locale.languageCode) {
        case 'en':
          return localizations.languageEnglish;
        case 'ru':
          return localizations.languageRussian;
        case 'vi':
          return localizations.languageVietnamese;
        default:
          return locale.languageCode.toUpperCase();
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.settingsPageTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          // Changed to Column for explicit layout control
          children: [
            Expanded(
              // Makes the ListView take available space, pushing logout to bottom
              child: ListView(
                // Use ListView for scrollability of settings items
                children: [
                  // Language Setting Section
                  Text(
                    localizations.settingsPageLanguageLabel,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<Locale>(
                    value: currentLocale,
                    isExpanded: true,
                    items: supportedLocales.map((locale) {
                      return DropdownMenuItem<Locale>(
                        value: locale,
                        child: Text(getLanguageName(locale)),
                      );
                    }).toList(),
                    onChanged: (Locale? newLocale) {
                      if (newLocale != null) {
                        localeProvider.setLocale(newLocale);
                      }
                    },
                  ),
                  const SizedBox(height: 24), // Spacing between sections

                  // OCR Service Setting Section
                  Text(
                    localizations.settingsPageOcrServiceLabel,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<AiServiceType>(
                    value: _selectedOcrService,
                    isExpanded: true,
                    items: _availableOcrServices.map((serviceType) {
                      return DropdownMenuItem<AiServiceType>(
                        value: serviceType,
                        child: Text(getServiceTypeName(serviceType)),
                      );
                    }).toList(),
                    onChanged: (AiServiceType? newServiceType) {
                      if (newServiceType != null) {
                        setState(() {
                          _selectedOcrService = newServiceType;
                        });
                        _settingsService.setSelectedOcrService(newServiceType);
                      }
                    },
                  ),
                  const SizedBox(height: 24), // Spacing between sections

                  // Chat Service Setting Section
                  Text(
                    localizations.settingsPageChatServiceLabel,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<AiServiceType>(
                    value: _selectedChatService,
                    isExpanded: true,
                    items: _availableChatServices.map((serviceType) {
                      return DropdownMenuItem<AiServiceType>(
                        value: serviceType,
                        child: Text(getServiceTypeName(serviceType)),
                      );
                    }).toList(),
                    onChanged: (AiServiceType? newServiceType) {
                      if (newServiceType != null) {
                        setState(() {
                          _selectedChatService = newServiceType;
                        });
                        _settingsService.setSelectedChatService(newServiceType);
                      }
                    },
                  ),
                  // Removed SizedBox before logout button to ensure it's at the very bottom of the Column
                ],
              ),
            ),
            // Logout Button Section - Placed outside Expanded ListView, at the bottom of Column
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                if (state is AuthAuthenticated) {
                  return Padding(
                    padding: const EdgeInsets.only(
                        top: 24.0), // Add some space above the button
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.logout),
                      label: Text(localizations
                          .settingsPageSignOutButton), // Use specific key for settings page
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        foregroundColor: Theme.of(context).colorScheme.onError,
                        minimumSize: const Size(
                            double.infinity, 48), // Make button wider
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: Text(localizations
                                .homePageSignOutDialogTitle), // Reusing existing key
                            content: Text(localizations
                                .homePageSignOutDialogContent), // Reusing existing key
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(),
                                child: Text(localizations
                                    .buttonCancel), // Reusing existing key
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(dialogContext).pop();
                                  context
                                      .read<AuthBloc>()
                                      .add(AuthSignOutRequested());
                                },
                                child: Text(localizations
                                    .homePageSignOutDialogConfirmButton), // Reusing existing key
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                }
                return const SizedBox
                    .shrink(); // Return empty if not authenticated
              },
            ),
            const SizedBox(height: 36), // Add padding at the bottom
          ],
        ),
      ),
    );
  }

  // Helper function to get user-friendly service name
  String getServiceTypeName(AiServiceType serviceType) {
    // Ensure context is available. Since this is a method of _SettingsPageState,
    // 'context' is implicitly available if called from 'build' or similar lifecycle methods.
    // However, to be safe and explicit, especially if this method could be called from elsewhere,
    // it's better to pass context if needed, or ensure it's only called where context is valid.
    // For now, assuming it's called in contexts where 'this.context' is valid.
    final localizations = AppLocalizations.of(context)!;
    switch (serviceType) {
      case AiServiceType.gemini:
        return localizations.aiServiceGemini;
      case AiServiceType.grok:
        return localizations.aiServiceGrok;
      case AiServiceType.gigachat:
        return localizations.aiServiceGigaChat;
      default:
        // Fallback for any new service types not yet localized
        return serviceType.toString().split('.').last;
    }
  }
}
