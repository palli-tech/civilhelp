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

class SitePerformanceScreen extends ConsumerStatefulWidget {
  const SitePerformanceScreen({super.key});

  @override
  ConsumerState<SitePerformanceScreen> createState() => _SitePerformanceScreenState();
}

class _SitePerformanceScreenState extends ConsumerState<SitePerformanceScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final companyIdAsync = ref.watch(userCompanyIdProvider);

    return AppScaffold(
      child: Column(
        children: [
          const ModuleHeader(
            title: 'Site Performance',
            subtitle: 'Overview of work location payouts and outstanding balances',
            showBackButton: true,
          ),
          Expanded(
            child: companyIdAsync.when(
              data: (companyId) {
          return Column(
            children: [
              ReportFilterBar(
                startDate: _startDate,
                endDate: _endDate,
                showWorkerFilter: false,
                showSiteFilter: false,
                onSiteChanged: (val) {},
                onWorkerChanged: (val) {},
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
    );

    final reportAsync = ref.watch(sitePerformanceReportProvider(filter));

    return reportAsync.when(
      data: (report) {
        if (report.entries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bar_chart, size: 64, color: context.colors.outline),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'No site performance data found',
                  style: TextStyle(fontSize: 16, color: context.colors.outline),
                ),
              ],
            ),
          );
        }

        final currencyFmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            // Top Summary Cards Section
            Column(
              children: [
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _buildSummaryCard('Total Sites', report.totalSites.toString(), context.customColors.info),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _buildSummaryCard('Total Workers', report.totalWorkers.toString(), context.customColors.worker),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _buildSummaryCard('Total Earned', currencyFmt.format(report.totalEarned), context.customColors.success),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _buildSummaryCard(
                          'Total Outstanding',
                          currencyFmt.format(report.totalOutstanding),
                          report.totalOutstanding >= 0 ? context.customColors.success : context.customColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            Text(
              'Site Details',
              style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.listGap),
            // Site Cards
            ...report.entries.map((entry) => Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.listGap),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.siteName,
                      style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Workers: ${entry.workerCount}',
                            style: TextStyle(color: context.colors.onSurfaceVariant),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Attendance Days: ${entry.attendanceDays}',
                            style: TextStyle(color: context.colors.onSurfaceVariant),
                            textAlign: TextAlign.end,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: _buildDetailCol('Earned', entry.totalEarned, currencyFmt)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildDetailCol('Advances', entry.totalAdvances, currencyFmt)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildDetailCol('Payments', entry.totalPayments, currencyFmt)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Outstanding:',
                          style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            currencyFmt.format(entry.outstandingBalance),
                            textAlign: TextAlign.end,
                            style: context.text.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: entry.outstandingBalance >= 0 ? context.customColors.success : context.customColors.error,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Card(
      color: color.withValues(alpha: 0.1),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: color.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCol(String title, double amount, NumberFormat format) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(color: context.colors.onSurfaceVariant, fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          format.format(amount),
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
