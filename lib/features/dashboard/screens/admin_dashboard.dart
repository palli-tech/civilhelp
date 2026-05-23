import 'package:flutter/material.dart';

import '../../../shared/layouts/app_scaffold.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/quick_action_tile.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        elevation: 0,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Overview',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Admin Role',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 24),

            // Dashboard Cards Grid
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                DashboardCard(
                  title: 'Total Users',
                  value: '285',
                  icon: Icons.people,
                ),
                DashboardCard(
                  title: 'Total Sites',
                  value: '48',
                  icon: Icons.location_on,
                ),
                DashboardCard(
                  title: 'Active Sessions',
                  value: '42',
                  icon: Icons.cloud_done,
                ),
                DashboardCard(
                  title: 'System Health',
                  value: '99%',
                  icon: Icons.health_and_safety,
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Quick Actions
            Text(
              'Administration',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Material(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[100],
              child: Column(
                children: [
                  QuickActionTile(
                    label: 'Manage Users',
                    icon: Icons.admin_panel_settings,
                    onTap: () {},
                  ),
                  const Divider(height: 0),
                  QuickActionTile(
                    label: 'System Logs',
                    icon: Icons.history,
                    onTap: () {},
                  ),
                  const Divider(height: 0),
                  QuickActionTile(
                    label: 'Analytics',
                    icon: Icons.analytics,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
