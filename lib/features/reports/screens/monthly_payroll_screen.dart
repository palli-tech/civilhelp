import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:civilhelp/core/providers/company_provider.dart';
import 'package:civilhelp/features/labour/data/models/labour_model.dart';
import 'package:civilhelp/features/labour/presentation/providers/labour_provider.dart';
import 'package:civilhelp/shared/layouts/app_scaffold.dart';
import '../models/report_filter.dart';
import '../providers/report_provider.dart';

class MonthlyPayrollScreen extends ConsumerStatefulWidget {
  const MonthlyPayrollScreen({super.key});

  @override
  ConsumerState<MonthlyPayrollScreen> createState() => _MonthlyPayrollScreenState();
}

class _MonthlyPayrollScreenState extends ConsumerState<MonthlyPayrollScreen> {
  String? _selectedLabourId;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 365));
  DateTime _endDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final companyIdAsync = ref.watch(userCompanyIdProvider);
    final laboursAsync = ref.watch(labourStreamProvider);

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Monthly Payroll Summary'),
      ),
      child: companyIdAsync.when(
        data: (companyId) {
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
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
              final validValue = _selectedLabourId != null && labours.any((l) => l.id == _selectedLabourId) 
                  ? _selectedLabourId 
                  : null;

              return DropdownButtonFormField<String>(
                initialValue: validValue,
                hint: const Text('All Workers (Optional)'),
                isExpanded: true,
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('All Workers'),
                  ),
                  ...labours.map<DropdownMenuItem<String>>((labour) {
                    return DropdownMenuItem<String>(
                      value: labour.id,
                      child: Text('${labour.fullName} - ${labour.assignedSiteName}'),
                    );
                  })
                ],
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
                    child: Text(DateFormat('MMM yyyy').format(_startDate)),
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
                    child: Text(DateFormat('MMM yyyy').format(_endDate)),
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
    final filter = ReportFilter(
      companyId: companyId,
      startDate: _startDate,
      endDate: DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59),
      labourId: _selectedLabourId,
    );

    final reportAsync = ref.watch(monthlyPayrollReportProvider(filter));

    return reportAsync.when(
      data: (report) {
        if (report.entries.isEmpty) {
          return const Center(child: Text('No data available for the selected period.'));
        }

        final currencyFmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: report.entries.length,
          itemBuilder: (context, index) {
            final entry = report.entries[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              child: ExpansionTile(
                title: Text(entry.month, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Balance: ${currencyFmt.format(entry.closingBalance)}', 
                  style: TextStyle(color: entry.closingBalance > 0 ? Colors.green : (entry.closingBalance < 0 ? Colors.red : Colors.grey))),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildRow('Earned', currencyFmt.format(entry.totalEarned), Colors.green),
                        const Divider(),
                        _buildRow('Advances', currencyFmt.format(entry.totalAdvances), Colors.orange),
                        const Divider(),
                        _buildRow('Payments', currencyFmt.format(entry.totalPayments), Colors.purple),
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
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: valueColor)),
        ],
      ),
    );
  }
}
