import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:civilhelp/app/theme.dart';
import 'package:civilhelp/app/router.dart';
import 'package:civilhelp/core/providers/company_provider.dart';
import '../../../shared/layouts/app_scaffold.dart';
import '../../../shared/widgets/module_header.dart';
import '../../../shared/widgets/premium_module_card.dart';
import '../../../shared/widgets/app_design_system.dart';
import '../../../shared/widgets/module_empty_state.dart';
import '../../../shared/widgets/operational_metrics_strip.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../../shared/widgets/metric_card.dart';
import '../providers/payroll_providers.dart';
import '../models/payroll_period_model.dart';
import 'payroll_processing_screen.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

class PayrollDashboardScreen extends ConsumerWidget {
  const PayrollDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final periodsAsync = ref.watch(payrollPeriodsStreamProvider);
    final companyId = ref.watch(userCompanyIdProvider).value ?? '';
    final firestore = ref.watch(firestoreProvider);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: companyId.isNotEmpty
          ? firestore
              .collection('companies/$companyId/payrollSummaries')
              .snapshots()
          : const Stream.empty(),
      builder: (context, snapshot) {
        double totalPayout = 0.0;
        if (snapshot.hasData) {
          for (final doc in snapshot.data!.docs) {
            totalPayout += (doc.data()['totalNetPaid'] as num?)?.toDouble() ?? 0.0;
          }
        }

        return AppScaffold(
          fab: FloatingActionButton.extended(
            onPressed: () => _showCreatePeriodDialog(context, ref),
            label: const Text('New Period', style: TextStyle(fontWeight: FontWeight.bold)),
            icon: const Icon(Icons.add),
            backgroundColor: context.colors.primary,
            foregroundColor: context.colors.onPrimary,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ModuleHeader(
                title: 'Payroll Dashboard',
                subtitle: 'Manage and settle worker payroll periods',
                showBackButton: false,
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: context.colors.background,
                  ),
                  child: periodsAsync.when(
                    data: (periods) {
                      if (periods.isEmpty) {
                        return ModuleEmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: 'No Payroll Periods',
                          description: 'Create a new payroll period to calculate, freeze, and settle worker salaries.',
                          ctaLabel: 'Create Payroll Period',
                          onCta: () => _showCreatePeriodDialog(context, ref),
                          iconColor: AppDesignSystem.payrollColor,
                        );
                      }

                      // Metrics calculations
                      final openPeriods = periods.where((p) => p.status == 'open').length;
                      final pendingPayroll = periods.where((p) => p.status == 'open' || p.status == 'frozen').length;
                      final processedPayroll = periods.where((p) => p.status == 'paid').length;

                      return SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Hero Metrics Strip
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24.0,
                                vertical: 12.0,
                              ),
                              child: OperationalMetricsStrip(
                                metrics: [
                                  OperationalMetricData(
                                    label: 'Open Periods',
                                    value: '$openPeriods',
                                    icon: Icons.lock_open_outlined,
                                    color: context.customColors.warning,
                                  ),
                                  OperationalMetricData(
                                    label: 'Pending Payroll',
                                    value: '$pendingPayroll',
                                    icon: Icons.pending_actions_outlined,
                                    color: context.customColors.attendance,
                                  ),
                                  OperationalMetricData(
                                    label: 'Processed Payroll',
                                    value: '$processedPayroll',
                                    icon: Icons.check_circle_outline,
                                    color: context.customColors.success,
                                  ),
                                  OperationalMetricData(
                                    label: 'Total Payout',
                                    value: '₹${totalPayout.toStringAsFixed(0)}',
                                    icon: Icons.currency_rupee_outlined,
                                    color: context.customColors.payroll,
                                  ),
                                ],
                              ),
                            ),
  
                            // Quick Actions Row
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24.0,
                                vertical: 8.0,
                              ),
                              child: Wrap(
                                spacing: 12,
                                runSpacing: 8,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () => _showCreatePeriodDialog(context, ref),
                                    icon: const Icon(Icons.add, size: 18),
                                    label: const Text('Create Payroll', style: TextStyle(fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: context.colors.primary,
                                      foregroundColor: context.colors.onPrimary,
                                      elevation: 0,
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      final processable = periods.cast<PayrollPeriodModel?>().firstWhere(
                                        (p) => p?.status != 'paid',
                                        orElse: () => null,
                                      );
                                      if (processable != null) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => PayrollProcessingScreen(periodId: processable.id),
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('No open or frozen payroll period to process.')),
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.payment_outlined, size: 18),
                                    label: const Text('Process Payroll'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: context.colors.primary,
                                      side: BorderSide(color: context.colors.primary),
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () => Navigator.of(context).pushNamed(AppRoutes.payments),
                                    icon: const Icon(Icons.history_outlined, size: 18),
                                    label: const Text('Payment Records'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: context.colors.primary,
                                      side: BorderSide(color: context.colors.primary),
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () => Navigator.of(context).pushNamed(AppRoutes.paymentReport),
                                    icon: const Icon(Icons.assessment_outlined, size: 18),
                                    label: const Text('Payment Reports'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: context.colors.primary,
                                      side: BorderSide(color: context.colors.primary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
  
                            const SizedBox(height: 12),
  
                            // Dynamic Grid
                            _buildPeriodsList(context, ref, periods),
                          ],
                        ),
                      );
                    },
                    loading: () => Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(context.colors.primary),
                      ),
                    ),
                    error: (err, _) => ModuleEmptyState(
                      icon: Icons.error_outline,
                      title: 'Failed to Load Payroll',
                      description: err.toString(),
                      iconColor: context.colors.error,
                      ctaLabel: 'Retry',
                      onCta: () => ref.invalidate(payrollPeriodsStreamProvider),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPeriodsList(
      BuildContext context, WidgetRef ref, List<PayrollPeriodModel> periods) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth;
        final isMobile = availableWidth < 650;

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 24.0,
            vertical: 16.0,
          ),
          child: Wrap(
            spacing: 20,
            runSpacing: 20,
            children: periods.map((period) {
              final double cardWidth = isMobile
                  ? (availableWidth - 48.0)
                  : (availableWidth - 48.0 - 20.0) / 2.0;

              return SizedBox(
                width: cardWidth.clamp(0.0, double.infinity),
                child: _buildPeriodCard(context, ref, period),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildPeriodCard(
      BuildContext context, WidgetRef ref, PayrollPeriodModel period) {
    final fmt = DateFormat('dd MMM yyyy');
    final startStr = fmt.format(period.startDate);
    final endStr = fmt.format(period.endDate);

    return PremiumModuleCard(
      glowColor: context.customColors.payroll,
      onTap: () {
        if (period.status != 'paid') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PayrollProcessingScreen(periodId: period.id),
            ),
          );
        } else {
          _showSummaryDialog(context, ref, period);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  period.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: context.colors.primary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              StatusChip(status: period.status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.date_range, size: 16, color: context.colors.outline),
              const SizedBox(width: 8),
              Text(
                '$startStr – $endStr',
                style: TextStyle(color: context.colors.onSurfaceVariant, fontSize: 14),
              ),
            ],
          ),
          if (period.status == 'paid') ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            _buildSummaryPreviewRow(context, ref, period),
          ],
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              if (period.status == 'open') ...[
                OutlinedButton.icon(
                  onPressed: () => _freezePeriod(context, ref, period.id),
                  icon: const Icon(Icons.lock, size: 16),
                  label: const Text('Freeze'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.customColors.warning,
                    side: BorderSide(color: context.customColors.warning),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PayrollProcessingScreen(periodId: period.id),
                      ),
                    );
                  },
                  icon: const Icon(Icons.payment, size: 16),
                  label: const Text('Process'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.primary,
                    foregroundColor: context.colors.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
              if (period.status == 'frozen') ...[
                OutlinedButton.icon(
                  onPressed: () => _reopenPeriod(context, ref, period.id),
                  icon: const Icon(Icons.lock_open, size: 16),
                  label: const Text('Reopen'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.colors.primary,
                    side: BorderSide(color: context.colors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PayrollProcessingScreen(periodId: period.id),
                      ),
                    );
                  },
                  icon: const Icon(Icons.payment, size: 16),
                  label: const Text('Settle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.customColors.success,
                    foregroundColor: context.colors.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
              if (period.status == 'paid')
                OutlinedButton.icon(
                  onPressed: () => _showSummaryDialog(context, ref, period),
                  icon: const Icon(Icons.analytics, size: 16),
                  label: const Text('View Summary'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.colors.primary,
                    side: BorderSide(color: context.colors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryPreviewRow(BuildContext context, WidgetRef ref, PayrollPeriodModel period) {
    final summaryAsync = ref.watch(payrollSummaryStreamProvider(period.id));
    return summaryAsync.when(
      data: (summary) {
        if (summary == null) return const SizedBox.shrink();
        return LayoutBuilder(
          builder: (context, constraints) {
            final double width = constraints.maxWidth;
            final useTwoRows = width < 450;

            final workersCard = MetricCard(
              label: 'Workers',
              value: '${summary.totalWorkers}',
              icon: Icons.people,
              color: context.colors.primary,
            );

            final grossCard = MetricCard(
              label: 'Gross',
              value: '₹${summary.totalGross.toStringAsFixed(0)}',
              icon: Icons.account_balance_wallet,
              color: context.colors.primary,
            );

            final deductionsCard = MetricCard(
              label: 'Deductions',
              value: '₹${summary.totalDeductions.toStringAsFixed(0)}',
              icon: Icons.remove_circle_outline,
              color: context.customColors.warning,
            );

            final netCard = MetricCard(
              label: 'Net Settled',
              value: '₹${summary.totalNetPaid.toStringAsFixed(0)}',
              icon: Icons.check_circle_outline,
              color: context.customColors.success,
            );

            if (useTwoRows) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      workersCard,
                      const SizedBox(width: 8),
                      grossCard,
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      deductionsCard,
                      const SizedBox(width: 8),
                      netCard,
                    ],
                  ),
                ],
              );
            }

            return Row(
              children: [
                workersCard,
                const SizedBox(width: 8),
                grossCard,
                const SizedBox(width: 8),
                deductionsCard,
                const SizedBox(width: 8),
                netCard,
              ],
            );
          },
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (_, e) => const Text('Failed to load summary details'),
    );
  }

  void _showCreatePeriodDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _CreatePeriodDialog(ref: ref),
    );
  }

  // ---------------------------------------------------------------------------
  // Period actions
  // ---------------------------------------------------------------------------

  void _freezePeriod(BuildContext context, WidgetRef ref, String periodId) async {
    try {
      await ref.read(freezePayrollPeriodProvider(periodId).future);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payroll period frozen successfully.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to freeze: $e'),
          backgroundColor: context.colors.error,
        ),
      );
    }
  }

  void _reopenPeriod(BuildContext context, WidgetRef ref, String periodId) async {
    try {
      await ref.read(reopenPayrollPeriodProvider(periodId).future);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payroll period reopened successfully.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reopen: $e'),
          backgroundColor: context.colors.error,
        ),
      );
    }
  }

  void _showSummaryDialog(BuildContext context, WidgetRef ref, PayrollPeriodModel period) {
    final summaryAsync = ref.watch(payrollSummaryStreamProvider(period.id));

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            '${period.name} — Summary',
            style: TextStyle(fontWeight: FontWeight.bold, color: context.colors.primary),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: summaryAsync.when(
            data: (summary) {
              if (summary == null) {
                return const Text('No summary snapshot available for this period.');
              }
              final currencyFmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSummaryItem(context, 'Total Workers', '${summary.totalWorkers}'),
                  _buildSummaryItem(
                      context, 'Total Gross Earnings', currencyFmt.format(summary.totalGross)),
                  _buildSummaryItem(
                      context, 'Total Advance Deductions', currencyFmt.format(summary.totalDeductions)),
                  const Divider(),
                  _buildSummaryItem(
                    context,
                    'Net Settled Amount',
                    currencyFmt.format(summary.totalNetPaid),
                    isBold: true,
                    color: context.customColors.success,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Settled on ${DateFormat('dd MMM yyyy hh:mm a').format(summary.createdAt)}',
                    style: TextStyle(fontSize: 10, color: context.colors.outline),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Text('Error loading summary: $err'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close', style: TextStyle(color: context.colors.primary)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryItem(BuildContext context, String label, String value,
      {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: context.colors.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color ?? context.colors.onSurface,
              fontSize: isBold ? 16 : 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── Dialog Stateful Widget ───────────────────────────────────────────────

class _CreatePeriodDialog extends StatefulWidget {
  final WidgetRef ref;
  const _CreatePeriodDialog({required this.ref});

  @override
  State<_CreatePeriodDialog> createState() => _CreatePeriodDialogState();
}

class _CreatePeriodDialogState extends State<_CreatePeriodDialog> {
  late DateTime selectedStart;
  late DateTime selectedEnd;
  late final TextEditingController nameController;
  final fmt = DateFormat('dd MMM yyyy');
  bool nameWasEdited = false;
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedStart = DateTime(now.year, now.month, 1);
    selectedEnd = DateTime(now.year, now.month + 1, 0);
    final periodName = '${fmt.format(selectedStart)} – ${fmt.format(selectedEnd)}';
    nameController = TextEditingController(text: periodName);
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  void updateSuggestedName() {
    if (!nameWasEdited) {
      final suggested = '${fmt.format(selectedStart)} – ${fmt.format(selectedEnd)}';
      nameController.text = suggested;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('create_payroll_dialog'),
      title: Text(
        'New Payroll Period',
        style: TextStyle(fontWeight: FontWeight.bold, color: context.colors.primary),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Start Date
            _buildDatePickerRow(
              context: context,
              label: 'Start Date',
              date: selectedStart,
              onTap: isLoading ? () {} : () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedStart,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null) {
                  setState(() {
                    selectedStart = picked;
                    // Ensure end >= start
                    if (selectedEnd.isBefore(selectedStart)) {
                      selectedEnd = selectedStart.add(const Duration(days: 13));
                    }
                    updateSuggestedName();
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            // End Date
            _buildDatePickerRow(
              context: context,
              label: 'End Date',
              date: selectedEnd,
              onTap: isLoading ? () {} : () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedEnd,
                  firstDate: selectedStart.add(const Duration(days: 1)),
                  lastDate: DateTime(2030),
                );
                if (picked != null) {
                  setState(() {
                    selectedEnd = picked;
                    updateSuggestedName();
                  });
                }
              },
            ),
            const SizedBox(height: 20),
            // Period Name
            TextFormField(
              controller: nameController,
              enabled: !isLoading,
              decoration: InputDecoration(
                labelText: 'Period Name',
                hintText: 'e.g. Site A Fortnight 1',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: const Icon(Icons.edit, size: 18),
              ),
              onChanged: (val) {
                // Mark as manually edited so auto-suggest stops overwriting
                nameWasEdited = val.trim().isNotEmpty &&
                    val.trim() != '${fmt.format(selectedStart)} – ${fmt.format(selectedEnd)}';
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Leave name as-is to use the auto-generated label.',
              style: TextStyle(fontSize: 11, color: context.colors.onSurfaceVariant),
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                key: const Key('dialog_error_text'),
                style: TextStyle(
                  color: context.colors.error,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isLoading
              ? null
              : () {
                  Navigator.pop(context);
                },
          child: Text('Cancel', style: TextStyle(color: context.colors.outline)),
        ),
        ElevatedButton(
          onPressed: isLoading
              ? null
              : () async {
                  setState(() {
                    isLoading = true;
                    errorMessage = null;
                  });
                  final name = nameController.text.trim();
                  try {
                    await widget.ref.read(createPayrollPeriodProvider((
                      name: name,
                      startDate: selectedStart,
                      endDate: selectedEnd,
                    )).future);

                    if (!context.mounted) return;
                    Navigator.pop(context); // Pop ONLY on success

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Payroll period created successfully.'),
                        backgroundColor: context.customColors.success,
                      ),
                    );
                  } catch (e) {
                    setState(() {
                      isLoading = false;
                      errorMessage = e.toString();
                    });
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: context.colors.primary,
            foregroundColor: context.colors.onPrimary,
          ),
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(context.colors.onPrimary),
                  ),
                )
              : const Text('Create'),
        ),
      ],
    );
  }

  Widget _buildDatePickerRow({
    required BuildContext context,
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    final fmt = DateFormat('dd MMM yyyy');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: context.colors.outline.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 18, color: context.colors.primary),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: context.colors.onSurfaceVariant),
                ),
                const SizedBox(height: 2),
                Text(
                  fmt.format(date),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: context.colors.primary,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Icon(Icons.arrow_drop_down, color: context.colors.outline),
          ],
        ),
      ),
    );
  }
}
