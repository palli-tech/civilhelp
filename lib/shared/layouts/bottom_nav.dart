import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:civilhelp/app/router.dart';
import 'package:civilhelp/core/enums/user_role.dart';
import 'package:civilhelp/core/auth/permissions.dart';
import 'package:civilhelp/core/providers/user_role_provider.dart';
import '../../features/auth/providers/auth_provider.dart';

class BottomNav extends ConsumerWidget {
  const BottomNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(userRoleProvider);

    final List<BottomNavigationBarItem> items = [];
    final List<VoidCallback> actions = [];

    // Dashboard — always visible
    items.add(const BottomNavigationBarItem(
      icon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ));
    actions.add(() => Navigator.of(context).pushNamed(AppRoutes.dashboard));

    if (role == UserRole.supervisor) {
      // Attendance for Supervisor
      items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.calendar_today),
        label: 'Attendance',
      ));
      actions.add(() => Navigator.of(context).pushNamed(AppRoutes.attendance));

      // Logout directly in BottomNav for Supervisor
      items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.logout),
        label: 'Logout',
      ));
      actions.add(() async {
        final authService = ref.read(authServiceProvider);
        await authService.signOut();
        if (context.mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      });
    } else {
      // Sites — owner/admin only
      if (role.canAccessSites) {
        items.add(const BottomNavigationBarItem(
          icon: Icon(Icons.location_on),
          label: 'Sites',
        ));
        actions.add(() => Navigator.of(context).pushNamed(AppRoutes.sites));
      }

      // Attendance — owner + supervisor
      if (role.canAccessAttendance) {
        items.add(const BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: 'Attendance',
        ));
        actions.add(() => Navigator.of(context).pushNamed(AppRoutes.attendance));
      }

      // More — owner/admin only
      items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.more_horiz),
        label: 'More',
      ));
      actions.add(() => _showMoreMenu(context, ref));
    }

    return SafeArea(
      top: false,
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        items: items,
        currentIndex: 0, // Since it's a push-based router, we don't strictly bind currentIndex
        onTap: (index) {
          if (index < actions.length) {
            actions[index]();
          }
        },
      ),
    );
  }

  void _showMoreMenu(BuildContext context, WidgetRef ref) {
    final role = ref.read(userRoleProvider);

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Labour — owner only
            if (role.canAccessLabour)
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text('Labour'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).pushNamed(AppRoutes.labour);
                },
              ),

            // Payroll — owner only
            if (role.hasPermission(Permission.managePayments))
              ListTile(
                leading: const Icon(Icons.receipt_long),
                title: const Text('Payroll'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).pushNamed(AppRoutes.payroll);
                },
              ),

            // Advances — owner only
            if (role.canAccessAdvances)
              ListTile(
                leading: const Icon(Icons.account_balance_wallet),
                title: const Text('Advances'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).pushNamed(AppRoutes.advances);
                },
              ),

            // Expenses — owner/admin only
            if (role.canAccessExpenses)
              ListTile(
                leading: const Icon(Icons.receipt_long),
                title: const Text('Expenses'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).pushNamed(AppRoutes.expenses);
                },
              ),

            // Reports — owner only
            if (role.canAccessReports)
              ListTile(
                leading: const Icon(Icons.assessment),
                title: const Text('Reports'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).pushNamed(AppRoutes.reports);
                },
              ),

            // Settings — owner only
            if (role.canAccessSettings)
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).pushNamed(AppRoutes.settings);
                },
              ),

            // Logout — always visible
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                Navigator.pop(context);
                final authService = ref.read(authServiceProvider);
                await authService.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
