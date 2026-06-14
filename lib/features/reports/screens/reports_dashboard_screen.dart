import 'package:flutter/material.dart';
import 'package:civilhelp/app/router.dart';
import 'package:civilhelp/app/theme.dart';
import 'package:civilhelp/shared/layouts/app_scaffold.dart';

class ReportsDashboardScreen extends StatelessWidget {
  const ReportsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        elevation: 0,
      ),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          Card(
            elevation: 2,
            child: ListTile(
              leading: Icon(Icons.receipt_long, color: context.customColors.worker),
              title: const Text('Worker Ledger'),
              subtitle: const Text('View detailed chronological ledger of attendance, advances, and payments for a specific worker.'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.workerLedger);
              },
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 2,
            child: ListTile(
              leading: Icon(Icons.calendar_today, color: context.customColors.success),
              title: const Text('Attendance Summary'),
              subtitle: const Text('View aggregated attendance details including present, half-day, and absent counts.'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.attendanceSummary);
              },
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 2,
            child: ListTile(
              leading: Icon(Icons.account_balance_wallet, color: context.customColors.advance),
              title: const Text('Advance Report'),
              subtitle: const Text('Track advances issued, including applied vs remaining unapplied amounts.'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.advanceReport);
              },
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 2,
            child: ListTile(
              leading: Icon(Icons.payment, color: context.customColors.payroll),
              title: const Text('Payment Report'),
              subtitle: const Text('View total net payments made over a specific period.'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.paymentReport);
              },
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 2,
            child: ListTile(
              leading: Icon(Icons.assessment, color: context.customColors.payroll),
              title: const Text('Monthly Payroll Summary'),
              subtitle: const Text('View aggregated monthly data including earned, advances, payments and balances.'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.monthlyPayroll);
              },
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 2,
            child: ListTile(
              leading: Icon(Icons.bar_chart, color: context.customColors.attendance),
              title: const Text('Site Performance'),
              subtitle: const Text('Compare earnings, payments, advances and balances across sites.'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.sitePerformance);
              },
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 2,
            child: ListTile(
              leading: Icon(Icons.account_balance, color: context.customColors.info),
              title: const Text('Outstanding Balance'),
              subtitle: const Text('View outstanding balance for all workers.'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.outstandingBalance);
              },
            ),
          ),
        ],
      ),
    );
  }
}

