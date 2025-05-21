import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hyper_split_bill/core/constants/ai_service_types.dart';

class SettingsService {
  final SharedPreferences _prefs;

  SettingsService(this._prefs);

  static const _selectedOcrServiceKey = 'selectedOcrService';
  static const _selectedChatServiceKey = 'selectedChatService';

  /// Gets the selected OCR service type. Defaults to Grok if not set.
  AiServiceType get selectedOcrService {
    final serviceName = _prefs.getString(_selectedOcrServiceKey);
    if (serviceName == null) {
      return AiServiceType.grok; // Default to Grok
    }
    try {
      return AiServiceType.values.firstWhere(
          (e) => e.toString().split('.').last == serviceName,
          orElse: () => AiServiceType.grok); // Default to Grok if not found
    } catch (e) {
      // Fallback in case of any parsing error
      return AiServiceType.grok;
    }
  }

  /// Sets the selected OCR service type.
  Future<bool> setSelectedOcrService(AiServiceType serviceType) async {
    return _prefs.setString(
        _selectedOcrServiceKey, serviceType.toString().split('.').last);
  }

  /// Gets the selected Chat service type. Defaults to Grok if not set.
  AiServiceType get selectedChatService {
    final serviceName = _prefs.getString(_selectedChatServiceKey);
    if (serviceName == null) {
      return AiServiceType.grok; // Default to Grok
    }
    try {
      return AiServiceType.values.firstWhere(
          (e) => e.toString().split('.').last == serviceName,
          orElse: () => AiServiceType.grok); // Default to Grok if not found
    } catch (e) {
      // Fallback in case of any parsing error
      return AiServiceType.grok;
    }
  }

  /// Sets the selected Chat service type.
  Future<bool> setSelectedChatService(AiServiceType serviceType) async {
    return _prefs.setString(
        _selectedChatServiceKey, serviceType.toString().split('.').last);
  }
}
