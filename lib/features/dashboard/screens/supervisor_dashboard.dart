import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:civilhelp/app/router.dart';
import '../../../shared/layouts/app_scaffold.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/dashboard_metrics_provider.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/quick_action_tile.dart';

class SupervisorDashboard extends ConsumerWidget {
  const SupervisorDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignedSitesCount = ref.watch(supervisorAssignedSitesCountProvider);
    final todayAttendanceCount = ref.watch(supervisorTodayAttendanceCountProvider);
    final presentWorkersCount = ref.watch(supervisorPresentWorkersCountProvider);
    final absentWorkersCount = ref.watch(supervisorAbsentWorkersCountProvider);
    final pendingAttendanceCount = ref.watch(supervisorPendingAttendanceCountProvider);
    final userData = ref.watch(userDataProvider).value;
    final userName = userData?['name'] as String? ?? 'Supervisor';

    String formatCount(AsyncValue<int> value) {
      return value.when(
        data: (count) => count.toString(),
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
                  title: 'Assigned Sites',
                  value: formatCount(assignedSitesCount),
                  icon: Icons.location_on,
                ),
                DashboardCard(
                  title: "Today's Attendance",
                  value: formatCount(todayAttendanceCount),
                  icon: Icons.today,
                ),
                DashboardCard(
                  title: 'Present Workers',
                  value: formatCount(presentWorkersCount),
                  icon: Icons.check_circle,
                ),
                DashboardCard(
                  title: 'Absent Workers',
                  value: formatCount(absentWorkersCount),
                  icon: Icons.cancel,
                ),
                DashboardCard(
                  title: 'Pending Attendance',
                  value: formatCount(pendingAttendanceCount),
                  icon: Icons.pending_actions,
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
