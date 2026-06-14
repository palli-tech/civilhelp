import 'package:flutter/material.dart';
import 'theme_extensions.dart';

extension ThemeContextExtension on BuildContext {
  /// Convenient accessor for standard [ColorScheme]
  ColorScheme get colors => Theme.of(this).colorScheme;

  /// Convenient accessor for standard [TextTheme]
  TextTheme get text => Theme.of(this).textTheme;

  /// Access domain-specific semantic colors via [ThemeExtension]
  CivilHelpColors get customColors => Theme.of(this).extension<CivilHelpColors>() ?? (isDarkMode ? CivilHelpColors.dark : CivilHelpColors.light);

  /// Easily check if the theme is in dark mode
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}

extension ThemeGradients on BuildContext {
  Gradient get surfaceGradient => LinearGradient(
        colors: isDarkMode
            ? [
                colors.surface,
                customColors.surfaceHigh,
              ]
            : [
                colors.surface,
                const Color(0xFFF3F0F7),
              ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  Gradient roleGradient(Color accent) => LinearGradient(
        colors: isDarkMode
            ? [
                accent.withValues(alpha: 0.15),
                colors.surface,
              ]
            : [
                accent.withValues(alpha: 0.12),
                colors.surface,
              ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}

