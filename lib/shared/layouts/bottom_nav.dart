import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';

class BottomNav extends ConsumerWidget {
  const BottomNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BottomNavigationBar(
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.location_on),
          label: 'Sites',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: 'Labour',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.more_horiz),
          label: 'More',
        ),
      ],
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.of(context).pushNamed('/dashboard');
            break;
          case 1:
            // Navigate to sites
            break;
          case 2:
            // Navigate to labour
            break;
          case 3:
            // Show more menu
            _showMoreMenu(context, ref);
            break;
        }
      },
    );
  }

  void _showMoreMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Attendance'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to attendance
              },
            ),
            ListTile(
              leading: const Icon(Icons.money),
              title: const Text('Expenses'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to expenses
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt),
              title: const Text('Invoices'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to invoices
              },
            ),
            ListTile(
              leading: const Icon(Icons.assessment),
              title: const Text('Reports'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to reports
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to settings
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
      ),
    );
  }
}
