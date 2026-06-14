import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:civilhelp/app/theme.dart';
import 'package:civilhelp/core/providers/company_provider.dart';
import 'package:civilhelp/shared/layouts/app_scaffold.dart';
import '../models/report_filter.dart';
import '../providers/report_provider.dart';
import '../widgets/report_filter_bar.dart';

class AttendanceSummaryScreen extends ConsumerStatefulWidget {
  const AttendanceSummaryScreen({super.key});

  @override
  ConsumerState<AttendanceSummaryScreen> createState() => _AttendanceSummaryScreenState();
}

class _AttendanceSummaryScreenState extends ConsumerState<AttendanceSummaryScreen> {
  String? _selectedSiteId;
  String? _selectedLabourId;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final companyIdAsync = ref.watch(userCompanyIdProvider);

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Attendance Summary'),
      ),
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

    final reportAsync = ref.watch(attendanceSummaryReportProvider(filter));

    return reportAsync.when(
      data: (report) {
        if (report.entries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy, size: 64, color: context.colors.outline),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'No attendance records found for selected filters',
                  style: TextStyle(color: context.colors.outline, fontSize: 16),
                ),
              ],
            ),
          );
        }

        final currencyFmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: Card(
                color: context.colors.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.cardPadding),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildGlobalMetric(
                              context, 'Total Workers', '${report.totalWorkers}'),
                          _buildGlobalMetric(
                              context, 'Attendance Days', '${report.totalAttendanceDays}'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildGlobalMetric(
                              context, 'Total Earnings', currencyFmt.format(report.totalEarned)),
                          _buildGlobalMetric(
                              context, 'Avg Daily Wage', currencyFmt.format(report.averageDailyWage)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                itemCount: report.entries.length,
                itemBuilder: (context, index) {
                  final entry = report.entries[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding, vertical: 6.0),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.cardPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                entry.labourName,
                                style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                currencyFmt.format(entry.totalEarned),
                                style: context.text.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: context.customColors.success,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildDetailCol('Days Worked', '${entry.attendanceDays}', null),
                              _buildDetailCol('Total Earned', currencyFmt.format(entry.totalEarned), null),
                              _buildDetailCol('Avg Daily Wage', currencyFmt.format(entry.averageDailyWage), null),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildGlobalMetric(BuildContext context, String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: context.text.titleSmall?.copyWith(
                color: context.colors.onPrimaryContainer.withValues(alpha: 0.7),
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: context.text.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colors.onPrimaryContainer,
              ),
        ),
      ],
    );
  }

  Widget _buildDetailCol(String title, String value, Color? color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(color: context.colors.onSurfaceVariant, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: color),
        ),
      ],
    );
  }
}
