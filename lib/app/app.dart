import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme.dart';

class CivilHelpApp extends ConsumerWidget {
  const CivilHelpApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeModeSetting = ref.watch(themeProvider);

    ThemeMode flutterThemeMode;
    switch (themeModeSetting) {
      case AppThemeMode.light:
        flutterThemeMode = ThemeMode.light;
        break;
      case AppThemeMode.dark:
        flutterThemeMode = ThemeMode.dark;
        break;
      case AppThemeMode.system:
        flutterThemeMode = ThemeMode.system;
        break;
    }

    return MaterialApp(
      title: 'CivilHelp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: flutterThemeMode,
      initialRoute: '/',
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
