import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:civilhelp/core/providers/company_provider.dart';
import 'package:civilhelp/shared/layouts/app_scaffold.dart';
import '../models/report_filter.dart';
import '../providers/report_provider.dart';
import '../widgets/report_filter_bar.dart';

class OutstandingBalanceScreen extends ConsumerStatefulWidget {
  const OutstandingBalanceScreen({super.key});

  @override
  ConsumerState<OutstandingBalanceScreen> createState() => _OutstandingBalanceScreenState();
}

class _OutstandingBalanceScreenState extends ConsumerState<OutstandingBalanceScreen> {
  String? _selectedSiteId;
  String? _selectedLabourId;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final companyIdAsync = ref.watch(userCompanyIdProvider);

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Outstanding Balance'),
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

    final reportAsync = ref.watch(outstandingBalanceReportProvider(filter));

    return reportAsync.when(
      data: (report) {
        if (report.workerEntries.isEmpty) {
          return const Center(
            child: Text('No outstanding balances for selected period.'),
          );
        }

        final currencyFmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
        
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Outstanding Balance',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                      ),
                      Text(
                        currencyFmt.format(report.totalOutstandingBalance),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: report.totalOutstandingBalance >= 0 ? Colors.green : Colors.red,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: report.workerEntries.length,
                itemBuilder: (context, index) {
                  final entry = report.workerEntries[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                entry.workerName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                currencyFmt.format(entry.outstandingBalance),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: entry.outstandingBalance >= 0 ? Colors.green : Colors.red,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildDetailCol('Earned', entry.totalEarned, currencyFmt),
                              _buildDetailCol('Advances', entry.totalAdvances, currencyFmt),
                              _buildDetailCol('Payments', entry.totalPayments, currencyFmt),
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

  Widget _buildDetailCol(String title, double amount, NumberFormat format) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          format.format(amount),
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
      ],
    );
  }
}
