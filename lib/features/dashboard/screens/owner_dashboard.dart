import 'package:flutter/material.dart';

import '../../../shared/layouts/app_scaffold.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/quick_action_tile.dart';

class OwnerDashboard extends StatelessWidget {
  const OwnerDashboard({super.key});

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
              'Business Owner Role',
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
                  title: 'Total Revenue',
                  value: '₹12.5L',
                  icon: Icons.trending_up,
                ),
                DashboardCard(
                  title: 'Active Sites',
                  value: '15',
                  icon: Icons.location_on,
                ),
                DashboardCard(
                  title: 'Total Expenses',
                  value: '₹8.2L',
                  icon: Icons.money_off,
                ),
                DashboardCard(
                  title: 'Pending Invoices',
                  value: '12',
                  icon: Icons.receipt_long,
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
                    label: 'Financial Reports',
                    icon: Icons.assessment,
                    onTap: () {},
                  ),
                  const Divider(height: 0),
                  QuickActionTile(
                    label: 'Manage Sites',
                    icon: Icons.location_on,
                    onTap: () {},
                  ),
                  const Divider(height: 0),
                  QuickActionTile(
                    label: 'Partner Management',
                    icon: Icons.people,
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
