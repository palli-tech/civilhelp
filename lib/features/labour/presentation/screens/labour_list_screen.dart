import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:civilhelp/app/theme.dart';
import 'package:civilhelp/core/enums/labour_status.dart';
import 'package:civilhelp/shared/layouts/app_scaffold.dart';
import 'package:civilhelp/shared/widgets/module_header.dart';
import 'package:civilhelp/shared/widgets/module_empty_state.dart';
import 'package:civilhelp/shared/widgets/operational_metrics_strip.dart';
import 'package:civilhelp/features/attendance/providers/attendance_provider.dart';
import 'package:civilhelp/features/advances/providers/advances_providers.dart';
import '../widgets/labour_card.dart';
import '../providers/labour_provider.dart';

class LabourListScreen extends ConsumerWidget {
  const LabourListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labourAsync = ref.watch(labourStreamProvider);
    final attendanceTodayAsync = ref.watch(attendanceTodayStreamProvider);
    final advancesAsync = ref.watch(advancesListStreamProvider);

    final FloatingActionButton? fab = labourAsync.when(
      data: (labourList) => labourList.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/add-labour');
              },
              tooltip: 'Add Labour',
              backgroundColor: context.customColors.worker,
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
          const ModuleHeader(
            title: 'Labour',
            subtitle: 'Manage workers, attendance and payouts',
            showBackButton: false,
          ),
          Expanded(
            child: labourAsync.when(
              data: (labourList) {
                if (labourList.isEmpty) {
                  return ModuleEmptyState(
                    icon: Icons.people_outline,
                    title: 'No Workers Added',
                    description: 'Add workers to start attendance and payroll tracking.',
                    ctaLabel: 'Add Labour',
                    onCta: () => Navigator.of(context).pushNamed('/add-labour'),
                    iconColor: context.customColors.worker,
                  );
                }

                // Gather lists for calculations
                final todayAttendance = attendanceTodayAsync.value ?? [];
                final advances = advancesAsync.value ?? [];

                // Metrics calculations
                final activeWorkers = labourList.where((l) => l.status == LabourStatus.active).length;
                final presentToday = todayAttendance.where((a) =>
                    a.status.toLowerCase() == 'present' ||
                    a.status.toLowerCase() == 'half day' ||
                    a.status.toLowerCase() == 'half-day'
                ).length;
                final outstandingAdvances = advances.where((a) => a.status != 'recovered').fold<double>(
                  0.0, (sum, a) => sum + a.remainingAmount
                );
                final averageWage = labourList.isNotEmpty
                    ? (labourList.fold<double>(0.0, (sum, l) => sum + l.dailyWage) / labourList.length)
                    : 0.0;

                //final textScale = MediaQuery.maybeTextScalerOf(context)?.scale(1.0) ?? 1.0;
                //final screenWidth = MediaQuery.of(context).size.width;
                //final isMobile = screenWidth < 700;

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
                            label: 'Active Workers',
                            value: '$activeWorkers',
                            icon: Icons.people_outline,
                            color: context.customColors.worker,
                          ),
                          OperationalMetricData(
                            label: 'Present Today',
                            value: '$presentToday',
                            icon: Icons.check_circle_outline,
                            color: context.customColors.success,
                          ),
                          OperationalMetricData(
                            label: 'Outstanding Advances',
                            value: '₹${outstandingAdvances.toStringAsFixed(0)}',
                            icon: Icons.currency_rupee_outlined,
                            color: context.customColors.advance,
                          ),
                          OperationalMetricData(
                            label: 'Average Wage',
                            value: '₹${averageWage.toStringAsFixed(0)}/d',
                            icon: Icons.payments_outlined,
                            color: context.customColors.payroll,
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
                      child: Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => Navigator.of(context).pushNamed('/add-labour'),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Labour', style: TextStyle(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.customColors.worker,
                              foregroundColor: Colors.white,
                              elevation: 0,
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Import Labour feature coming soon.')),
                              );
                            },
                            icon: const Icon(Icons.upload_file_outlined, size: 18),
                            label: const Text('Import Labour'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: context.customColors.worker,
                              side: BorderSide(color: context.customColors.worker),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Labour responsive grid layout
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(labourStreamProvider);
                          ref.invalidate(attendanceTodayStreamProvider);
                          ref.invalidate(advancesListStreamProvider);
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
                                  children: labourList.map((labour) {
                                    final double cardWidth = isMobileLayout
                                        ? (availableWidth - 48.0)
                                        : (availableWidth - 48.0 - 20.0) / 2.0;

                                    // Worker specific attendance today
                                    final hasAttendance = todayAttendance.any((a) => a.labourId == labour.id);
                                    final workerAtt = hasAttendance
                                        ? todayAttendance.firstWhere((a) => a.labourId == labour.id)
                                        : null;
                                    final attendanceStr = workerAtt != null 
                                        ? (workerAtt.status.toString().split('.').last[0].toUpperCase() + workerAtt.status.toString().split('.').last.substring(1))
                                        : 'Not marked';

                                    // Worker outstanding advance balance
                                    final workerAdvances = advances.where(
                                      (a) => a.labourId == labour.id && a.status != 'recovered'
                                    ).fold<double>(0.0, (sum, a) => sum + a.remainingAmount);

                                    return SizedBox(
                                      width: cardWidth.clamp(0.0, double.infinity),
                                      child: LabourCard(
                                        labour: labour,
                                        attendanceToday: attendanceStr,
                                        advanceBalance: workerAdvances,
                                        onTap: () {
                                          Navigator.of(context).pushNamed(
                                            '/labour-details',
                                            arguments: labour.id,
                                          );
                                        },
                                        onEdit: () {
                                          Navigator.of(context).pushNamed(
                                            '/edit-labour',
                                            arguments: labour.id,
                                          );
                                        },
                                        onDelete: () {
                                          _showDeleteDialog(context, ref, labour.id);
                                        },
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
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stackTrace) {
                return ModuleEmptyState(
                  icon: Icons.error_outline,
                  title: 'Error Loading Labour',
                  description: error.toString(),
                  iconColor: context.colors.error,
                  ctaLabel: 'Retry',
                  onCta: () => ref.invalidate(labourStreamProvider),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, String labourId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Labour'),
        content: const Text('Are you sure you want to delete this labour record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(deleteLabourProvider(labourId).future);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Labour record deleted successfully'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: Text('Delete', style: TextStyle(color: context.colors.error)),
          ),
        ],
      ),
    );
  }
}
