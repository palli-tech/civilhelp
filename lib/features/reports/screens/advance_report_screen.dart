import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:civilhelp/app/theme.dart';
import 'package:civilhelp/core/providers/company_provider.dart';
import 'package:civilhelp/shared/layouts/app_scaffold.dart';
import '../models/report_filter.dart';
import '../providers/report_provider.dart';
import '../widgets/report_filter_bar.dart';

class AdvanceReportScreen extends ConsumerStatefulWidget {
  const AdvanceReportScreen({super.key});

  @override
  ConsumerState<AdvanceReportScreen> createState() => _AdvanceReportScreenState();
}

class _AdvanceReportScreenState extends ConsumerState<AdvanceReportScreen> {
  String? _selectedSiteId;
  String? _selectedLabourId;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final companyIdAsync = ref.watch(userCompanyIdProvider);

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Advance Report'),
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

    final reportAsync = ref.watch(advanceReportProvider(filter));

    return reportAsync.when(
      data: (report) {
        final currencyFmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: context.customColors.advance.withValues(alpha: 0.2),
                        child: Icon(Icons.account_balance_wallet, color: context.customColors.advance, size: 30),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total Advances Issued', style: context.text.titleMedium?.copyWith(color: context.colors.onSurfaceVariant)),
                            const SizedBox(height: 8),
                            Text(
                              currencyFmt.format(report.totalAdvances),
                              style: context.text.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: context.customColors.advance,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.listGap),
              Row(
                children: [
                  Expanded(
                    child: Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              report.advanceCount.toString(),
                              style: context.text.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: context.customColors.info,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('Advance Count', style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              currencyFmt.format(report.remainingUnapplied),
                              style: context.text.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: context.customColors.error,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('Unapplied/Remaining', style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}

