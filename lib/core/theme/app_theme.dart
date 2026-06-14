import 'package:flutter/material.dart';
import 'color_tokens.dart';
import 'typography_tokens.dart';
import 'theme_extensions.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: ColorTokens.lightPrimary,
        onPrimary: ColorTokens.lightOnPrimary,
        primaryContainer: ColorTokens.lightPrimaryContainer,
        onPrimaryContainer: ColorTokens.lightOnPrimaryContainer,
        secondary: ColorTokens.lightSecondary,
        onSecondary: ColorTokens.lightOnSecondary,
        secondaryContainer: ColorTokens.lightSecondaryContainer,
        onSecondaryContainer: ColorTokens.lightOnSecondaryContainer,
        background: ColorTokens.lightBackground,
        onBackground: ColorTokens.lightOnBackground,
        surface: ColorTokens.lightSurface,
        onSurface: ColorTokens.lightOnSurface,
        surfaceVariant: ColorTokens.lightSurfaceVariant,
        onSurfaceVariant: ColorTokens.lightOnSurfaceVariant,
        outline: ColorTokens.lightOutline,
        error: ColorTokens.lightError,
        onError: ColorTokens.lightOnError,
      ),
      textTheme: TypographyTokens.createTextTheme(ColorTokens.lightOnBackground),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: ColorTokens.lightOnBackground,
      ),
      cardTheme: const CardThemeData(
        color: ColorTokens.lightSurface,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: ColorTokens.lightSurfaceVariant,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ColorTokens.lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: ColorTokens.lightOutline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: ColorTokens.lightOutline.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: ColorTokens.lightPrimary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorTokens.lightPrimary,
          foregroundColor: ColorTokens.lightOnPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ColorTokens.lightPrimary,
          side: const BorderSide(color: ColorTokens.lightPrimary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      extensions: [
        CivilHelpColors.light,
      ],
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: ColorTokens.darkPrimary,
        onPrimary: ColorTokens.darkOnPrimary,
        primaryContainer: ColorTokens.darkPrimaryContainer,
        onPrimaryContainer: ColorTokens.darkOnPrimaryContainer,
        secondary: ColorTokens.darkSecondary,
        onSecondary: ColorTokens.darkOnSecondary,
        secondaryContainer: ColorTokens.darkSecondaryContainer,
        onSecondaryContainer: ColorTokens.darkOnSecondaryContainer,
        background: ColorTokens.darkBackground,
        onBackground: ColorTokens.darkOnBackground,
        surface: ColorTokens.darkSurface,
        onSurface: ColorTokens.darkOnSurface,
        surfaceVariant: ColorTokens.darkSurfaceVariant,
        onSurfaceVariant: ColorTokens.darkOnSurfaceVariant,
        outline: ColorTokens.darkOutline,
        error: ColorTokens.darkError,
        onError: ColorTokens.darkOnError,
      ),
      textTheme: TypographyTokens.createTextTheme(ColorTokens.darkOnBackground),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: ColorTokens.darkOnBackground,
      ),
      cardTheme: const CardThemeData(
        color: ColorTokens.darkSurface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: ColorTokens.darkSurfaceVariant,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ColorTokens.darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: ColorTokens.darkOutline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: ColorTokens.darkOutline.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: ColorTokens.darkPrimary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorTokens.darkPrimary,
          foregroundColor: ColorTokens.darkOnPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ColorTokens.darkPrimary,
          side: const BorderSide(color: ColorTokens.darkPrimary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      extensions: [
        CivilHelpColors.dark,
      ],
    );
  }
}
