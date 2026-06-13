import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:civilhelp/core/auth/permissions.dart';
import 'package:civilhelp/core/providers/user_role_provider.dart';
import 'package:civilhelp/app/router.dart';
import 'package:civilhelp/core/providers/tenant_provider.dart';
import 'package:civilhelp/shared/widgets/company_header.dart';
import '../../features/auth/providers/auth_provider.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final userDataAsync = ref.watch(userDataProvider);
    final tenantCompanyAsync = ref.watch(tenantCompanyStreamProvider);
    final role = ref.watch(userRoleProvider);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Area (Top)
                userDataAsync.maybeWhen(
                  data: (userData) {
                    final name = userData?['name'] as String? ?? currentUser?.displayName ?? 'User';
                    final formattedRole = role.displayName;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formattedRole,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  },
                  orElse: () => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentUser?.displayName ?? 'User',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // Company Area (Bottom)
                tenantCompanyAsync.maybeWhen(
                  data: (company) => company != null
                      ? CompanyHeader(
                          companyName: company.name,
                          logoUrl: company.logoUrl,
                          size: 36.0,
                          textColor: Colors.white,
                        )
                      : const SizedBox.shrink(),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          // --- Always visible ---
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamed(AppRoutes.dashboard);
            },
          ),

          // --- Owner only: Sites ---
          if (role.canAccessSites)
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('Sites'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed(AppRoutes.sites);
              },
            ),

          // --- Owner only: Labour ---
          if (role.canAccessLabour)
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Labour'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed(AppRoutes.labour);
              },
            ),

          // --- Owner + Supervisor: Attendance ---
          if (role.canAccessAttendance)
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Attendance'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed(AppRoutes.attendance);
              },
            ),

          // --- Owner only: Payments ---
          if (role.canAccessPayments)
            ListTile(
              leading: const Icon(Icons.money),
              title: const Text('Payments'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed(AppRoutes.payments);
              },
            ),

          // --- Owner only: Advances ---
          if (role.canAccessAdvances)
            ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: const Text('Advances'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed(AppRoutes.advances);
              },
            ),

          // --- Owner only: Reports ---
          if (role.canAccessReports)
            ListTile(
              leading: const Icon(Icons.assessment),
              title: const Text('Reports'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed(AppRoutes.reports);
              },
            ),

          const Divider(),

          // --- Owner only: Settings ---
          if (role.canAccessSettings)
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed(AppRoutes.settings);
              },
            ),

          // --- Always visible: Logout ---
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
    );
  }
}
