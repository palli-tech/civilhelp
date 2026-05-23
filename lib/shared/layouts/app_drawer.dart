import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../../core/enums/user_role.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    currentUser?.displayName?.isNotEmpty == true
                        ? currentUser!.displayName![0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  currentUser?.displayName ?? 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  currentUser?.email ?? '',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamed('/dashboard');
            },
          ),
          ListTile(
            leading: const Icon(Icons.location_on),
            title: const Text('Sites'),
            onTap: () {
              Navigator.pop(context);
              // Future route: /sites
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Labour'),
            onTap: () {
              Navigator.pop(context);
              // Future route: /labour
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Attendance'),
            onTap: () {
              Navigator.pop(context);
              // Future route: /attendance
            },
          ),
          ListTile(
            leading: const Icon(Icons.money),
            title: const Text('Expenses'),
            onTap: () {
              Navigator.pop(context);
              // Future route: /expenses
            },
          ),
          ListTile(
            leading: const Icon(Icons.receipt),
            title: const Text('Invoices'),
            onTap: () {
              Navigator.pop(context);
              // Future route: /invoices
            },
          ),
          ListTile(
            leading: const Icon(Icons.assessment),
            title: const Text('Reports'),
            onTap: () {
              Navigator.pop(context);
              // Future route: /reports
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              // Future route: /settings
            },
          ),
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
