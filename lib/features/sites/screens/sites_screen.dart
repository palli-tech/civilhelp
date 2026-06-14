import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:civilhelp/app/theme.dart';
import 'package:civilhelp/core/enums/site_status.dart';
import '../../../shared/layouts/app_scaffold.dart';
import '../../../shared/widgets/module_header.dart';
import '../../../shared/widgets/module_empty_state.dart';
import '../../../shared/widgets/operational_metrics_strip.dart';
import '../../labour/presentation/providers/labour_provider.dart';
import '../../attendance/providers/attendance_provider.dart';
import '../providers/site_provider.dart';
import '../widgets/site_card.dart';

class SitesScreen extends ConsumerWidget {
  const SitesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sitesAsync = ref.watch(sitesStreamProvider);
    final labourAsync = ref.watch(labourStreamProvider);
    final attendanceTodayAsync = ref.watch(attendanceTodayStreamProvider);
    final attendanceAllAsync = ref.watch(roleAwareAttendanceStreamProvider);

    final FloatingActionButton? fab = sitesAsync.when(
      data: (sites) => sites.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/add-site');
              },
              tooltip: 'Add Site',
              backgroundColor: context.customColors.site,
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
            title: 'Sites',
            subtitle: 'Manage active work locations and teams',
            showBackButton: false,
          ),
          Expanded(
            child: sitesAsync.when(
              data: (sites) {
                if (sites.isEmpty) {
                  return ModuleEmptyState(
                    icon: Icons.business_outlined,
                    title: 'No Sites Yet',
                    description: 'Create your first site to begin workforce tracking.',
                    ctaLabel: 'Add Site',
                    onCta: () => Navigator.of(context).pushNamed('/add-site'),
                    iconColor: context.customColors.site,
                  );
                }

                // Gather lists for calculations
                final labours = labourAsync.value ?? [];
                final todayAttendance = attendanceTodayAsync.value ?? [];
                final allAttendance = attendanceAllAsync.value ?? [];

                // Metrics calculations
                final totalSites = sites.length;
                final activeSites = sites.where((s) => s.status == SiteStatus.active).length;
                final workersAssigned = labours.where((l) => l.assignedSiteId.isNotEmpty).length;
                final todayWorkforce = todayAttendance.where((a) => 
                    a.status.toLowerCase() == 'present' || 
                    a.status.toLowerCase() == 'half day' || 
                    a.status.toLowerCase() == 'half-day'
                ).length;

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
                            label: 'Total Sites',
                            value: '$totalSites',
                            icon: Icons.business_outlined,
                            color: context.customColors.site,
                          ),
                          OperationalMetricData(
                            label: 'Active Projects',
                            value: '$activeSites',
                            icon: Icons.check_circle_outline,
                            color: context.customColors.success,
                          ),
                          OperationalMetricData(
                            label: 'Workers Assigned',
                            value: '$workersAssigned',
                            icon: Icons.people_outline,
                            color: context.customColors.worker,
                          ),
                          OperationalMetricData(
                            label: 'Today\'s Workforce',
                            value: '$todayWorkforce',
                            icon: Icons.today_outlined,
                            color: context.customColors.advance,
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
                            onPressed: () => Navigator.of(context).pushNamed('/add-site'),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Site', style: TextStyle(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.customColors.site,
                              foregroundColor: Colors.white,
                              elevation: 0,
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).pushNamed('/add-labour'),
                            icon: const Icon(Icons.person_add_outlined, size: 18),
                            label: const Text('Assign Workers'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: context.customColors.site,
                              side: BorderSide(color: context.customColors.site),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Sites responsive grid layout
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(sitesStreamProvider);
                          ref.invalidate(labourStreamProvider);
                          ref.invalidate(attendanceTodayStreamProvider);
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
                                  children: sites.map((site) {
                                    final double cardWidth = isMobileLayout
                                        ? (availableWidth - 48.0)
                                        : (availableWidth - 48.0 - 20.0) / 2.0;

                                    // Site specific metrics
                                    final siteWorkers = labours.where((l) => l.assignedSiteId == site.id).length;
                                    final siteTodayWorkforce = todayAttendance.where((a) => 
                                        a.siteId == site.id &&
                                        (a.status.toLowerCase() == 'present' || 
                                         a.status.toLowerCase() == 'half day' || 
                                         a.status.toLowerCase() == 'half-day')
                                    ).length;

                                    final siteAttendanceLogs = allAttendance.where((a) => a.siteId == site.id).toList();
                                    String lastAttendanceDate = 'No records';
                                    if (siteAttendanceLogs.isNotEmpty) {
                                      final lastDate = siteAttendanceLogs
                                          .map((a) => a.date)
                                          .reduce((a, b) => a.isAfter(b) ? a : b);
                                      lastAttendanceDate = DateFormat('dd MMM yyyy').format(lastDate);
                                    }

                                    return SizedBox(
                                      width: cardWidth.clamp(0.0, double.infinity),
                                      child: SiteCard(
                                        site: site,
                                        workersCount: siteWorkers,
                                        todayWorkforce: siteTodayWorkforce,
                                        lastAttendance: lastAttendanceDate,
                                        onTap: () {
                                          Navigator.of(context).pushNamed(
                                            '/site-details',
                                            arguments: site.id,
                                          );
                                        },
                                        onDelete: () {
                                          _showDeleteDialog(context, ref, site.id);
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
                  title: 'Error Loading Sites',
                  description: error.toString(),
                  iconColor: context.colors.error,
                  ctaLabel: 'Retry',
                  onCta: () => ref.invalidate(sitesStreamProvider),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, String siteId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Site'),
        content: const Text('Are you sure you want to delete this site?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(deleteSiteProvider(siteId).future);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Site deleted successfully')),
                );
              }
            },
            child: Text('Delete', style: TextStyle(color: context.colors.error)),
          ),
        ],
      ),
    );
  }
}
