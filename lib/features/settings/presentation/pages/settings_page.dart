import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import generated localizations
import '../../../../core/providers/locale_provider.dart'; // Import LocaleProvider
import '../../../../core/config/settings_service.dart'; // Import SettingsService
import '../../../../core/constants/ai_service_types.dart'; // Import AiServiceType
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
        child: ListView(
          // Use ListView for scrollability
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
              localizations.settingsPageOcrServiceLabel, // Placeholder key
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            DropdownButton<AiServiceType>(
              value: _selectedOcrService,
              isExpanded: true,
              items: _availableOcrServices.map((serviceType) {
                return DropdownMenuItem<AiServiceType>(
                  value: serviceType,
                  // Display a user-friendly name for the service type
                  child: Text(getServiceTypeName(
                      serviceType)), // Helper function needed
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
              localizations.settingsPageChatServiceLabel, // Placeholder key
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            DropdownButton<AiServiceType>(
              value: _selectedChatService,
              isExpanded: true,
              items: _availableChatServices.map((serviceType) {
                return DropdownMenuItem<AiServiceType>(
                  value: serviceType,
                  // Display a user-friendly name for the service type
                  child: Text(getServiceTypeName(
                      serviceType)), // Helper function needed
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
          ],
        ),
      ),
    );
  }

  // Helper function to get user-friendly service name
  String getServiceTypeName(AiServiceType serviceType) {
    final localizations = AppLocalizations.of(context)!;
    switch (serviceType) {
      case AiServiceType.gemini:
        return localizations.aiServiceGemini;
      case AiServiceType.grok:
        return localizations.aiServiceGrok;
      case AiServiceType.gigachat:
        return localizations.aiServiceGigaChat;
      default:
        return serviceType.toString().split('.').last;
    }
  }
}
