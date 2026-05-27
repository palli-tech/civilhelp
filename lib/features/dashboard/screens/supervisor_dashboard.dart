import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:civilhelp/app/router.dart';
import '../../../shared/layouts/app_scaffold.dart';
import '../providers/dashboard_metrics_provider.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/quick_action_tile.dart';

class SupervisorDashboard extends ConsumerWidget {
  const SupervisorDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSites = ref.watch(activeSitesCountProvider);
    final labourPresent = ref.watch(labourPresentTodayCountProvider);
    final pendingPayments = ref.watch(pendingPaymentsCountProvider);
    final outstandingAdvanceTotal = ref.watch(outstandingAdvanceTotalProvider);

    String formatCount(AsyncValue<int> value) {
      return value.when(
        data: (count) => count.toString(),
        loading: () => '--',
        error: (_, _) => 'N/A',
      );
    }

    String formatAmount(AsyncValue<double> value) {
      return value.when(
        data: (amount) => '₹${amount.toStringAsFixed(0)}',
        loading: () => '--',
        error: (_, _) => 'N/A',
      );
    }

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
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 24),

            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.3,
              primary: false,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                DashboardCard(
                  title: 'Active Sites',
                  value: formatCount(activeSites),
                  icon: Icons.location_on,
                ),
                DashboardCard(
                  title: 'Labour Present',
                  value: formatCount(labourPresent),
                  icon: Icons.people,
                ),
                DashboardCard(
                  title: 'Pending Payments',
                  value: formatCount(pendingPayments),
                  icon: Icons.money,
                ),
                DashboardCard(
                  title: 'Advance Outstanding',
                  value: formatAmount(outstandingAdvanceTotal),
                  icon: Icons.account_balance_wallet,
                ),
              ],
            ),

            const SizedBox(height: 32),

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
                    onTap: () {
                      Navigator.of(context).pushNamed(AppRoutes.attendance);
                    },
                  ),
                  const Divider(height: 0),
                  QuickActionTile(
                    label: 'Create Payment',
                    icon: Icons.payment,
                    onTap: () {
                      Navigator.of(context).pushNamed(AppRoutes.payments);
                    },
                  ),
                  const Divider(height: 0),
                  QuickActionTile(
                    label: 'View Advances',
                    icon: Icons.account_balance_wallet,
                    onTap: () {
                      Navigator.of(context).pushNamed(AppRoutes.advances);
                    },
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
