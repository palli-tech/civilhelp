import 'package:flutter/material.dart';

import '../../../shared/layouts/app_scaffold.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/quick_action_tile.dart';

class PartnerDashboard extends StatelessWidget {
  const PartnerDashboard({super.key});

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
              'Partner Role',
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
                  title: 'Active Projects',
                  value: '8',
                  icon: Icons.work,
                ),
                DashboardCard(
                  title: 'Total Revenue',
                  value: '₹2.4L',
                  icon: Icons.trending_up,
                ),
                DashboardCard(
                  title: 'Labour Assigned',
                  value: '156',
                  icon: Icons.people,
                ),
                DashboardCard(
                  title: 'Pending Bills',
                  value: '5',
                  icon: Icons.receipt,
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
                    label: 'View Projects',
                    icon: Icons.work,
                    onTap: () {},
                  ),
                  const Divider(height: 0),
                  QuickActionTile(
                    label: 'Billing',
                    icon: Icons.payment,
                    onTap: () {},
                  ),
                  const Divider(height: 0),
                  QuickActionTile(
                    label: 'Performance',
                    icon: Icons.bar_chart,
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
