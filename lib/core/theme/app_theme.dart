// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:hyper_split_bill/core/constants/app_colors.dart'; // Updated import path
// Assuming these widget theme files will be created or already exist in the new project structure
// If they are from hyper_authenticator, their paths or content might need adjustment.
// For now, I'll comment them out if they cause immediate errors,
// and you can provide their new versions/locations.
// import 'package:hyper_authenticator/core/theme/widget_themes/elevated_button_theme.dart';
// import 'package:hyper_authenticator/core/theme/widget_themes/outlined_button_theme.dart';
// import 'package:hyper_authenticator/core/theme/widget_themes/text_field_theme.dart';
// import 'package:hyper_authenticator/core/theme/widget_themes/text_theme.dart';

// Placeholder for CTextTheme until its new version is provided
class CTextTheme {
  static const TextTheme lightTextTheme = TextTheme(
    headlineSmall: TextStyle(fontWeight: FontWeight.bold),
    headlineMedium: TextStyle(fontWeight: FontWeight.bold),
    headlineLarge: TextStyle(fontWeight: FontWeight.bold),
  );
  static const TextTheme darkTextTheme = TextTheme(
    headlineSmall: TextStyle(fontWeight: FontWeight.bold),
    headlineMedium: TextStyle(fontWeight: FontWeight.bold),
    headlineLarge: TextStyle(fontWeight: FontWeight.bold),
  );
}

// Placeholder for COutlinedButtonTheme
class COutlinedButtonTheme {
  static final lightOutlinedButtonTheme = OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        foregroundColor:
            AppColors.cSecondaryColor, // Assuming AppColors is correctly set up
        side: const BorderSide(color: AppColors.cSecondaryColor),
        padding: const EdgeInsets.symmetric(vertical: 15)),
  );
  static final darkOutlinedButtonTheme = OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        foregroundColor:
            AppColors.cWhiteColor, // Assuming AppColors is correctly set up
        side: const BorderSide(color: AppColors.cWhiteColor),
        padding: const EdgeInsets.symmetric(vertical: 15)),
  );
}

// Placeholder for CElevatedButtonTheme
class CElevatedButtonTheme {
  static final lightElevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        foregroundColor: AppColors.cWhiteColor,
        backgroundColor: AppColors.cSecondaryColor,
        side: const BorderSide(color: AppColors.cSecondaryColor),
        padding: const EdgeInsets.symmetric(vertical: 15)),
  );
  static final darkElevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        foregroundColor: AppColors.cSecondaryColor,
        backgroundColor: AppColors.cWhiteColor,
        side: const BorderSide(color: AppColors.cWhiteColor),
        padding: const EdgeInsets.symmetric(vertical: 15)),
  );
}

// Placeholder for CTextFormFieldTheme
class CTextFormFieldTheme {
  static InputDecorationTheme lightInputDecorationTheme = InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(100)),
      prefixIconColor: AppColors.cSecondaryColor,
      floatingLabelStyle: const TextStyle(color: AppColors.cSecondaryColor),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(100),
        borderSide:
            const BorderSide(width: 2, color: AppColors.cSecondaryColor),
      ));

  static InputDecorationTheme darkInputDecorationTheme = InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(100)),
      prefixIconColor:
          AppColors.cPrimaryColor, // Assuming AppColors is correctly set up
      floatingLabelStyle: const TextStyle(color: AppColors.cPrimaryColor),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(100),
        borderSide: const BorderSide(width: 2, color: AppColors.cPrimaryColor),
      ));
}

class AppTheme {
  // Prevent instantiation
  AppTheme._();

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true, // Enable Material 3 features
    brightness: Brightness.light,
    primaryColor: AppColors.facebookBlue, // Use Facebook blue
    scaffoldBackgroundColor:
        AppColors.lightBackground, // White or light gray background
    fontFamily: 'Averta', // Set default font
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.lightBackground, // White or light gray
      foregroundColor: AppColors.textPrimaryLight, // Dark title and icons
      elevation: 0.5, // Subtle elevation or 0
      titleTextStyle: TextStyle(
        color: AppColors.textPrimaryLight,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: AppColors.textPrimaryLight),
    ),
    textTheme: CTextTheme.lightTextTheme,
    outlinedButtonTheme: COutlinedButtonTheme.lightOutlinedButtonTheme,
    elevatedButtonTheme: CElevatedButtonTheme.lightElevatedButtonTheme,
    inputDecorationTheme: CTextFormFieldTheme.lightInputDecorationTheme,
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.lightBackground,
      indicatorColor: AppColors.facebookBlue.withOpacity(0.15),
      indicatorShape: const StadiumBorder(),
      labelTextStyle: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.facebookBlue,
          );
        }
        return TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondaryLight,
        );
      }),
      iconTheme: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return IconThemeData(color: AppColors.facebookBlue);
        }
        return IconThemeData(color: AppColors.textSecondaryLight);
      }),
      elevation: 0,
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.facebookBlue, // Use Facebook blue as seed
      brightness: Brightness.light,
      primary: AppColors.facebookBlue,
      background: AppColors.lightBackground,
      surface: AppColors.lightBackground,
      onBackground: AppColors.textPrimaryLight,
      onSurface: AppColors.textPrimaryLight,
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: AppColors.facebookBlue,
    scaffoldBackgroundColor: AppColors.darkBackground,
    fontFamily: 'Averta',
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.cDarkColor,
      foregroundColor: AppColors.textPrimaryDark,
      elevation: 0.5,
      titleTextStyle: TextStyle(
        color: AppColors.textPrimaryDark,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: AppColors.textPrimaryDark),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.cDarkColor,
      indicatorColor: AppColors.cBlueColor.withOpacity(0.25),
      indicatorShape: const StadiumBorder(),
      labelTextStyle: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.cBlueColor,
          );
        }
        return TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondaryDark,
        );
      }),
      iconTheme: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return IconThemeData(color: AppColors.cBlueColor);
        }
        return IconThemeData(color: AppColors.textSecondaryDark);
      }),
      elevation: 0,
    ),
    textTheme: CTextTheme.darkTextTheme,
    outlinedButtonTheme: COutlinedButtonTheme.darkOutlinedButtonTheme,
    elevatedButtonTheme: CElevatedButtonTheme.darkElevatedButtonTheme,
    inputDecorationTheme: CTextFormFieldTheme.darkInputDecorationTheme,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.facebookBlue,
      brightness: Brightness.dark,
      primary: AppColors.facebookBlue,
      background: AppColors.darkBackground,
      surface: AppColors.darkSurface,
      onPrimary: Colors.white,
      onBackground: AppColors.textPrimaryDark,
      onSurface: AppColors.textPrimaryDark,
    ),
  );
}
