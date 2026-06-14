import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:civilhelp/app/theme.dart';
import 'package:civilhelp/core/providers/company_provider.dart';

import 'package:civilhelp/shared/layouts/app_scaffold.dart';
import 'package:civilhelp/features/sites/providers/site_provider.dart';
import 'package:civilhelp/features/labour/presentation/providers/labour_provider.dart';
import '../models/report_filter.dart';
import '../providers/report_provider.dart';
import '../providers/pdf_provider.dart';
import '../models/worker_ledger_entry.dart';
import '../models/worker_ledger_report_dto.dart';
import '../widgets/report_filter_bar.dart';

class WorkerLedgerScreen extends ConsumerStatefulWidget {
  const WorkerLedgerScreen({super.key});

  @override
  ConsumerState<WorkerLedgerScreen> createState() => _WorkerLedgerScreenState();
}

class _WorkerLedgerScreenState extends ConsumerState<WorkerLedgerScreen> {
  String? _selectedSiteId;
  String? _selectedLabourId;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    debugPrint('WorkerLedgerScreen build called');
    final companyIdAsync = ref.watch(userCompanyIdProvider);
    
    debugPrint('companyIdAsync: $companyIdAsync');

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Worker Ledger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export PDF',
            onPressed: () {
                // Only attempt export when companyId is resolved.
                companyIdAsync.when(
                  data: (companyId) {
                    if (companyId.isEmpty) return;
                    _handleExportPdf(context, companyId);
                  },
                  loading: () async {},
                  error: (e, _) async {},
                );
              },
          ),
        ],
      ),
      child: companyIdAsync.when(
        data: (companyId) {
                  debugPrint('companyIdAsync data: $companyId');
          if (companyId.isEmpty) {
            return const Center(child: Text('Company not associated with user.'));
          }

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
      siteId: _selectedSiteId,
    );

    final reportAsync = ref.watch(workerLedgerReportProvider(filter));
    debugPrint('workerLedgerReportProvider state: $reportAsync');


    return reportAsync.when(
      data: (report) {
        return Column(
          children: [
            _buildSummaryCards(report),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
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
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      color: context.colors.surfaceVariant,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SummaryStat(title: 'Earned', value: currencyFmt.format(report.totalEarned), color: context.customColors.success),
              _SummaryStat(title: 'Advances', value: currencyFmt.format(report.totalAdvances), color: context.customColors.advance),
              _SummaryStat(title: 'Paid', value: currencyFmt.format(report.totalPayments), color: context.customColors.payroll),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Outstanding Balance: ',
                style: context.text.titleMedium,
              ),
              Text(
                currencyFmt.format(report.outstandingBalance),
                style: context.text.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: report.outstandingBalance > 0 ? context.customColors.error : context.customColors.success,
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
        iconColor = context.customColors.success;
        break;
      case LedgerEntryType.advance:
        icon = Icons.money_off;
        iconColor = context.customColors.advance;
        break;
      case LedgerEntryType.payment:
        icon = Icons.payments;
        iconColor = context.customColors.payroll;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding, vertical: 4.0),
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
              Text('+ ${currencyFmt.format(entry.credit)}', style: TextStyle(color: context.customColors.success, fontWeight: FontWeight.bold)),
            if (entry.debit > 0)
              Text('- ${currencyFmt.format(entry.debit)}', style: TextStyle(color: context.customColors.error, fontWeight: FontWeight.bold)),
            Text('Bal: ${currencyFmt.format(entry.runningBalance)}', style: TextStyle(fontSize: 12, color: context.colors.outline)),
          ],
        ),
      ),
    );
  }

  Future<void> _handleExportPdf(BuildContext context, String? companyId) async {
    if (companyId == null) return;

    if (_selectedLabourId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a worker to export.')),
      );
      return;
    }

    final filter = ReportFilter(
      companyId: companyId,
      startDate: _startDate,
      endDate: DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59),
      labourId: _selectedLabourId,
      siteId: _selectedSiteId,
    );

    try {
      final report = await ref.read(workerLedgerReportProvider(filter).future);

      if (report.entries.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No data available to export.')),
        );
        return;
      }

      // Fetch names for header
      String workerName = 'All Workers';
      if (_selectedLabourId != null) {
        final labours = await ref.read(labourStreamProvider.future);
        final labour = labours.where((l) => l.id == _selectedLabourId).firstOrNull;
        if (labour != null) workerName = labour.fullName;
      }

      String siteName = 'All Sites';
      if (_selectedSiteId != null) {
        final sites = await ref.read(sitesStreamProvider.future);
        final site = sites.where((s) => s.id == _selectedSiteId).firstOrNull;
        if (site != null) siteName = site.name;
      }

      final pdfService = ref.read(pdfServiceProvider);
      
      // In a real app, you might want to get the actual company name from a provider
      final companyName = 'CivilHelp Construction';

      await pdfService.previewWorkerLedgerPdf(
        report: report,
        filter: filter,
        companyName: companyName,
        workerName: workerName,
        siteName: siteName,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate PDF: $e')),
      );
    }
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
        Text(title, style: TextStyle(color: context.colors.onSurfaceVariant, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}
