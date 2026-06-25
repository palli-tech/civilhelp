import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:civilhelp/app/router.dart';
import 'package:civilhelp/core/enums/user_role.dart';
import 'package:civilhelp/core/auth/permissions.dart';
import 'package:civilhelp/core/providers/user_role_provider.dart';
import '../../features/auth/providers/auth_provider.dart';

class BottomNav extends ConsumerWidget {
  const BottomNav({super.key});

  void _navigateToRoute(BuildContext context, String routeName, String? currentRoute) {
    if (currentRoute == routeName) return;

    if (routeName == AppRoutes.dashboard) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      Navigator.of(context).popUntil((route) => route.isFirst);
      Navigator.of(context).pushNamed(routeName);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(userRoleProvider);
    final currentRoute = ModalRoute.of(context)?.settings.name;

    final List<BottomNavigationBarItem> items = [];
    final List<String> routes = [];
    final List<VoidCallback> actions = [];

    // Dashboard — always visible
    items.add(const BottomNavigationBarItem(
      icon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ));
    routes.add(AppRoutes.dashboard);
    actions.add(() => _navigateToRoute(context, AppRoutes.dashboard, currentRoute));

    if (role == UserRole.admin) {
      // Companies
      items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.business),
        label: 'Companies',
      ));
      routes.add(AppRoutes.companyManagement);
      actions.add(() => _navigateToRoute(context, AppRoutes.companyManagement, currentRoute));

      // Analytics
      items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.analytics),
        label: 'Analytics',
      ));
      routes.add(AppRoutes.adminAnalytics);
      actions.add(() => _navigateToRoute(context, AppRoutes.adminAnalytics, currentRoute));

      // Logout
      items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.logout),
        label: 'Logout',
      ));
      routes.add('');
      actions.add(() async {
        final authService = ref.read(authServiceProvider);
        await authService.signOut();
        if (context.mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      });
    } else if (role == UserRole.supervisor) {
      // Attendance for Supervisor
      items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.calendar_today),
        label: 'Attendance',
      ));
      routes.add(AppRoutes.attendance);
      actions.add(() => _navigateToRoute(context, AppRoutes.attendance, currentRoute));

      // Logout directly in BottomNav for Supervisor
      items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.logout),
        label: 'Logout',
      ));
      routes.add('');
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
        routes.add(AppRoutes.sites);
        actions.add(() => _navigateToRoute(context, AppRoutes.sites, currentRoute));
      }

      // Attendance — owner + supervisor
      if (role.canAccessAttendance) {
        items.add(const BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: 'Attendance',
        ));
        routes.add(AppRoutes.attendance);
        actions.add(() => _navigateToRoute(context, AppRoutes.attendance, currentRoute));
      }

      // More — owner/admin only
      items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.more_horiz),
        label: 'More',
      ));
      routes.add('');
      actions.add(() => _showMoreMenu(context, ref, currentRoute));
    }

    // Calculate current active index
    int currentIndex = 0;
    for (int i = 0; i < routes.length; i++) {
      if (routes[i] == currentRoute) {
        currentIndex = i;
        break;
      }
    }

    if (currentIndex == 0 && currentRoute != AppRoutes.dashboard) {
      final moreIndex = items.indexWhere((item) => item.label == 'More');
      if (moreIndex != -1) {
        currentIndex = moreIndex;
      }
    }

    return SafeArea(
      top: false,
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        items: items,
        currentIndex: currentIndex,
        onTap: (index) {
          if (index < actions.length) {
            actions[index]();
          }
        },
      ),
    );
  }

  void _showMoreMenu(BuildContext context, WidgetRef ref, String? currentRoute) {
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
                  _navigateToRoute(context, AppRoutes.labour, currentRoute);
                },
              ),

            // Payroll — owner only
            if (role.hasPermission(Permission.managePayments))
              ListTile(
                leading: const Icon(Icons.receipt_long),
                title: const Text('Payroll'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToRoute(context, AppRoutes.payroll, currentRoute);
                },
              ),

            // Advances — owner only
            if (role.canAccessAdvances)
              ListTile(
                leading: const Icon(Icons.account_balance_wallet),
                title: const Text('Advances'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToRoute(context, AppRoutes.advances, currentRoute);
                },
              ),

            // Expenses — owner/admin only
            if (role.canAccessExpenses)
              ListTile(
                leading: const Icon(Icons.receipt_long),
                title: const Text('Expenses'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToRoute(context, AppRoutes.expenses, currentRoute);
                },
              ),

            // Reports — owner only
            if (role.canAccessReports)
              ListTile(
                leading: const Icon(Icons.assessment),
                title: const Text('Reports'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToRoute(context, AppRoutes.reports, currentRoute);
                },
              ),

            // Settings — owner only
            if (role.canAccessSettings)
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToRoute(context, AppRoutes.settings, currentRoute);
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
