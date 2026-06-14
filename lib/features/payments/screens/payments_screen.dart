import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:civilhelp/shared/layouts/app_scaffold.dart';
import 'package:civilhelp/shared/widgets/module_header.dart';
import 'package:civilhelp/features/labour/presentation/providers/labour_provider.dart';
import 'package:civilhelp/features/sites/providers/site_provider.dart';
import '../models/payment_model.dart';
import '../providers/payment_provider.dart';

import '../widgets/payment_card.dart';
import '../../labour/data/models/labour_model.dart';
import '../../sites/models/site_model.dart';

class PaymentsScreen extends ConsumerWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(paymentsStreamProvider);
    final sitesAsync = ref.watch(sitesStreamProvider);
    final labourAsync = ref.watch(labourStreamProvider);

    final FloatingActionButton? fab = paymentsAsync.when(
      data: (payments) => payments.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: () {
                _showNewPaymentDialog(context, ref, sitesAsync, labourAsync);
              },
              tooltip: 'Create Payment',
              child: const Icon(Icons.add),
            ),
      loading: () => null,
      error: (_, _) => null,
    );

    return AppScaffold(
      fab: fab,
      child: Column(
        children: [
          const ModuleHeader(
            title: 'Payments',
            subtitle: 'Disburse and track labour wage payouts',
            showBackButton: true,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: paymentsAsync.when(
                data: (payments) {
                  if (payments.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.money, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No payments recorded yet',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create payments after attendance is recorded for labour',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              _showNewPaymentDialog(
                                context,
                                ref,
                                sitesAsync,
                                labourAsync,
                              );
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Create Payment'),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: payments.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final payment = payments[index];
                      return PaymentCard(
                        payment: payment,
                        onMarkPaid: () async {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const Center(child: CircularProgressIndicator()),
                          );

                          try {
                            final finalSummary = await ref.read(paymentRepositoryProvider).calculateFinalPaymentSummary(payment);
                            
                            if (context.mounted) {
                              Navigator.of(context).pop(); // dismiss loading
                              _confirmAction(
                                context,
                                ref,
                                title: 'Mark Payment as Paid',
                                content: 'Have you disbursed ₹${finalSummary.netAmount.toStringAsFixed(0)} to ${payment.labourName}?\n\nThis will formally recover any allocated advances.',
                                actionText: 'Confirm Paid',
                                actionColor: Colors.green,
                                onConfirm: () async {
                                  await ref.read(markPaymentPaidProvider(payment.id).future);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Payment marked as paid')),
                                    );
                                  }
                                },
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              Navigator.of(context).pop(); // dismiss loading
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error calculating final amount: $e')),
                              );
                            }
                          }
                        },
                        onCancelPayment: () => _confirmAction(
                          context,
                          ref,
                          title: 'Cancel Payment',
                          content: 'Are you sure you want to cancel this pending payment for ${payment.labourName}?',
                          actionText: 'Cancel Payment',
                          actionColor: Colors.orange,
                          onConfirm: () async {
                            await ref.read(updatePaymentStatusProvider((payment.id, 'cancelled')).future);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Payment cancelled')),
                              );
                            }
                          },
                        ),
                        onDelete: () {
                          _showDeletePaymentDialog(context, ref, payment);
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) =>
                    Center(child: Text('Failed to load payments: $error')),
              ),
            ),
          ],
        ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmAction(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String content,
    required String actionText,
    required Color actionColor,
    required Future<void> Function() onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: actionColor),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await onConfirm();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: Text(actionText),
          ),
        ],
      ),
    );
  }

  void _showDeletePaymentDialog(
    BuildContext context,
    WidgetRef ref,
    PaymentModel payment,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Payment'),
        content: Text('Delete payment for ${payment.labourName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await ref.read(deletePaymentProvider(payment.id).future);

              if (context.mounted) {
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payment deleted')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showNewPaymentDialog(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<SiteModel>> sitesAsync,
    AsyncValue<List<LabourModel>> labourAsync,
  ) {
    final formKey = GlobalKey<FormState>();
    DateTime periodStart = DateTime.now().subtract(const Duration(days: 7));
    DateTime periodEnd = DateTime.now();
    String? selectedSiteId;
    String? selectedLabourId;
    PaymentSummary? paymentSummary;
    bool isCalculating = false;
    bool isSaving = false;
    String? inlineValidationMessage;

    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            void clearValidation() {
              if (inlineValidationMessage != null) {
                setState(() {
                  inlineValidationMessage = null;
                });
              }
            }

            Future<void> recalculatePayment() async {
              clearValidation();

              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              final normStart = DateTime(periodStart.year, periodStart.month, periodStart.day);
              final normEnd = DateTime(periodEnd.year, periodEnd.month, periodEnd.day);

              if (normStart.isAfter(normEnd)) {
                setState(() {
                  inlineValidationMessage =
                      'Period start date must be before or equal to period end date.';
                  paymentSummary = null;
                });
                return;
              }

              if (normStart.isAfter(today)) {
                setState(() {
                  inlineValidationMessage =
                      'Period start date cannot be in the future.';
                  paymentSummary = null;
                });
                return;
              }

              if (normEnd.isAfter(today)) {
                setState(() {
                  inlineValidationMessage =
                      'Period end date cannot be in the future.';
                  paymentSummary = null;
                });
                return;
              }

              if (selectedLabourId == null || selectedSiteId == null) {
                setState(() {
                  paymentSummary = null;
                });
                return;
              }

              setState(() {
                paymentSummary = null;
                isCalculating = true;
              });

              try {
                final labour = labourAsync.valueOrNull?.firstWhere(
                  (l) => l.id == selectedLabourId,
                  orElse: () => throw Exception('Labour not found'),
                );

                if (labour != null) {
                  final summary = await ref.read(
                    calculatePaymentProvider((
                      labour.id,
                      selectedSiteId!,
                      labour.dailyWage,
                      periodStart,
                      periodEnd,
                    )).future,
                  );

                  if (context.mounted) {
                    setState(() {
                      paymentSummary = summary;
                      isCalculating = false;
                      if (summary.grossAmount <= 0) {
                        inlineValidationMessage =
                            'No payable attendance found for the selected period.';
                      }
                    });
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  setState(() {
                    paymentSummary = null;
                    isCalculating = false;
                  });
                }
              }
            }

            return AlertDialog(
              title: const Text('Create Pending Payment'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: selectedSiteId,
                        decoration: const InputDecoration(labelText: 'Site'),
                        items: sitesAsync.when(
                          data: (sites) => sites
                              .map(
                                (site) => DropdownMenuItem(
                                  value: site.id,
                                  child: Text(site.name),
                                ),
                              )
                              .toList(),
                          loading: () => const [],
                          error: (_, _) => const [],
                        ),
                        onChanged: (value) {
                          setState(() {
                            selectedSiteId = value;
                          });
                          recalculatePayment();
                        },
                        validator: (value) =>
                            value == null ? 'Select a site' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedLabourId,
                        decoration: const InputDecoration(labelText: 'Labour'),
                        items: labourAsync.when(
                          data: (labour) => labour
                              .map(
                                (entry) => DropdownMenuItem(
                                  value: entry.id,
                                  child: Text(entry.fullName),
                                ),
                              )
                              .toList(),
                          loading: () => const [],
                          error: (_, _) => const [],
                        ),
                        onChanged: (value) {
                          setState(() {
                            selectedLabourId = value;
                          });
                          recalculatePayment();
                        },
                        validator: (value) =>
                            value == null ? 'Select a labour' : null,
                      ),
                      TextButton(
                        onPressed: () async {
                          final today = DateTime.now();
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: periodStart.isAfter(today) ? today : periodStart,
                            firstDate: today.subtract(
                              const Duration(days: 365),
                            ),
                            lastDate: periodEnd.isBefore(today) ? periodEnd : today,
                          );
                          if (picked != null) {
                            setState(() {
                              periodStart = picked;
                            });
                            recalculatePayment();
                          }
                        },
                        child: Text(
                          'Period start: ${periodStart.toLocal().toShortDateString()}',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () async {
                          final today = DateTime.now();
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: periodEnd.isAfter(today) ? today : periodEnd,
                            firstDate: periodStart,
                            lastDate: today,
                          );
                          if (picked != null) {
                            setState(() {
                              periodEnd = picked;
                            });
                            recalculatePayment();
                          }
                        },
                        child: Text(
                          'Period end: ${periodEnd.toLocal().toShortDateString()}',
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (inlineValidationMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            inlineValidationMessage!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (isCalculating)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: SizedBox(
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      else if (paymentSummary != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Gross Amount: ₹${paymentSummary!.grossAmount.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Projected Advance Deduction: ₹${paymentSummary!.advancesTotal.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Net Payable: ₹${paymentSummary!.netAmount.toStringAsFixed(2)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: (isCalculating ||
                          isSaving ||
                          periodStart.isAfter(periodEnd) ||
                          paymentSummary == null ||
                          paymentSummary!.grossAmount <= 0)
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }

                          final selectedSite = sitesAsync.valueOrNull?.firstWhere(
                            (site) => site.id == selectedSiteId,
                          );
                          final selectedLabour =
                              labourAsync.valueOrNull?.firstWhere(
                            (labour) => labour.id == selectedLabourId,
                          );

                          if (selectedSite == null || selectedLabour == null) {
                            return;
                          }

                          setState(() {
                            isSaving = true;
                            clearValidation();
                          });

                          // Manual payment creation: overlap check is not applicable
                          // (this flow is deprecated and will be removed in Issue #4).
                          // Pass empty periodId so hasOverlappingPayment returns false.
                          final isDuplicate = await ref.read(
                            hasOverlappingPaymentProvider((
                              selectedLabour.id,
                              '',
                            )).future,
                          );

                          if (isDuplicate) {
                            if (context.mounted) {
                              setState(() {
                                isSaving = false;
                                inlineValidationMessage =
                                    'Payment periods cannot overlap. A payment already exists for these dates.';
                              });
                            }
                            return;
                          }

                          final grossPayment =
                              paymentSummary!.grossAmount;

                          try {
                            final payment = await ref.read(
                              createPaymentProvider((
                                selectedLabour.id,
                                selectedLabour.fullName,
                                selectedSite.id,
                                selectedSite.name,
                                periodStart,
                                periodEnd,
                                grossPayment,
                              )).future,
                            );

                            if (context.mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Pending payment created for ${payment.labourName}',
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              setState(() {
                                isSaving = false;
                                inlineValidationMessage = e.toString();
                              });
                            }
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

extension on DateTime {
  String toShortDateString() {
    return '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/${year.toString()}';
  }
}

