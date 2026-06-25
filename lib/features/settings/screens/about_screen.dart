import 'package:flutter/material.dart';
import 'package:civilhelp/app/theme.dart';
import '../../../shared/layouts/app_scaffold.dart';
import '../../../shared/widgets/module_header.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: Column(
        children: [
          const ModuleHeader(
            title: 'About',
            subtitle: 'Application version and build details',
            showBackButton: true,
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  padding: const EdgeInsets.all(AppSpacing.sectionGap),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.business_center,
                        size: 80,
                        color: context.colors.primary,
                      ),
                      const SizedBox(height: AppSpacing.sectionGap),
                      const Text(
                        'CivilHelp Workforce Management System',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'CivilHelp Enterprise Edition',
                        style: TextStyle(
                          fontSize: 16,
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sectionGap),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.cardPadding),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Version', style: TextStyle(color: context.colors.onSurfaceVariant)),
                                  const Text('1.0.0', style: TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Build', style: TextStyle(color: context.colors.onSurfaceVariant)),
                                  const Text('1', style: TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('SDK Version', style: TextStyle(color: context.colors.onSurfaceVariant)),
                                  const Text('Flutter 3.x (Dart 3.x)', style: TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sectionGap),
                      Text(
                        '© 2026 PalliVerse. All rights reserved.',
                        style: TextStyle(color: context.colors.onSurfaceVariant, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

