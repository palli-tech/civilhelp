import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:civilhelp/app/theme.dart';
import 'package:civilhelp/core/providers/user_role_provider.dart';
import 'package:civilhelp/core/auth/permissions.dart';
import '../../../app/router.dart';
import '../../../core/providers/tenant_provider.dart';
import '../../../shared/layouts/app_scaffold.dart';
import '../../../shared/widgets/module_header.dart';
import '../../auth/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenantState = ref.watch(tenantContextProvider);
    final userDataState = ref.watch(userDataProvider);
    final currentUser = ref.watch(currentUserProvider);
    final role = ref.watch(userRoleProvider);
    final themeMode = ref.watch(themeProvider);

    return AppScaffold(
      child: Column(
        children: [
          const ModuleHeader(
            title: 'Settings',
            subtitle: 'Configure application preferences and profile',
            showBackButton: false,
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // User Profile Section
                  Text(
                    'User Profile',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Card(
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.cardPadding),
                      child: userDataState.when(
                        data: (userData) {
                          final userName = userData?['name'] as String? ?? currentUser?.displayName ?? 'User';
                          final userEmail = userData?['email'] as String? ?? currentUser?.email ?? '';
                          final userRole = role.displayName;
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoRow(context, 'Name', userName),
                              const Divider(),
                              _buildInfoRow(context, 'Email', userEmail),
                              const Divider(),
                              _buildInfoRow(context, 'Role', userRole),
                            ],
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (err, stack) => Text('Error loading user profile: $err'),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sectionGap),

                  // Theme Selector Section
                  Text(
                    'Theme Settings',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Card(
                    elevation: 1,
                    child: Column(
                      children: [
                        RadioListTile<AppThemeMode>(
                          title: const Text('Light Mode'),
                          value: AppThemeMode.light,
                          groupValue: themeMode,
                          onChanged: (val) {
                            if (val != null) {
                              ref.read(themeProvider.notifier).setThemeMode(val);
                            }
                          },
                        ),
                        const Divider(height: 1),
                        RadioListTile<AppThemeMode>(
                          title: const Text('Dark Mode'),
                          value: AppThemeMode.dark,
                          groupValue: themeMode,
                          onChanged: (val) {
                            if (val != null) {
                              ref.read(themeProvider.notifier).setThemeMode(val);
                            }
                          },
                        ),
                        const Divider(height: 1),
                        RadioListTile<AppThemeMode>(
                          title: const Text('System Default'),
                          value: AppThemeMode.system,
                          groupValue: themeMode,
                          onChanged: (val) {
                            if (val != null) {
                              ref.read(themeProvider.notifier).setThemeMode(val);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sectionGap),

                  // App Portal Card
                  Card(
                    elevation: 2,
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(Icons.business, color: context.colors.primary),
                          title: const Text('Company Profile'),
                          subtitle: const Text('Update name, address, GST, and brand logo'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.of(context).pushNamed(AppRoutes.companyProfile);
                          },
                        ),
                        if (role.hasPermission(Permission.manageUsers)) ...[
                          const Divider(height: 1),
                          ListTile(
                            leading: Icon(Icons.group, color: context.customColors.payroll),
                            title: const Text('Team Management'),
                            subtitle: const Text('Manage supervisors, roles, and site assignments'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.of(context).pushNamed(AppRoutes.teamManagement);
                            },
                          ),
                        ],
                        const Divider(height: 1),
                        ListTile(
                          leading: Icon(Icons.info_outline, color: context.customColors.success),
                          title: const Text('About App'),
                          subtitle: const Text('Version details and licenses'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.of(context).pushNamed(AppRoutes.about);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sectionGap),

                  // Tenant details
                  Text(
                    'Tenant Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  tenantState.when(
                    data: (tenant) {
                      if (tenant == null) {
                        return const Card(
                          child: Padding(
                            padding: EdgeInsets.all(AppSpacing.cardPadding),
                            child: Text('No active tenant associated with this session.'),
                          ),
                        );
                      }

                      final dateFormatted = tenant.createdAt != null
                          ? DateFormat('dd-MMM-yyyy').format(tenant.createdAt!)
                          : 'N/A';

                      return Card(
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.cardPadding),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoRow(context, 'Company Name', tenant.companyName),
                              const Divider(),
                              _buildInfoRow(context, 'Company ID', tenant.companyId),
                              const Divider(),
                              _buildInfoRow(
                                context,
                                'Status',
                                tenant.tenantStatus.toUpperCase(), 
                                color: tenant.tenantStatus == 'active' ? context.customColors.success : context.colors.error,
                              ),
                              const Divider(),
                              _buildInfoRow(context, 'Registered On', dateFormatted),
                            ],
                          ),
                        ),
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.cardPadding),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (err, stack) => Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.cardPadding),
                        child: Text('Error loading tenant context: $err'),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sectionGap),

                  // Version Card
                  Card(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.cardPadding),
                      child: Column(
                        children: [
                          const Text(
                            'CivilHelp Workforce Management System',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Version 1.0.0 (Build 11)',
                            style: TextStyle(color: context.colors.onSurfaceVariant, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  ],
),
);
}

  Widget _buildInfoRow(BuildContext context, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
