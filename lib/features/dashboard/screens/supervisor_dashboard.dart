import 'package:flutter/material.dart';

import '../../../shared/layouts/app_scaffold.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/quick_action_tile.dart';

class SupervisorDashboard extends StatelessWidget {
  const SupervisorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        elevation: 0,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome Back',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Supervisor Role',
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
                  title: 'Active Sites',
                  value: '5',
                  icon: Icons.location_on,
                ),
                DashboardCard(
                  title: 'Labour Present',
                  value: '24',
                  icon: Icons.people,
                ),
                DashboardCard(
                  title: 'Tasks Today',
                  value: '12',
                  icon: Icons.task_alt,
                ),
                DashboardCard(
                  title: 'Pending Approvals',
                  value: '3',
                  icon: Icons.pending_actions,
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Quick Actions
            Text(
              'Quick Actions',
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
                    label: 'Mark Attendance',
                    icon: Icons.check_circle,
                    onTap: () {},
                  ),
                  const Divider(height: 0),
                  QuickActionTile(
                    label: 'Create Task',
                    icon: Icons.add_task,
                    onTap: () {},
                  ),
                  const Divider(height: 0),
                  QuickActionTile(
                    label: 'View Reports',
                    icon: Icons.assessment,
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
