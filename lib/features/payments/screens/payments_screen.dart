import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:civilhelp/features/labour/presentation/providers/labour_provider.dart';
import 'package:civilhelp/features/sites/providers/site_provider.dart';
import '../providers/payment_provider.dart';
import '../../labour/data/models/labour_model.dart';
import '../../sites/models/site_model.dart';

class PaymentsScreen extends ConsumerWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(paymentsStreamProvider);
    final sitesAsync = ref.watch(sitesStreamProvider);
    final labourAsync = ref.watch(labourStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Payments backlog',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _showNewPaymentDialog(context, ref, sitesAsync, labourAsync);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Create Payment'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: paymentsAsync.when(
                data: (payments) {
                  if (payments.isEmpty) {
                    return const Center(
                      child: Text('No payments recorded yet.'),
                    );
                  }

                  return ListView.separated(
                    itemCount: payments.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final payment = payments[index];
                      return ListTile(
                        title: Text(payment.labourName),
                        subtitle: Text(
                          '${payment.siteName} • ${payment.status} • ${payment.periodStart.toLocal().toShortDateString()} - ${payment.periodEnd.toLocal().toShortDateString()}',
                        ),
                        trailing: Text('₹${payment.netAmount.toStringAsFixed(0)}'),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Failed to load payments: $error')),
              ),
            ),
          ],
        ),
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
    String paymentStatus = 'pending';

    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Create Payment'),
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
                              .map((site) => DropdownMenuItem(
                                    value: site.id,
                                    child: Text(site.name),
                                  ))
                              .toList(),
                          loading: () => const [],
                          error: (_, _) => const [],
                        ),
                        onChanged: (value) {
                          setState(() {
                            selectedSiteId = value;
                          });
                        },
                        validator: (value) => value == null ? 'Select a site' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedLabourId,
                        decoration: const InputDecoration(labelText: 'Labour'),
                        items: labourAsync.when(
                          data: (labour) => labour
                              .map((entry) => DropdownMenuItem(
                                    value: entry.id,
                                    child: Text(entry.fullName),
                                  ))
                              .toList(),
                          loading: () => const [],
                          error: (_, _) => const [],
                        ),
                        onChanged: (value) {
                          setState(() {
                            selectedLabourId = value;
                          });
                        },
                        validator: (value) => value == null ? 'Select a labour' : null,
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: periodStart,
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setState(() {
                              periodStart = picked;
                            });
                          }
                        },
                        child: Text('Period start: ${periodStart.toLocal().toShortDateString()}'),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: periodEnd,
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setState(() {
                              periodEnd = picked;
                            });
                          }
                        },
                        child: Text('Period end: ${periodEnd.toLocal().toShortDateString()}'),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: paymentStatus,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: const [
                          DropdownMenuItem(value: 'pending', child: Text('Pending')),
                          DropdownMenuItem(value: 'completed', child: Text('Completed')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              paymentStatus = value;
                            });
                          }
                        },
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
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) {
                      return;
                    }

                    final selectedSite = sitesAsync.valueOrNull
                        ?.firstWhere((site) => site.id == selectedSiteId);
                    final selectedLabour = labourAsync.valueOrNull
                        ?.firstWhere((labour) => labour.id == selectedLabourId);

                    if (selectedSite == null || selectedLabour == null) {
                      return;
                    }

                    final paymentSummary = await ref.read(calculatePaymentProvider(
                      (
                        selectedLabour.id,
                        selectedLabour.dailyWage,
                        periodStart,
                        periodEnd,
                      ),
                    ).future);

                    final grossPayment = paymentSummary.grossAmount;
                    final advancesTotal = paymentSummary.advancesTotal;
                    final netAmount = paymentSummary.netAmount;

                    final payment = await ref.read(createPaymentProvider(
                      (
                        selectedLabour.id,
                        selectedLabour.fullName,
                        selectedSite.id,
                        selectedSite.name,
                        periodStart,
                        periodEnd,
                        grossPayment,
                        advancesTotal,
                        netAmount,
                        paymentStatus,
                      ),
                    ).future);

                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Payment recorded for ${payment.labourName}')),
                      );
                    }
                  },
                  child: const Text('Save'),
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
