import 'package:flutter/material.dart';
import 'package:civilhelp/app/router.dart';
import 'package:civilhelp/app/theme.dart';
import 'package:civilhelp/shared/layouts/app_scaffold.dart';
import 'package:civilhelp/shared/widgets/module_header.dart';
import 'package:civilhelp/shared/widgets/premium_module_card.dart';

class ReportsDashboardScreen extends StatelessWidget {
  const ReportsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reports = [
      (
        title: 'Worker Ledger',
        description: 'View detailed chronological ledger of attendance, advances, and payments for a specific worker.',
        icon: Icons.receipt_long,
        color: context.customColors.worker,
        route: AppRoutes.workerLedger,
      ),
      (
        title: 'Attendance Summary',
        description: 'View aggregated attendance details including present, half-day, and absent counts.',
        icon: Icons.calendar_today,
        color: context.customColors.success,
        route: AppRoutes.attendanceSummary,
      ),
      (
        title: 'Advance Report',
        description: 'Track advances issued, including applied vs remaining unapplied amounts.',
        icon: Icons.account_balance_wallet,
        color: context.customColors.advance,
        route: AppRoutes.advanceReport,
      ),
      (
        title: 'Payment Report',
        description: 'View total net payments made over a specific period.',
        icon: Icons.payment,
        color: context.customColors.payroll,
        route: AppRoutes.paymentReport,
      ),
      (
        title: 'Monthly Payroll Summary',
        description: 'View aggregated monthly data including earned, advances, payments and balances.',
        icon: Icons.assessment,
        color: context.customColors.payroll,
        route: AppRoutes.monthlyPayroll,
      ),
      (
        title: 'Site Performance',
        description: 'Compare earnings, payments, advances and balances across sites.',
        icon: Icons.bar_chart,
        color: context.customColors.attendance,
        route: AppRoutes.sitePerformance,
      ),
      (
        title: 'Outstanding Balance',
        description: 'View outstanding balance for all workers.',
        icon: Icons.account_balance,
        color: context.customColors.info,
        route: AppRoutes.outstandingBalance,
      ),
    ];

    return AppScaffold(
      child: Column(
        children: [
          const ModuleHeader(
            title: 'Reports',
            subtitle: 'View workforce, attendance and payroll analytics',
            showBackButton: false,
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final availableWidth = constraints.maxWidth;
                final textScale = MediaQuery.maybeTextScalerOf(context)?.scale(1.0) ?? 1.0;
                final int crossAxisCount;
                final double baseAspectRatio;

                if (availableWidth >= 600) {
                  crossAxisCount = 2;
                  baseAspectRatio = 2.8;
                } else {
                  crossAxisCount = 1;
                  baseAspectRatio = 1.8;
                }

                return GridView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: baseAspectRatio / textScale,
                  ),
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final report = reports[index];
                return PremiumModuleCard(
                  glowColor: report.color,
                  onTap: () {
                    Navigator.pushNamed(context, report.route);
                  },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: report.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          report.icon,
                          color: report.color,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              report.title,
                              style: context.text.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              report.description,
                              style: context.text.bodySmall?.copyWith(
                                color: context.colors.onSurfaceVariant,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Center(
                        child: Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: context.colors.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
          ),
        ],
      ),
    );
  }
}
