import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:civilhelp/app/theme.dart';
import 'package:civilhelp/core/providers/company_provider.dart';
import 'package:civilhelp/shared/layouts/app_scaffold.dart';
import 'package:civilhelp/shared/widgets/module_header.dart';
import '../models/report_filter.dart';
import '../providers/report_provider.dart';
import '../widgets/report_filter_bar.dart';

class MonthlyPayrollScreen extends ConsumerStatefulWidget {
  const MonthlyPayrollScreen({super.key});

  @override
  ConsumerState<MonthlyPayrollScreen> createState() => _MonthlyPayrollScreenState();
}

class _MonthlyPayrollScreenState extends ConsumerState<MonthlyPayrollScreen> {
  String? _selectedSiteId;
  String? _selectedLabourId;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 365));
  DateTime _endDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final companyIdAsync = ref.watch(userCompanyIdProvider);

    return AppScaffold(
      child: Column(
        children: [
          const ModuleHeader(
            title: 'Monthly Payroll Summary',
            subtitle: 'Overview of monthly earnings, advances, and payments',
            showBackButton: true,
          ),
          Expanded(
            child: companyIdAsync.when(
              data: (companyId) {
          return Column(
            children: [
              ReportFilterBar(
                selectedSiteId: _selectedSiteId,
                selectedWorkerId: _selectedLabourId,
                startDate: _startDate,
                endDate: _endDate,
                onSiteChanged: (val) => setState(() => _selectedSiteId = val),
                onWorkerChanged: (val) => setState(() => _selectedLabourId = val),
                onDateRangeChanged: (start, end) => setState(() {
                  _startDate = start;
                  _endDate = end;
                }),
              ),
              const Divider(height: 1),
              Expanded(
                child: _buildReportContent(companyId),
              ),
            ],
          );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportContent(String companyId) {
    final filter = ReportFilter(
      companyId: companyId,
      startDate: _startDate,
      endDate: DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59),
      labourId: _selectedLabourId,
      siteId: _selectedSiteId,
    );

    final reportAsync = ref.watch(monthlyPayrollReportProvider(filter));

    return reportAsync.when(
      data: (report) {
        if (report.entries.isEmpty) {
          return const Center(child: Text('No data available for the selected period.'));
        }

        final currencyFmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          itemCount: report.entries.length,
          itemBuilder: (context, index) {
            final entry = report.entries[index];
            return Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.listGap),
              elevation: 2,
              child: ExpansionTile(
                title: Text(entry.month, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  'Balance: ${currencyFmt.format(entry.closingBalance)}', 
                  style: TextStyle(
                    color: entry.closingBalance > 0 
                        ? context.customColors.success 
                        : (entry.closingBalance < 0 ? context.customColors.error : context.colors.outline),
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildRow('Earned', currencyFmt.format(entry.totalEarned), context.customColors.success),
                        const Divider(),
                        _buildRow('Advances', currencyFmt.format(entry.totalAdvances), context.customColors.advance),
                        const Divider(),
                        _buildRow('Payments', currencyFmt.format(entry.totalPayments), context.customColors.payroll),
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: context.colors.onSurfaceVariant)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: valueColor)),
        ],
      ),
    );
  }
}
