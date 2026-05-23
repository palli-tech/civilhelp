import 'package:flutter/material.dart';

import 'router.dart';
import 'theme.dart';

class CivilHelpApp extends StatelessWidget {
  const CivilHelpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CivilHelp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
