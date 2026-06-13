import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/enums/user_role.dart';
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

    return userDataAsync.when(
      data: (userData) {
        final roleStr = userData?['role'] as String?;
        final role = UserRole.fromString(roleStr);
        switch (role) {
          case UserRole.admin:
            return const AdminDashboard();
          case UserRole.owner:
            return const OwnerDashboard();
          case UserRole.partner:
            return const PartnerDashboard();
          case UserRole.supervisor:
            return const SupervisorDashboard();
          case UserRole.pending:
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacementNamed('/company-setup');
            });
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
