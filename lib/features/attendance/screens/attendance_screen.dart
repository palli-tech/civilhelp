import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:civilhelp/shared/layouts/app_scaffold.dart';
import 'package:civilhelp/features/labour/presentation/providers/labour_provider.dart';
import 'package:civilhelp/features/sites/providers/site_provider.dart';
import '../models/attendance_model.dart';
import '../providers/attendance_provider.dart';
import '../widgets/attendance_card.dart';
import '../../labour/data/models/labour_model.dart';
import '../../sites/models/site_model.dart';

class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceAsync = ref.watch(attendanceStreamProvider);
    final sitesAsync = ref.watch(sitesStreamProvider);
    final labourAsync = ref.watch(labourStreamProvider);

    final FloatingActionButton? fab = attendanceAsync.when(
      data: (attendance) => attendance.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: () {
                _showNewAttendanceDialog(context, ref, sitesAsync, labourAsync);
              },
              tooltip: 'Mark Attendance',
              child: const Icon(Icons.add),
            ),
      loading: () => null,
      error: (_, __) => null,
    );

    return AppScaffold(
      appBar: AppBar(title: const Text('Attendance'), elevation: 0),
      fab: fab,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: attendanceAsync.when(
                data: (attendance) {
                  if (attendance.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No attendance records yet',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Mark attendance to track labour presence and hours',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              _showNewAttendanceDialog(
                                context,
                                ref,
                                sitesAsync,
                                labourAsync,
                              );
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Mark Attendance'),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: attendance.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final entry = attendance[index];
                      return AttendanceCard(
                        attendance: entry,
                        onEdit: () {
                          _showEditAttendanceDialog(context, ref, entry);
                        },
                        onDelete: () {
                          _showDeleteAttendanceDialog(context, ref, entry);
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) =>
                    Center(child: Text('Failed to load attendance: $error')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditAttendanceDialog(
    BuildContext context,
    WidgetRef ref,
    AttendanceModel attendance,
  ) {
    String selectedStatus = attendance.status;
    double hoursWorked = attendance.hoursWorked;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Attendance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: selectedStatus,
              items: const [
                DropdownMenuItem(value: 'Present', child: Text('Present')),
                DropdownMenuItem(value: 'Absent', child: Text('Absent')),
                DropdownMenuItem(value: 'Half Day', child: Text('Half Day')),
              ],
              onChanged: (value) {
                if (value != null) {
                  selectedStatus = value;
                }
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: hoursWorked.toString(),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Hours Worked'),
              onChanged: (value) {
                hoursWorked = double.tryParse(value) ?? attendance.hoursWorked;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await ref.read(
                updateAttendanceProvider(
                  attendance.copyWith(
                    status: selectedStatus,
                    hoursWorked: hoursWorked,
                  ),
                ).future,
              );

              if (context.mounted) {
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Attendance updated')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAttendanceDialog(
    BuildContext context,
    WidgetRef ref,
    AttendanceModel attendance,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Attendance'),
        content: Text(
          'Are you sure you want to delete attendance for ${attendance.labourName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await ref.read(deleteAttendanceProvider(attendance.id).future);

              if (context.mounted) {
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Attendance deleted')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
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
                        },
                        validator: (value) =>
                            value == null ? 'Select a labour' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedStatus,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: const [
                          DropdownMenuItem(
                            value: 'Present',
                            child: Text('Present'),
                          ),
                          DropdownMenuItem(
                            value: 'Absent',
                            child: Text('Absent'),
                          ),
                          DropdownMenuItem(
                            value: 'Half Day',
                            child: Text('Half Day'),
                          ),
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
                        decoration: const InputDecoration(
                          labelText: 'Hours Worked',
                        ),
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
                            firstDate: DateTime.now().subtract(
                              const Duration(days: 365),
                            ),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (picked != null) {
                            setState(() {
                              selectedDate = picked;
                            });
                          }
                        },
                        child: Text(
                          'Date: ${selectedDate.toLocal().toShortDateString()}',
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
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) {
                      return;
                    }

                    final selectedSite = sitesAsync.valueOrNull?.firstWhere(
                      (site) => site.id == selectedSiteId,
                    );
                    final selectedLabour = labourAsync.valueOrNull?.firstWhere(
                      (labour) => labour.id == selectedLabourId,
                    );

                    if (selectedSite == null || selectedLabour == null) {
                      return;
                    }

                    final attendance = await ref.read(
                      createAttendanceProvider((
                        selectedLabour.id,
                        selectedLabour.fullName,
                        selectedSite.id,
                        selectedSite.name,
                        selectedDate,
                        selectedStatus,
                        hoursWorked,
                      )).future,
                    );

                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Attendance saved for ${attendance.labourName}',
                          ),
                        ),
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
