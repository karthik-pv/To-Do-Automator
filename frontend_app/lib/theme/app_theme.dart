import 'package:flutter/material.dart';

class AppTheme {
  // Dark theme colors inspired by Microsoft To-Do
  static const Color primaryBlue = Color(0xFF4A9EFF);
  static const Color lightBlue = Color(0xFF40E0D0);
  static const Color backgroundDark = Color(0xFF1E1E1E); // Main background
  static const Color surfaceDark = Color(0xFF2D2D30); // Cards and surfaces
  static const Color surfaceDarker = Color(0xFF252526); // Input fields and secondary surfaces
  static const Color borderDark = Color(0xFF3E3E42); // Borders
  static const Color textPrimary = Color(0xFFFFFFFF); // Primary text (white)
  static const Color textSecondary = Color(0xFFCCCCCC); // Secondary text (light gray)
  static const Color textTertiary = Color(0xFF999999); // Tertiary text (darker gray)
  static const Color importantOrange = Color(0xFFFF8C00); // Important tasks
  static const Color completedGreen = Color(0xFF4CAF50); // Completed tasks
  static const Color hoverDark = Color(0xFF404040); // Hover states
  static const Color accentPurple = Color(0xFF9A4DFF); // Accent color
  static const Color warningRed = Color(0xFFFF6B6B); // Errors and delete actions

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: createMaterialColor(primaryBlue),
    scaffoldBackgroundColor: backgroundDark,
    appBarTheme: const AppBarTheme(
      backgroundColor: surfaceDark,
      elevation: 0,
      iconTheme: IconThemeData(color: textPrimary),
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      color: surfaceDark,
      elevation: 2,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceDarker,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: borderDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: borderDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryBlue, width: 2),
      ),
      hintStyle: const TextStyle(color: textTertiary),
      labelStyle: const TextStyle(color: textSecondary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    iconTheme: const IconThemeData(
      color: textSecondary,
    ),
    listTileTheme: const ListTileThemeData(
      textColor: textPrimary,
      iconColor: textSecondary,
    ),
    dividerTheme: const DividerThemeData(
      color: borderDark,
      thickness: 1,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w300),
      displayMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w400),
      displaySmall: TextStyle(color: textPrimary, fontWeight: FontWeight.w400),
      headlineLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w400),
      headlineMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w400),
      headlineSmall: TextStyle(color: textPrimary, fontWeight: FontWeight.w400),
      titleLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w500),
      titleMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w500),
      titleSmall: TextStyle(color: textPrimary, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(color: textPrimary),
      bodyMedium: TextStyle(color: textSecondary),
      bodySmall: TextStyle(color: textTertiary),
      labelLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w500),
      labelMedium: TextStyle(color: textSecondary, fontWeight: FontWeight.w500),
      labelSmall: TextStyle(color: textTertiary, fontWeight: FontWeight.w500),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      contentTextStyle: TextStyle(
        color: textSecondary,
        fontSize: 16,
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: surfaceDarker,
      contentTextStyle: TextStyle(color: textPrimary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryBlue,
      foregroundColor: Colors.white,
      elevation: 4,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryBlue;
        }
        return textTertiary;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryBlue.withOpacity(0.5);
        }
        return borderDark;
      }),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return completedGreen;
        }
        return null;
      }),
      checkColor: WidgetStateProperty.all(Colors.white),
    ),
    popupMenuTheme: const PopupMenuThemeData(
      color: surfaceDark,
      textStyle: TextStyle(color: textPrimary),
    ),
  );

  static MaterialColor createMaterialColor(Color color) {
    final strengths = <double>[.05];
    final swatch = <int, Color>{};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
  }

  // Legacy color names for backward compatibility
  static Color get backgroundGray => backgroundDark;
  static Color get cardWhite => surfaceDark;
  static Color get textDark => textPrimary;
  static Color get textLight => textSecondary;
  static Color get borderGray => borderDark;
  static Color get importantRed => importantOrange;
  static Color get hoverGray => hoverDark;
} 