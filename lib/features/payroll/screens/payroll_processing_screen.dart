import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:civilhelp/app/theme.dart';
import '../../../shared/layouts/app_scaffold.dart';
import '../providers/payroll_providers.dart';
import '../repositories/payroll_repository.dart';

class PayrollProcessingScreen extends ConsumerStatefulWidget {
  final String periodId;

  const PayrollProcessingScreen({super.key, required this.periodId});

  @override
  ConsumerState<PayrollProcessingScreen> createState() => _PayrollProcessingScreenState();
}

class _PayrollProcessingScreenState extends ConsumerState<PayrollProcessingScreen> {
  final Map<String, double> _deductionOverrides = {};
  String _paymentMode = 'cash';
  bool _isSettling = false;

  @override
  Widget build(BuildContext context) {
    final periodAsync = ref.watch(payrollPeriodStreamProvider(widget.periodId));
    final calculationsAsync = ref.watch(payrollCalculationProvider(widget.periodId));

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Process Payroll', style: TextStyle(fontWeight: FontWeight.bold)),
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
      child: Stack(
        children: [
          periodAsync.when(
            data: (period) {
              if (period == null) {
                return const Center(child: Text('Payroll period not found.'));
              }
              return calculationsAsync.when(
                data: (calcs) {
                  if (calcs.isEmpty) {
                    return _buildEmptyState(context);
                  }
                  return _buildProcessingUI(context, period, calcs);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error loading calculations: $err')),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error loading period: $err')),
          ),
          if (_isSettling)
            Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: Center(
                child: Card(
                  margin: const EdgeInsets.all(32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(context.colors.primary),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Settling Payroll...',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Updating balances, recovery ledgers, and attendance stamps.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: context.colors.outline, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_rounded, size: 64, color: context.customColors.warning),
            const SizedBox(height: 16),
            const Text(
              'No Payable Attendance Found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'There are no active unpaid attendance records logged for workers in this payroll period.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.colors.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: context.colors.primary),
              child: const Text('Back to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingUI(BuildContext context, dynamic period, List<PayrollCalculationResult> calcs) {
    final currencyFmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    
    // Compute totals
    double totalGross = 0.0;
    double totalDeductions = 0.0;
    double totalNet = 0.0;

    for (final calc in calcs) {
      final deduction = _deductionOverrides[calc.labourId] ?? calc.advanceDeductions;
      totalGross += calc.grossEarnings;
      totalDeductions += deduction;
      totalNet += (calc.grossEarnings - deduction);
    }

    return Column(
      children: [
        // Top summary banner
        Container(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          color: context.colors.surfaceVariant,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryStat('Workers', '${calcs.length}', context.colors.onSurface),
              _buildSummaryStat('Total Gross', currencyFmt.format(totalGross), context.colors.onSurface),
              _buildSummaryStat('Deductions', currencyFmt.format(totalDeductions), context.customColors.advance),
              _buildSummaryStat('Net Payable', currencyFmt.format(totalNet), context.customColors.success),
            ],
          ),
        ),
        const Divider(height: 1),
        // Workers List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: calcs.length,
            itemBuilder: (context, index) {
              final calc = calcs[index];
              final double initialDeduction = calc.advanceDeductions;
              final double currentDeduction = _deductionOverrides[calc.labourId] ?? initialDeduction;
              final double netPayable = calc.grossEarnings - currentDeduction;

              return Card(
                elevation: 1.5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            calc.labourName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            '${calc.presentDays} Days Present',
                            style: TextStyle(color: context.colors.onSurfaceVariant, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildDetailCol('Gross Earnings', currencyFmt.format(calc.grossEarnings)),
                          _buildEditableDeductionCol(calc, currentDeduction),
                          _buildDetailCol('Net Payable', currencyFmt.format(netPayable), isBold: true, color: context.customColors.success),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // Bottom Action Bar
        Container(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          decoration: BoxDecoration(
            color: context.colors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: context.isDarkMode ? 0.2 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: _paymentMode,
                    dropdownColor: context.colors.surface,
                    decoration: const InputDecoration(
                      labelText: 'Payment Mode',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'cash', child: Text('Cash')),
                      DropdownMenuItem(value: 'upi', child: Text('UPI')),
                      DropdownMenuItem(value: 'bankTransfer', child: Text('Bank Transfer')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _paymentMode = val);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: () => _finalizePayroll(context, period, calcs, totalNet),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Finalize & Settle', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colors.primary,
                      foregroundColor: context.colors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: context.colors.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildDetailCol(String label, String value, {bool isBold = false, Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: context.colors.outline)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: color ?? context.colors.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildEditableDeductionCol(PayrollCalculationResult calc, double currentDeduction) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Deduction', style: TextStyle(fontSize: 11, color: context.colors.outline)),
        const SizedBox(height: 4),
        SizedBox(
          width: 90,
          child: TextFormField(
            initialValue: currentDeduction.toStringAsFixed(0),
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              border: OutlineInputBorder(),
            ),
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.customColors.advance),
            onChanged: (val) {
              final amt = double.tryParse(val) ?? 0.0;
              // Limit deduction to grossEarnings
              final clamped = amt.clamp(0.0, calc.grossEarnings);
              setState(() {
                _deductionOverrides[calc.labourId] = clamped;
              });
            },
          ),
        ),
      ],
    );
  }

  void _finalizePayroll(BuildContext context, dynamic period, List<PayrollCalculationResult> calcs, double totalNet) async {
    // 1. Confirm Dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Payroll Settlement', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text(
            'Are you sure you want to finalize this payroll run?\n\n'
            'Total Net Payout: ₹${totalNet.toStringAsFixed(0)} via ${_paymentMode.toUpperCase()}.\n\n'
            'This action is permanently immutable. Attendance for this period will be marked as paid, and outstanding advances will be updated.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: TextStyle(color: context.colors.outline)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: context.colors.primary),
              child: const Text('Finalize'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _isSettling = true);

    try {
      // Create final calculation list with applied deduction overrides
      final List<PayrollCalculationResult> finalResults = calcs.map((calc) {
        final adjustedDeduction = _deductionOverrides[calc.labourId] ?? calc.advanceDeductions;
        final adjustedNet = calc.grossEarnings - adjustedDeduction;
        return PayrollCalculationResult(
          labourId: calc.labourId,
          labourName: calc.labourName,
          presentDays: calc.presentDays,
          grossEarnings: calc.grossEarnings,
          advanceDeductions: adjustedDeduction,
          netPayable: adjustedNet,
          attendanceIds: calc.attendanceIds,
        );
      }).toList();

      await ref.read(finalizePayrollProvider((
        periodId: widget.periodId,
        results: finalResults,
        paymentMode: _paymentMode,
      )).future);

      setState(() => _isSettling = false);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payroll settled and finalized successfully.')),
      );
      if (!context.mounted) return;
      Navigator.pop(context);
    } catch (e) {
      setState(() => _isSettling = false);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to finalize payroll: $e'), backgroundColor: context.colors.error),
      );
    }
  }
}
