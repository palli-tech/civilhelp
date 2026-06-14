import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:civilhelp/app/theme.dart';
import '../../../shared/layouts/app_scaffold.dart';
import '../../../shared/widgets/app_design_system.dart';
import '../../../shared/widgets/civil_empty_state.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../../shared/widgets/metric_card.dart';
import '../providers/payroll_providers.dart';
import '../models/payroll_period_model.dart';
import 'payroll_processing_screen.dart';


class PayrollDashboardScreen extends ConsumerWidget {
  const PayrollDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final periodsAsync = ref.watch(payrollPeriodsStreamProvider);

    return AppScaffold(
      appBar: AppBar(
        title: const Text(
          'Payroll Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [context.colors.primary, context.colors.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      fab: FloatingActionButton.extended(
        onPressed: () => _showCreatePeriodDialog(context, ref),
        label: const Text('New Period', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add),
        backgroundColor: context.colors.primary,
        foregroundColor: context.colors.onPrimary,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.background,
        ),
        child: periodsAsync.when(
          data: (periods) {
            if (periods.isEmpty) {
              return _buildEmptyState(context, ref);
            }
            return _buildPeriodsList(context, ref, periods);
          },
          loading: () => Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(context.colors.primary),
            ),
          ),
          error: (err, _) => Center(
            child: Text(
              'Error loading payroll: $err',
              style: TextStyle(color: context.colors.error, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return CivilEmptyState(
      icon: Icons.receipt_long_outlined,
      title: 'No Payroll Periods',
      description: 'Create a new payroll period to calculate, freeze, and settle worker salaries.',
      iconColor: AppDesignSystem.payrollColor,
      ctaLabel: 'Create Payroll Period',
      onCta: () => _showCreatePeriodDialog(context, ref),
    );
  }

  Widget _buildPeriodsList(
      BuildContext context, WidgetRef ref, List<PayrollPeriodModel> periods) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: periods.length,
      itemBuilder: (context, index) {
        final period = periods[index];
        return _buildPeriodCard(context, ref, period);
      },
    );
  }

  Widget _buildPeriodCard(
      BuildContext context, WidgetRef ref, PayrollPeriodModel period) {
    final fmt = DateFormat('dd MMM yyyy');
    final startStr = fmt.format(period.startDate);
    final endStr = fmt.format(period.endDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: context.surfaceGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.colors.outline.withValues(alpha: context.isDarkMode ? 0.15 : 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDarkMode ? 0.25 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
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
          child: Padding(
            padding: const EdgeInsets.all(20),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
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
                      const SizedBox(width: 12),
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
                      const SizedBox(width: 12),
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
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryPreviewRow(BuildContext context, WidgetRef ref, PayrollPeriodModel period) {
    final summaryAsync = ref.watch(payrollSummaryStreamProvider(period.id));
    return summaryAsync.when(
      data: (summary) {
        if (summary == null) return const SizedBox.shrink();
        return Row(
          children: [
            MetricCard(
              label: 'Workers',
              value: '${summary.totalWorkers}',
              icon: Icons.people,
              color: context.colors.primary,
            ),
            const SizedBox(width: 8),
            MetricCard(
              label: 'Gross',
              value: '₹${summary.totalGross.toStringAsFixed(0)}',
              icon: Icons.account_balance_wallet,
              color: context.colors.primary,
            ),
            const SizedBox(width: 8),
            MetricCard(
              label: 'Deductions',
              value: '₹${summary.totalDeductions.toStringAsFixed(0)}',
              icon: Icons.remove_circle_outline,
              color: context.customColors.warning,
            ),
            const SizedBox(width: 8),
            MetricCard(
              label: 'Net Settled',
              value: '₹${summary.totalNetPaid.toStringAsFixed(0)}',
              icon: Icons.check_circle_outline,
              color: context.customColors.success,
            ),
          ],
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
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: context.colors.onSurface,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color ?? context.colors.onSurface,
              fontSize: isBold ? 16 : 14,
            ),
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
