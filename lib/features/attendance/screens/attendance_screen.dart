import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:civilhelp/core/auth/permissions.dart';
import 'package:civilhelp/core/enums/user_role.dart';
import 'package:civilhelp/core/providers/user_role_provider.dart';
import 'package:civilhelp/shared/layouts/app_scaffold.dart';
import 'package:civilhelp/shared/widgets/civil_empty_state.dart';
import 'package:civilhelp/features/labour/presentation/providers/labour_provider.dart';
import 'package:civilhelp/features/sites/providers/site_provider.dart';
import '../models/attendance_model.dart';
import '../providers/attendance_provider.dart';
import '../widgets/attendance_card.dart';
import '../widgets/attendance_form.dart';
import '../widgets/bulk_attendance_form.dart';
import '../../labour/data/models/labour_model.dart';
import '../../sites/models/site_model.dart';

class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(userRoleProvider);
    final canDelete = role.hasPermission(Permission.deleteAttendance);
    final attendanceAsync = ref.watch(roleAwareAttendanceStreamProvider);

    // For supervisors, filter sites/labour to assigned sites only
    final assignedSiteIds = ref.watch(assignedSiteIdsProvider);
    final allSitesAsync = ref.watch(sitesStreamProvider);
    final allLabourAsync = ref.watch(labourStreamProvider);

    final sitesAsync = role == UserRole.supervisor
        ? allSitesAsync.whenData((sites) =>
            sites.where((s) => assignedSiteIds.contains(s.id)).toList())
        : allSitesAsync;
    final labourAsync = role == UserRole.supervisor
        ? allLabourAsync.whenData((labour) =>
            labour.where((l) => assignedSiteIds.contains(l.assignedSiteId)).toList())
        : allLabourAsync;

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
      error: (_, _) => null,
    );

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add),
            tooltip: 'Bulk Attendance',
            onPressed: () => _showBulkAttendanceDialog(context, ref, sitesAsync, labourAsync),
          ),
        ],
      ),
      fab: fab,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: attendanceAsync.when(
                data: (attendance) {
                  if (attendance.isEmpty) {
                    return CivilEmptyState(
                      icon: Icons.calendar_today_outlined,
                      title: 'No Attendance Records',
                      description: 'Mark attendance to track labour presence, hours, and earnings.',
                      ctaLabel: 'Mark Attendance',
                      onCta: () => _showNewAttendanceDialog(
                        context, ref, sitesAsync, labourAsync),
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
                          _showEditAttendanceDialog(context, ref, entry,
                              sitesAsync, labourAsync);
                        },
                        onDelete: canDelete
                            ? () {
                                _showDeleteAttendanceDialog(context, ref, entry);
                              }
                            : null,
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
    AsyncValue<List<SiteModel>> sitesAsync,
    AsyncValue<List<LabourModel>> labourAsync,
  ) {
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;
    String? inlineError;

    sitesAsync.whenData((sites) {
      labourAsync.whenData((labour) {
        showDialog<void>(
          context: context,
          builder: (context) {
            return StatefulBuilder(
              builder: (context, setState) => AlertDialog(
                title: const Text('Edit Attendance'),
                content: AttendanceForm(
                  formKey: formKey,
                  sites: sites,
                  labour: labour,
                  initialAttendance: attendance,
                  isLoading: isLoading,
                  inlineError: inlineError,
                  onChanged: () {
                    if (inlineError != null) setState(() => inlineError = null);
                  },
                  submitLabel: 'Update',
                  onSubmit: (siteId, siteName, labourId, labourName, date,
                      status, hoursWorked, musterQuantity) async {
                    setState(() => isLoading = true);
                    try {
                      // Preserve original labour and site; only update date/status/hours/muster
                      final updated = attendance.copyWith(
                        date: date,
                        status: status,
                        hoursWorked: hoursWorked,
                        musterQuantity: musterQuantity,
                      );

                      await ref.read(updateAttendanceProvider(updated).future);

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Attendance updated')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        // Map duplicate/business errors to inline validation
                        final msg = e.toString();
                        if (msg.contains('Attendance already exists')) {
                          final dateStr = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
                          inlineError = 'Attendance already exists for $labourName on $dateStr';
                        } else {
                          inlineError = 'Error: $e';
                        }
                        setState(() => isLoading = false);
                      }
                    }
                  },
                ),
                actions: [
                  TextButton(
                    onPressed: isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            );
          },
        );
      });
    });
  }

  void _showDeleteAttendanceDialog(
    BuildContext context,
    WidgetRef ref,
    AttendanceModel attendance,
  ) {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Attendance'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Are you sure you want to delete attendance for ${attendance.labourName}?',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason for deletion',
                  hintText: 'e.g., Wrong hours entered, duplicate entry',
                  isDense: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a reason for deletion';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              await ref.read(
                deleteAttendanceProvider((
                  attendanceId: attendance.id,
                  deleteReason: reasonController.text.trim(),
                )).future,
              );

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
    bool isLoading = false;
    String? inlineError;

    sitesAsync.whenData((sites) {
      labourAsync.whenData((labour) {
        showDialog<void>(
          context: context,
          builder: (context) {
            return StatefulBuilder(
              builder: (context, setState) => AlertDialog(
                title: const Text('Mark Attendance'),
                content: AttendanceForm(
                  formKey: formKey,
                  sites: sites,
                  labour: labour,
                  isLoading: isLoading,
                  inlineError: inlineError,
                  onChanged: () {
                    if (inlineError != null) setState(() => inlineError = null);
                  },
                  onSubmit: (siteId, siteName, labourId, labourName, date,
                      status, hoursWorked, musterQuantity) async {
                    setState(() => isLoading = true);
                    try {
                      final attendance = await ref.read(
                        createAttendanceProvider((
                          labourId,
                          labourName,
                          siteId,
                          siteName,
                          date,
                          status,
                          hoursWorked,
                          musterQuantity,
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
                    } catch (e) {
                      if (context.mounted) {
                        final msg = e.toString();
                        if (msg.contains('Attendance already exists')) {
                          final dateStr = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
                          inlineError = 'Attendance already exists for $labourName on $dateStr';
                        } else {
                          inlineError = 'Error: $e';
                        }
                        setState(() => isLoading = false);
                      }
                    }
                  },
                ),
                actions: [
                  TextButton(
                    onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            );
          },
        );
      });
    });
  }

  void _showBulkAttendanceDialog(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<SiteModel>> sitesAsync,
    AsyncValue<List<LabourModel>> labourAsync,
  ) {
    sitesAsync.whenData((sites) {
      labourAsync.whenData((labour) {
        showDialog<void>(
          context: context,
          builder: (context) {
            bool isLoading = false;
            String? error;

            return StatefulBuilder(
              builder: (context, setState) {
                return Dialog.fullscreen(
                  child: Scaffold(
                    appBar: AppBar(
                      title: const Text('Bulk Attendance'),
                      leading: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    body: BulkAttendanceForm(
                      sites: sites,
                      labour: labour,
                      isLoading: isLoading,
                      error: error,
                      onCancel: () => Navigator.pop(context),
                      onSubmit: (siteId, siteName, date, records) async {
                        setState(() => isLoading = true);
                        try {
                          final result = await ref.read(createBulkAttendanceProvider((
                            siteId: siteId,
                            siteName: siteName,
                            date: date,
                            labourRecords: records,
                          )).future);

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Attendance Saved - Created: ${result.$1}, Skipped: ${result.$2}'),
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            setState(() {
                              isLoading = false;
                              error = e.toString();
                            });
                          }
                        }
                      },
                    ),
                  ),
                );
              },
            );
          },
        );
      });
    });
  }
}

