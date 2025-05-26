import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    AiServiceType.tesseract,
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localizations = AppLocalizations.of(context)!;

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

    // Helper to get language flag emoji
    String getLanguageFlag(Locale locale) {
      switch (locale.languageCode) {
        case 'en':
          return '🇺🇸';
        case 'ru':
          return '🇷🇺';
        case 'vi':
          return '🇻🇳';
        default:
          return '🌐';
      }
    }

    // Helper to get AI service icon
    IconData getServiceIcon(AiServiceType serviceType) {
      switch (serviceType) {
        case AiServiceType.gemini:
          return Icons.auto_awesome;
        case AiServiceType.grok:
          return Icons.psychology;
        case AiServiceType.gigachat:
          return Icons.chat_bubble;
        case AiServiceType.tesseract:
          return Icons.document_scanner;
        default:
          return Icons.smart_toy;
      }
    }

    // Helper to check if service is experimental/disabled
    bool isServiceDisabled(AiServiceType serviceType) {
      // Only Tesseract is disabled, Gemini is now selectable with warning
      return serviceType == AiServiceType.tesseract;
    }

    // Helper to get experimental label
    String getExperimentalLabel(AiServiceType serviceType) {
      if (serviceType == AiServiceType.gemini ||
          serviceType == AiServiceType.tesseract) {
        return ' (Experimental)';
      }
      if (serviceType == AiServiceType.gigachat) {
        return ' (Beta)';
      }
      return '';
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(localizations.settingsPageTitle),
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
              Theme.of(context).brightness == Brightness.light
                  ? Brightness.dark
                  : Brightness.light,
          statusBarBrightness: Theme.of(context).brightness,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Simplified Header Section
            Center(
              child: Icon(
                Icons.settings,
                size: 36,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),

            // Preferences Section
            Text(
              'Preferences',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            // Language Setting Card
            _buildSettingCard(
              context,
              icon: Icons.language,
              title: localizations.settingsPageLanguageLabel,
              subtitle: 'Choose your preferred language',
              child: Column(
                children: supportedLocales.map((locale) {
                  final isSelected = currentLocale == locale;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: ListTile(
                      leading: Text(
                        getLanguageFlag(locale),
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Text(
                        getLanguageName(locale),
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(
                              Icons.check_circle,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : null,
                      onTap: () => localeProvider.setLocale(locale),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // AI Services Section
            Text(
              'AI Services',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            // OCR Service Setting Card
            _buildSettingCard(
              context,
              icon: Icons.document_scanner,
              title: localizations.settingsPageOcrServiceLabel,
              subtitle: 'Select AI service for bill scanning',
              child: Column(
                children: _availableOcrServices.map((serviceType) {
                  final isSelected = _selectedOcrService == serviceType;
                  final isDisabled = isServiceDisabled(serviceType);
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isDisabled
                          ? Colors.grey.withOpacity(0.05)
                          : isSelected
                              ? Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.1)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDisabled
                            ? Colors.grey.withOpacity(0.2)
                            : isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Opacity(
                      opacity: isDisabled ? 0.5 : 1.0,
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.2)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            getServiceIcon(serviceType),
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey[600],
                            size: 20,
                          ),
                        ),
                        title: Text(
                          getServiceTypeName(serviceType) +
                              getExperimentalLabel(serviceType),
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                        ),
                        trailing: isDisabled
                            ? Icon(
                                Icons.lock_outline,
                                color: Colors.grey[400],
                                size: 20,
                              )
                            : isSelected
                                ? Icon(
                                    Icons.check_circle,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  )
                                : null,
                        onTap: isServiceDisabled(serviceType)
                            ? null
                            : () {
                                if (serviceType == AiServiceType.gemini) {
                                  _showExperimentalWarning(serviceType);
                                } else {
                                  setState(() {
                                    _selectedOcrService = serviceType;
                                  });
                                  _settingsService
                                      .setSelectedOcrService(serviceType);
                                }
                              },
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // Chat Service Setting Card
            _buildSettingCard(
              context,
              icon: Icons.chat,
              title: localizations.settingsPageChatServiceLabel,
              subtitle: 'Select AI service for chat assistance',
              child: Column(
                children: _availableChatServices.map((serviceType) {
                  final isSelected = _selectedChatService == serviceType;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.2)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          getServiceIcon(serviceType),
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey[600],
                          size: 20,
                        ),
                      ),
                      title: Text(
                        getServiceTypeName(serviceType) +
                            getExperimentalLabel(serviceType),
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(
                              Icons.check_circle,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedChatService = serviceType;
                        });
                        _settingsService.setSelectedChatService(serviceType);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 32),

            // Account Section
            Text(
              'Account',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            // Logout Button
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                if (state is AuthAuthenticated) {
                  return Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          Colors.red.withOpacity(0.8),
                          Colors.red.withOpacity(0.9),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: Text(
                        localizations.settingsPageSignOutButton,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: Row(
                              children: [
                                Icon(
                                  Icons.logout,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 8),
                                Text(localizations.homePageSignOutDialogTitle),
                              ],
                            ),
                            content: Text(
                                localizations.homePageSignOutDialogContent),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(),
                                child: Text(
                                  localizations.buttonCancel,
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.of(dialogContext).pop();
                                  context
                                      .read<AuthBloc>()
                                      .add(AuthSignOutRequested());
                                },
                                child: Text(localizations
                                    .homePageSignOutDialogConfirmButton),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  // Show experimental warning dialog for Gemini
  void _showExperimentalWarning(AiServiceType serviceType) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning,
              color: Colors.orange,
              size: 24,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Experimental',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gemini OCR is experimental and may be unreliable.',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Text('• May produce errors'),
            const SizedBox(height: 4),
            Text('• Still in development'),
            const SizedBox(height: 12),
            Text(
              'Grok is recommended for reliable results.',
              style: TextStyle(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              setState(() {
                _selectedOcrService = serviceType;
              });
              _settingsService.setSelectedOcrService(serviceType);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('⚠️ Gemini OCR enabled'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: Text('Use Anyway'),
          ),
        ],
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
      case AiServiceType.tesseract:
        return 'Tesseract';
      default:
        // Fallback for any new service types not yet localized
        return serviceType.toString().split('.').last;
    }
  }
}
