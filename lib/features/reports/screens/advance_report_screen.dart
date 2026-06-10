import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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
          padding: const EdgeInsets.all(16.0),
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
                        backgroundColor: Colors.orange.withValues(alpha: 0.2),
                        child: const Icon(Icons.account_balance_wallet, color: Colors.orange, size: 30),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total Advances Issued', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[700])),
                            const SizedBox(height: 8),
                            Text(currencyFmt.format(report.totalAdvances), style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.orange)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(report.advanceCount.toString(), style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.blue)),
                            const SizedBox(height: 8),
                            Text('Advance Count', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700])),
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
                            Text(currencyFmt.format(report.remainingUnapplied), style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.red)),
                            const SizedBox(height: 8),
                            Text('Unapplied/Remaining', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700])),
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

