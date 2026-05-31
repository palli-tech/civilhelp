import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:civilhelp/shared/layouts/app_scaffold.dart';
import 'package:civilhelp/features/labour/presentation/providers/labour_provider.dart';
import 'package:civilhelp/features/sites/providers/site_provider.dart';
import '../providers/advance_provider.dart';
import '../../labour/data/models/labour_model.dart';
import '../../sites/models/site_model.dart';

class AdvancesScreen extends ConsumerWidget {
  const AdvancesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final advancesAsync = ref.watch(advancesStreamProvider);
    final sitesAsync = ref.watch(sitesStreamProvider);
    final labourAsync = ref.watch(labourStreamProvider);

    final FloatingActionButton? fab = advancesAsync.when(
      data: (advances) => advances.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: () {
                _showNewAdvanceDialog(context, ref, sitesAsync, labourAsync);
              },
              tooltip: 'Add Advance',
              child: const Icon(Icons.add),
            ),
      loading: () => null,
      error: (_, __) => null,
    );

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Advances'),
        elevation: 0,
      ),
      fab: fab,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: advancesAsync.when(
                data: (advances) {
                  if (advances.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No advances recorded yet',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add advances to track loaned amounts and repayments',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              _showNewAdvanceDialog(context, ref, sitesAsync, labourAsync);
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Add Advance'),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: advances.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final advance = advances[index];
                      return ListTile(
                        title: Text(advance.labourName),
                        subtitle: Text(
                          '${advance.siteName} • ₹${advance.amount.toStringAsFixed(0)} • ${advance.reason}',
                        ),
                        trailing: Icon(
                          advance.paidBack ? Icons.check_circle : Icons.money_off,
                          color: advance.paidBack ? Colors.green : Colors.orange,
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Failed to load advances: $error')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNewAdvanceDialog(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<SiteModel>> sitesAsync,
    AsyncValue<List<LabourModel>> labourAsync,
  ) {
    final formKey = GlobalKey<FormState>();
    DateTime selectedDate = DateTime.now();
    String? selectedSiteId;
    String? selectedLabourId;
    String amountValue = '0';
    String reason = '';

    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Advance'),
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
                          error: (error, stackTrace) => const [],
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
                      TextFormField(
                        initialValue: amountValue,
                        decoration: const InputDecoration(labelText: 'Amount'),
                        keyboardType: TextInputType.number,
                        onChanged: (value) => amountValue = value,
                        validator: (value) {
                          final amount = double.tryParse(value ?? '');
                          if (amount == null || amount <= 0) {
                            return 'Enter a valid amount';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Reason'),
                        onChanged: (value) => reason = value,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter a reason';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setState(() {
                              selectedDate = picked;
                            });
                          }
                        },
                        child: Text('Date: ${selectedDate.toLocal().toShortDateString()}'),
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

                    final advance = await ref.read(createAdvanceProvider(
                      (
                        selectedLabour.id,
                        selectedLabour.fullName,
                        selectedSite.id,
                        selectedSite.name,
                        double.tryParse(amountValue) ?? 0.0,
                        reason,
                        selectedDate,
                      ),
                    ).future);

                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Advance created for ${advance.labourName}')),
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
