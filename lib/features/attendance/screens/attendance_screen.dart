import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:civilhelp/features/labour/presentation/providers/labour_provider.dart';
import 'package:civilhelp/features/sites/providers/site_provider.dart';
import '../providers/attendance_provider.dart';
import '../../labour/data/models/labour_model.dart';
import '../../sites/models/site_model.dart';

class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceAsync = ref.watch(attendanceStreamProvider);
    final sitesAsync = ref.watch(sitesStreamProvider);
    final labourAsync = ref.watch(labourStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
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
                  'Attendance overview',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _showNewAttendanceDialog(context, ref, sitesAsync, labourAsync);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Mark Attendance'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: attendanceAsync.when(
                data: (attendance) {
                  if (attendance.isEmpty) {
                    return const Center(
                      child: Text('No attendance records yet.'),
                    );
                  }

                  return ListView.separated(
                    itemCount: attendance.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final entry = attendance[index];
                      return ListTile(
                        title: Text(entry.labourName),
                        subtitle: Text('${entry.siteName} • ${entry.status} • ${entry.date.toLocal().toShortDateString()}'),
                        trailing: Text('${entry.hoursWorked.toStringAsFixed(1)}h'),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Failed to load attendance: $error')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNewAttendanceDialog(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<SiteModel>> sitesAsync,
    AsyncValue<List<LabourModel>> labourAsync,
  ) {
    final formKey = GlobalKey<FormState>();
    DateTime selectedDate = DateTime.now();
    String selectedStatus = 'Present';
    String? selectedSiteId;
    String? selectedLabourId;
    double hoursWorked = 8.0;

    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Mark Attendance'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (sitesAsync.hasError)
                        const Text('Unable to load sites.'),
                      if (labourAsync.hasError)
                        const Text('Unable to load labour.'),
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
                        },
                        validator: (value) => value == null ? 'Select a site' : null,
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
                        },
                        validator: (value) => value == null ? 'Select a labour' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedStatus,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: const [
                          DropdownMenuItem(value: 'Present', child: Text('Present')),
                          DropdownMenuItem(value: 'Absent', child: Text('Absent')),
                          DropdownMenuItem(value: 'Half Day', child: Text('Half Day')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedStatus = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: hoursWorked.toStringAsFixed(1),
                        decoration: const InputDecoration(labelText: 'Hours Worked'),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          hoursWorked = double.tryParse(value) ?? 8.0;
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

                    final attendance = await ref.read(createAttendanceProvider(
                      (
                        selectedLabour.id,
                        selectedLabour.fullName,
                        selectedSite.id,
                        selectedSite.name,
                        selectedDate,
                        selectedStatus,
                        hoursWorked,
                      ),
                    ).future);

                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Attendance saved for ${attendance.labourName}')),
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
