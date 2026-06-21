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

class PaymentReportScreen extends ConsumerStatefulWidget {
  const PaymentReportScreen({super.key});

  @override
  ConsumerState<PaymentReportScreen> createState() => _PaymentReportScreenState();
}

class _PaymentReportScreenState extends ConsumerState<PaymentReportScreen> {
  String? _selectedSiteId;
  String? _selectedLabourId;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final companyIdAsync = ref.watch(userCompanyIdProvider);

    return AppScaffold(
      child: Column(
        children: [
          const ModuleHeader(
            title: 'Payment Report',
            subtitle: 'Overview of wages paid to workers',
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

    final reportAsync = ref.watch(paymentReportProvider(filter));

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
                        backgroundColor: context.customColors.payroll.withValues(alpha: 0.2),
                        child: Icon(Icons.payment, color: context.customColors.payroll, size: 30),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Net Payable Settled', style: context.text.titleMedium?.copyWith(color: context.colors.onSurfaceVariant)),
                            const SizedBox(height: 8),
                            Text(
                              currencyFmt.format(report.totalPayments),
                              style: context.text.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: context.customColors.payroll,
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
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        report.paymentCount.toString(),
                        style: context.text.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.customColors.info,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Payment Count', style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant)),
                    ],
                  ),
                ),
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

