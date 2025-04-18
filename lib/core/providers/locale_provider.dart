import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import generated localizations

class LocaleProvider with ChangeNotifier {
  final SharedPreferences sharedPreferences;
  Locale? _locale;

  static const String _localeKey = 'locale';
  static const Locale defaultLocale = Locale('en'); // Default locale

  LocaleProvider(this.sharedPreferences) {
    _loadLocale();
  }

  Locale get locale => _locale ?? defaultLocale;

  // Get supported locales from AppLocalizations
  List<Locale> get supportedLocales => AppLocalizations.supportedLocales;

  void _loadLocale() {
    final String? localeString = sharedPreferences.getString(_localeKey);
    if (localeString != null) {
      _locale = Locale(localeString);
    } else {
      _locale = defaultLocale; // Set default if nothing is saved
    }
    // No need to notify listeners here as it's called during initialization
  }

  Future<void> setLocale(Locale locale) async {
    if (!supportedLocales.contains(locale))
      return; // Ensure locale is supported
    if (_locale == locale) return; // No change needed

    _locale = locale;
    await sharedPreferences.setString(_localeKey, locale.languageCode);
    notifyListeners();
  }
}
