import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _themeModePrefKey = 'theme_mode'; // Reuse key

class ThemeProvider with ChangeNotifier {
  final SharedPreferences sharedPreferences;
  ThemeMode _themeMode = ThemeMode.light; // Default

  ThemeProvider(this.sharedPreferences) {
    _loadThemeMode();
  }

  ThemeMode get themeMode => _themeMode;

  void _loadThemeMode() {
    // If no theme mode is saved, default to light mode.
    final String savedThemeMode =
        sharedPreferences.getString(_themeModePrefKey) ?? ThemeMode.light.name;
    _themeMode = ThemeMode.values.firstWhere(
      (e) => e.name == savedThemeMode,
      // Fallback to light mode if the saved string is somehow invalid,
      // though ThemeMode.light.name should always be valid.
      orElse: () => ThemeMode.light,
    );
    // No need to notify listeners here as it's called during initialization
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    if (_themeMode == themeMode) return; // No change

    _themeMode = themeMode;
    try {
      await sharedPreferences.setString(_themeModePrefKey, themeMode.name);
      notifyListeners(); // Notify listeners about the change
    } catch (e) {
      // Handle potential error saving preference
      debugPrint("Error saving theme mode preference: $e");
      // Optionally revert _themeMode or handle error differently
    }
  }
}
