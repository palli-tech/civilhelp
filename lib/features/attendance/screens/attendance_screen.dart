import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:civilhelp/app/theme.dart';
import 'package:civilhelp/core/auth/permissions.dart';
import 'package:civilhelp/core/enums/user_role.dart';
import 'package:civilhelp/core/providers/user_role_provider.dart';
import 'package:civilhelp/shared/layouts/app_scaffold.dart';
import 'package:civilhelp/shared/widgets/module_header.dart';
import 'package:civilhelp/shared/widgets/module_empty_state.dart';
import 'package:civilhelp/shared/widgets/operational_metrics_strip.dart';
import 'package:civilhelp/shared/widgets/premium_module_card.dart';
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
              backgroundColor: context.customColors.attendance,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            ),
      loading: () => null,
      error: (_, _) => null,
    );

    return AppScaffold(
      fab: fab,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ModuleHeader(
            title: 'Attendance',
            subtitle: 'Track worker daily presence & hours',
            showBackButton: false,
            actions: [
              IconButton(
                icon: Icon(Icons.group_add_outlined, color: context.colors.primary),
                tooltip: 'Bulk Attendance',
                onPressed: () => _showBulkAttendanceDialog(context, ref, sitesAsync, labourAsync),
              ),
            ],
          ),
          Expanded(
            child: attendanceAsync.when(
              data: (attendance) {
                if (attendance.isEmpty) {
                  return ModuleEmptyState(
                    icon: Icons.calendar_today_outlined,
                    title: 'No Attendance Records',
                    description: 'Mark attendance to track labour presence, hours, and earnings.',
                    ctaLabel: 'Mark Attendance',
                    onCta: () => _showNewAttendanceDialog(context, ref, sitesAsync, labourAsync),
                    iconColor: context.customColors.attendance,
                  );
                }

                // Determine active date context for KPIs (default to today or fall back to latest date in logs)
                DateTime targetDate = DateTime.now();
                List<AttendanceModel> dayLogs = attendance.where((a) =>
                    a.date.year == targetDate.year &&
                    a.date.month == targetDate.month &&
                    a.date.day == targetDate.day
                ).toList();

                if (dayLogs.isEmpty && attendance.isNotEmpty) {
                  final latestDate = attendance.map((a) => a.date).reduce((a, b) => a.isAfter(b) ? a : b);
                  targetDate = latestDate;
                  dayLogs = attendance.where((a) =>
                      a.date.year == targetDate.year &&
                      a.date.month == targetDate.month &&
                      a.date.day == targetDate.day
                  ).toList();
                }

                // Metrics calculations for the day
                final present = dayLogs.where((a) => a.status.toLowerCase() == 'present').length;
                final absent = dayLogs.where((a) => a.status.toLowerCase() == 'absent').length;
                final halfDay = dayLogs.where((a) => 
                    a.status.toLowerCase() == 'half day' || 
                    a.status.toLowerCase() == 'half-day'
                ).length;
                final attendancePct = dayLogs.isNotEmpty
                    ? ((present + halfDay * 0.5) / dayLogs.length * 100)
                    : 0.0;

                final textScale = MediaQuery.maybeTextScalerOf(context)?.scale(1.0) ?? 1.0;
                final screenWidth = MediaQuery.of(context).size.width;
                final isMobile = screenWidth < 700;

                return Column(
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
                            label: 'Present Today',
                            value: '$present',
                            icon: Icons.check_circle_outline,
                            color: context.customColors.success,
                          ),
                          OperationalMetricData(
                            label: 'Absent Today',
                            value: '$absent',
                            icon: Icons.cancel_outlined,
                            color: context.colors.error,
                          ),
                          OperationalMetricData(
                            label: 'Half Day Today',
                            value: '$halfDay',
                            icon: Icons.star_half_rounded,
                            color: context.customColors.warning,
                          ),
                          OperationalMetricData(
                            label: 'Attendance %',
                            value: '${attendancePct.toStringAsFixed(0)}%',
                            icon: Icons.percent_outlined,
                            color: context.customColors.attendance,
                          ),
                        ],
                      ),
                    ),

                    // Quick Actions
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
                            onPressed: () => _showNewAttendanceDialog(context, ref, sitesAsync, labourAsync),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Mark Attendance', style: TextStyle(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.customColors.attendance,
                              foregroundColor: Colors.white,
                              elevation: 0,
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _showBulkAttendanceDialog(context, ref, sitesAsync, labourAsync),
                            icon: const Icon(Icons.group_add_outlined, size: 18),
                            label: const Text('Bulk Attendance'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: context.customColors.attendance,
                              side: BorderSide(color: context.customColors.attendance),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Insights Panel
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 12.0,
                      ),
                      child: _buildInsightsPanel(context, dayLogs, targetDate),
                    ),

                    const SizedBox(height: 12),

                    // Primary Content Grid
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(roleAwareAttendanceStreamProvider);
                        },
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final double availableWidth = constraints.maxWidth;
                              final isMobileLayout = availableWidth < 700;

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24.0,
                                  vertical: 16.0,
                                ),
                                child: Wrap(
                                  spacing: 20,
                                  runSpacing: 20,
                                  children: attendance.map((entry) {
                                    final double cardWidth = isMobileLayout
                                        ? (availableWidth - 48.0)
                                        : (availableWidth - 48.0 - 20.0) / 2.0;

                                    return SizedBox(
                                      width: cardWidth.clamp(0.0, double.infinity),
                                      child: AttendanceCard(
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
                                      ),
                                    );
                                  }).toList(),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => ModuleEmptyState(
                icon: Icons.error_outline,
                title: 'Failed to Load Attendance',
                description: error.toString(),
                iconColor: context.colors.error,
                ctaLabel: 'Retry',
                onCta: () => ref.invalidate(roleAwareAttendanceStreamProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsPanel(BuildContext context, List<AttendanceModel> dayLogs, DateTime date) {

    // Top performing site today
    final Map<String, int> siteCounts = {};
    for (final a in dayLogs) {
      if (a.status.toLowerCase() == 'present' || 
          a.status.toLowerCase() == 'half day' || 
          a.status.toLowerCase() == 'half-day') {
        siteCounts[a.siteName] = (siteCounts[a.siteName] ?? 0) + 1;
      }
    }
    String topSite = 'None';
    int maxCount = -1;
    siteCounts.forEach((site, count) {
      if (count > maxCount) {
        maxCount = count;
        topSite = site;
      }
    });

    final absentWorkers = dayLogs.where((a) => a.status.toLowerCase() == 'absent').map((a) => a.labourName).toList();
    final absentNames = absentWorkers.isNotEmpty ? absentWorkers.join(', ') : 'None';
    final formattedDate = DateFormat('dd MMM yyyy').format(date);

    return PremiumModuleCard(
      glowColor: context.customColors.attendance,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Attendance Insights ($formattedDate)',
                  style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.analytics_outlined, size: 18, color: context.customColors.attendance),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Top Performing Site', style: TextStyle(fontSize: 11, color: context.colors.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Text(
                      topSite,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Absent Workers Count', style: TextStyle(fontSize: 11, color: context.colors.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Text(
                      '${absentWorkers.length}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(height: 1),
          ),
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 14, color: context.colors.error),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Absent Workers: $absentNames',
                  style: TextStyle(fontSize: 11, color: context.colors.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
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
