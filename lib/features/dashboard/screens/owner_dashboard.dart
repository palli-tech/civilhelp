import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/layouts/app_scaffold.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/dashboard_metrics_provider.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/quick_action_tile.dart';

class OwnerDashboard extends ConsumerWidget {
  const OwnerDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userData = ref.watch(userDataProvider).value;
    final userName = userData?['name'] as String? ?? 'Owner';

    final totalSites = ref.watch(totalSitesCountProvider);
    final activeLabour = ref.watch(activeLabourCountProvider);
    final todayAttendance = ref.watch(todayAttendanceCountProvider);
    final outstandingAdvances = ref.watch(outstandingAdvanceTotalProvider);
    final pendingPayments = ref.watch(pendingPaymentsCountProvider);
    final currentMonthPayroll = ref.watch(currentMonthPayrollProvider);

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
              'Welcome Back, $userName',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Owner Role',
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
                  title: 'Total Sites',
                  value: formatCount(totalSites),
                  icon: Icons.location_on,
                ),
                DashboardCard(
                  title: 'Active Labour',
                  value: formatCount(activeLabour),
                  icon: Icons.people,
                ),
                DashboardCard(
                  title: "Today's Attendance",
                  value: formatCount(todayAttendance),
                  icon: Icons.today,
                ),
                DashboardCard(
                  title: 'Outstanding Advances',
                  value: formatAmount(outstandingAdvances),
                  icon: Icons.account_balance_wallet,
                ),
                DashboardCard(
                  title: 'Pending Payments',
                  value: formatCount(pendingPayments),
                  icon: Icons.payment,
                ),
                DashboardCard(
                  title: 'Current Month Payroll',
                  value: formatAmount(currentMonthPayroll),
                  icon: Icons.money,
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
                    onTap: () {
                      Navigator.pushNamed(context, '/reports');
                    },
                  ),
                  const Divider(height: 0),
                  QuickActionTile(
                    label: 'Manage Sites',
                    icon: Icons.location_on,
                    onTap: () {
                      Navigator.pushNamed(context, '/sites');
                    },
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
