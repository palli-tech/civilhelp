import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/enums/user_role.dart';
import '../../../core/providers/user_role_provider.dart';
import '../../auth/providers/auth_provider.dart';
import 'admin_dashboard.dart';
import 'owner_dashboard.dart';
import 'partner_dashboard.dart';
import 'supervisor_dashboard.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userDataAsync = ref.watch(userDataProvider);
    final role = ref.watch(userRoleProvider);

    return userDataAsync.when(
      data: (userData) {
        switch (role) {
          case UserRole.admin:
            return const AdminDashboard();
          case UserRole.owner:
          case UserRole.partner:
            return const OwnerDashboard();
          case UserRole.supervisor:
            return const SupervisorDashboard();
          case UserRole.pending:
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
        }
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stackTrace) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Error loading dashboard'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(userDataProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
