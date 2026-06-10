import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:civilhelp/features/sites/providers/site_provider.dart';
import 'package:civilhelp/features/labour/presentation/providers/labour_provider.dart';

class ReportFilterBar extends ConsumerWidget {
  final String? selectedSiteId;
  final String? selectedWorkerId;
  final DateTime startDate;
  final DateTime endDate;
  final bool showWorkerFilter;
  final ValueChanged<String?> onSiteChanged;
  final ValueChanged<String?> onWorkerChanged;
  final void Function(DateTime start, DateTime end) onDateRangeChanged;

  const ReportFilterBar({
    super.key,
    this.selectedSiteId,
    this.selectedWorkerId,
    required this.startDate,
    required this.endDate,
    this.showWorkerFilter = true,
    required this.onSiteChanged,
    required this.onWorkerChanged,
    required this.onDateRangeChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sitesAsync = ref.watch(sitesStreamProvider);
    final laboursAsync = ref.watch(labourStreamProvider);

    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Theme.of(context).cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: startDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      onDateRangeChanged(date, endDate);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Start Date',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(DateFormat('dd MMM yyyy').format(startDate)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: endDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      onDateRangeChanged(startDate, date);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'End Date',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(DateFormat('dd MMM yyyy').format(endDate)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          sitesAsync.when(
            data: (sites) {
              final validSiteId = selectedSiteId != null && sites.any((s) => s.id == selectedSiteId) 
                  ? selectedSiteId 
                  : null;

              return DropdownButtonFormField<String>(
                initialValue: validSiteId,
                decoration: const InputDecoration(
                  labelText: 'Site',
                  border: OutlineInputBorder(),
                ),
                isExpanded: true,
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('All Sites'),
                  ),
                  ...sites.map((site) => DropdownMenuItem<String>(
                    value: site.id,
                    child: Text(site.name),
                  )),
                ],
                onChanged: onSiteChanged,
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Text('Error loading sites: $err'),
          ),
          if (showWorkerFilter) ...[
            const SizedBox(height: 16),
            laboursAsync.when(
              data: (labours) {
                // If a site is selected, optionally filter workers by that site,
                // but for now we just show all workers or workers assigned to site.
                // It's safer to show all to not break historical data viewing.
                final validWorkerId = selectedWorkerId != null && labours.any((l) => l.id == selectedWorkerId) 
                    ? selectedWorkerId 
                    : null;

                return DropdownButtonFormField<String>(
                  initialValue: validWorkerId,
                  decoration: const InputDecoration(
                    labelText: 'Worker',
                    border: OutlineInputBorder(),
                  ),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('All Workers'),
                    ),
                    ...labours.map((labour) => DropdownMenuItem<String>(
                      value: labour.id,
                      child: Text('${labour.fullName} - ${labour.assignedSiteName}'),
                    )),
                  ],
                  onChanged: onWorkerChanged,
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text('Error loading workers: $err'),
            ),
          ],
        ],
      ),
    );
  }
}
