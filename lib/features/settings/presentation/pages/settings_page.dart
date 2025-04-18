import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import generated localizations
import '../../../../core/providers/locale_provider.dart'; // Import LocaleProvider

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static const String routeName = '/settings'; // Define route name

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final currentLocale = localeProvider.locale;
    final supportedLocales = localeProvider.supportedLocales;
    final localizations = AppLocalizations.of(context)!; // Get localizations

    // Helper to get language name from locale
    String getLanguageName(Locale locale) {
      // Use language code directly or create a map if more names are needed
      switch (locale.languageCode) {
        case 'en':
          return 'English'; // Hardcoded for now
        case 'ru':
          return 'Русский'; // Hardcoded for now
        default:
          return locale.languageCode.toUpperCase();
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.settingsPageTitle), // Use corrected key
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.settingsPageLanguageLabel, // Use corrected key
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
          ],
        ),
      ),
    );
  }
}
