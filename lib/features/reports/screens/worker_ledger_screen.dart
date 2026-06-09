import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:civilhelp/core/providers/company_provider.dart';
import 'package:civilhelp/features/labour/data/models/labour_model.dart';
import 'package:civilhelp/features/labour/presentation/providers/labour_provider.dart';
import 'package:civilhelp/shared/layouts/app_scaffold.dart';
import '../models/report_filter.dart';
import '../providers/report_provider.dart';
import '../models/worker_ledger_entry.dart';
import '../models/worker_ledger_report_dto.dart';

class WorkerLedgerScreen extends ConsumerStatefulWidget {
  const WorkerLedgerScreen({super.key});

  @override
  ConsumerState<WorkerLedgerScreen> createState() => _WorkerLedgerScreenState();
}

class _WorkerLedgerScreenState extends ConsumerState<WorkerLedgerScreen> {
  String? _selectedLabourId;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    debugPrint('WorkerLedgerScreen build called');
    final companyIdAsync = ref.watch(userCompanyIdProvider);
    final laboursAsync = ref.watch(labourStreamProvider);
    
    debugPrint('companyIdAsync: $companyIdAsync');
    debugPrint('laboursAsync: $laboursAsync');

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Worker Ledger'),
      ),
      child: companyIdAsync.when(
        data: (companyId) {
          debugPrint('companyIdAsync data: $companyId');
          return Column(
            children: [
              _buildFilters(companyId, laboursAsync),
              const Divider(height: 1),
              Expanded(
                child: _buildReportContent(companyId),
              ),
            ],
          );
        },
        loading: () {
          debugPrint('companyIdAsync is loading');
          return const Center(child: CircularProgressIndicator());
        },
        error: (err, stack) {
          debugPrint('companyIdAsync error: $err');
          return Center(child: Text('Error: $err'));
        },
      ),
    );
  }

  Widget _buildFilters(String companyId, AsyncValue<List<LabourModel>> laboursAsync) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Theme.of(context).cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          laboursAsync.when(
            data: (labours) {
              // Ensure selected ID exists in the list to prevent Dropdown assertion errors
              final validValue = _selectedLabourId != null && labours.any((l) => l.id == _selectedLabourId) 
                  ? _selectedLabourId 
                  : null;

              return DropdownButtonFormField<String>(
                initialValue: validValue,
                hint: const Text('Select Worker'),
                isExpanded: true,
                items: labours.map<DropdownMenuItem<String>>((labour) {
                  return DropdownMenuItem<String>(
                    value: labour.id,
                    child: Text('${labour.fullName} - ${labour.assignedSiteName}'),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedLabourId = val;
                  });
                },
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (err, stack) => Text('Error loading workers: $err'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _startDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setState(() => _startDate = date);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Start Date',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(DateFormat('dd MMM yyyy').format(_startDate)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _endDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setState(() => _endDate = date);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'End Date',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(DateFormat('dd MMM yyyy').format(_endDate)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportContent(String companyId) {
    if (_selectedLabourId == null) {
      return const Center(
        child: Text('Please select a worker to view their ledger.'),
      );
    }

    final filter = ReportFilter(
      companyId: companyId,
      startDate: _startDate,
      endDate: DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59),
      labourId: _selectedLabourId,
    );

    final reportAsync = ref.watch(workerLedgerReportProvider(filter));
    debugPrint('workerLedgerReportProvider: ${reportAsync.when(data: (d) => "data", loading: () => "loading", error: (e, s) => "error=$e")}');

    return reportAsync.when(
      data: (report) {
        return Column(
          children: [
            _buildSummaryCards(report),
            Expanded(
              child: ListView.builder(
                itemCount: report.entries.length,
                itemBuilder: (context, index) {
                  final entry = report.entries[index];
                  return _buildLedgerTile(entry);
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

  Widget _buildSummaryCards(WorkerLedgerReportDTO report) {
    final currencyFmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.blue.shade50,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SummaryStat(title: 'Earned', value: currencyFmt.format(report.totalEarned), color: Colors.green),
              _SummaryStat(title: 'Advances', value: currencyFmt.format(report.totalAdvances), color: Colors.orange),
              _SummaryStat(title: 'Paid', value: currencyFmt.format(report.totalPayments), color: Colors.blue),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Outstanding Balance: ',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                currencyFmt.format(report.outstandingBalance),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: report.outstandingBalance > 0 ? Colors.red : Colors.green,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildLedgerTile(WorkerLedgerEntry entry) {
    final currencyFmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    
    IconData icon;
    Color iconColor;
    
    switch(entry.type) {
      case LedgerEntryType.attendance:
        icon = Icons.work;
        iconColor = Colors.green;
        break;
      case LedgerEntryType.advance:
        icon = Icons.money_off;
        iconColor = Colors.orange;
        break;
      case LedgerEntryType.payment:
        icon = Icons.payments;
        iconColor = Colors.blue;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withValues(alpha: 0.2),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(entry.description),
        subtitle: Text(DateFormat('dd MMM yyyy').format(entry.date)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (entry.credit > 0)
              Text('+ ${currencyFmt.format(entry.credit)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            if (entry.debit > 0)
              Text('- ${currencyFmt.format(entry.debit)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            Text('Bal: ${currencyFmt.format(entry.runningBalance)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _SummaryStat({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}
