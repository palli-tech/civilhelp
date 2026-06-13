import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:civilhelp/core/enums/user_role.dart';
import '../../../app/router.dart';
import '../../../core/providers/tenant_provider.dart';
import '../../../shared/layouts/app_scaffold.dart';
import '../../auth/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenantState = ref.watch(tenantContextProvider);
    final userDataState = ref.watch(userDataProvider);
    final currentUser = ref.watch(currentUserProvider);

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // User Profile Section
                  const Text(
                    'User Profile',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: userDataState.when(
                        data: (userData) {
                          final userName = userData?['name'] as String? ?? currentUser?.displayName ?? 'User';
                          final userEmail = userData?['email'] as String? ?? currentUser?.email ?? '';
                          final rawRole = userData?['role'] as String?;
                          final role = UserRole.fromString(rawRole);
                          final userRole = role.displayName;
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoRow('Name', userName),
                              const Divider(),
                              _buildInfoRow('Email', userEmail),
                              const Divider(),
                              _buildInfoRow('Role', userRole),
                            ],
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (err, stack) => Text('Error loading user profile: $err'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // App Portal Card
                  Card(
                    elevation: 2,
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.business, color: Colors.blue),
                          title: const Text('Company Profile'),
                          subtitle: const Text('Update name, address, GST, and brand logo'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.of(context).pushNamed(AppRoutes.companyProfile);
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.info_outline, color: Colors.green),
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
                  const SizedBox(height: 24),

                  // Tenant details
                  const Text(
                    'Tenant Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),

                  tenantState.when(
                    data: (tenant) {
                      if (tenant == null) {
                        return const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
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
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoRow('Company Name', tenant.companyName),
                              const Divider(),
                              _buildInfoRow('Company ID', tenant.companyId),
                              const Divider(),
                              _buildInfoRow('Status', tenant.tenantStatus.toUpperCase(), 
                                  color: tenant.tenantStatus == 'active' ? Colors.green : Colors.red),
                              const Divider(),
                              _buildInfoRow('Registered On', dateFormatted),
                            ],
                          ),
                        ),
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (err, stack) => Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text('Error loading tenant context: $err'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Version Card
                  Card(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    child: const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            'Workforce Management System',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Version 1.0.0 (Build 1)',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
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
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
