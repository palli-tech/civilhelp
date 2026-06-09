import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:civilhelp/core/providers/company_provider.dart';
import 'package:civilhelp/features/labour/data/models/labour_model.dart';
import 'package:civilhelp/features/labour/presentation/providers/labour_provider.dart';
import 'package:civilhelp/shared/layouts/app_scaffold.dart';
import '../models/report_filter.dart';
import '../providers/report_provider.dart';
import '../models/report_dtos.dart';

class AttendanceSummaryScreen extends ConsumerStatefulWidget {
  const AttendanceSummaryScreen({super.key});

  @override
  ConsumerState<AttendanceSummaryScreen> createState() => _AttendanceSummaryScreenState();
}

class _AttendanceSummaryScreenState extends ConsumerState<AttendanceSummaryScreen> {
  String? _selectedLabourId;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final companyIdAsync = ref.watch(userCompanyIdProvider);
    final laboursAsync = ref.watch(labourStreamProvider);

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Attendance Summary'),
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
                value: validValue,
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
    final filter = ReportFilter(
      companyId: companyId,
      startDate: _startDate,
      endDate: DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59),
      labourId: _selectedLabourId,
    );

    final reportAsync = ref.watch(attendanceSummaryReportProvider(filter));

    return reportAsync.when(
      data: (report) {
        final currencyFmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _SummaryCard(
                title: 'Total Earned',
                value: currencyFmt.format(report.totalEarned),
                icon: Icons.currency_rupee,
                color: Colors.green,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Total Days',
                      value: report.totalDays.toString(),
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatCard(
                      title: 'Present',
                      value: report.presentCount.toString(),
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Half Day',
                      value: report.halfDayCount.toString(),
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatCard(
                      title: 'Absent',
                      value: report.absentCount.toString(),
                      color: Colors.red,
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

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[700])),
                  const SizedBox(height: 8),
                  Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: color)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 8),
            Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700])),
          ],
        ),
      ),
    );
  }
}