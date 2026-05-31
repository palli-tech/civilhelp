import 'package:civilhelp/core/enums/site_status.dart';
import 'package:civilhelp/shared/layouts/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/site_provider.dart';
import 'package:civilhelp/features/attendance/providers/attendance_provider.dart';

class SiteDetailsScreen extends ConsumerWidget {
  final String siteId;

  const SiteDetailsScreen({
    super.key,
    required this.siteId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final siteAsync = ref.watch(siteByIdProvider(siteId));
    final dateFormat = DateFormat('MMM dd, yyyy');

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Site Details'),
        elevation: 0,
      ),
      child: siteAsync.when(
        data: (site) {
          if (site == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64),
                  const SizedBox(height: 16),
                  const Text('Site not found'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Site Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              site.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                          Chip(
                            label: Text(site.status.name),
                            backgroundColor:
                                _getStatusColor(site.status).withValues(alpha: 0.2),
                            labelStyle: TextStyle(
                              color: _getStatusColor(site.status),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              size: 18, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            site.location,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.person,
                              size: 18, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            site.client,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Site Information
                Text(
                  'Information',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _InfoRow(
                        label: 'Start Date',
                        value: dateFormat.format(site.startDate),
                        icon: Icons.calendar_today,
                      ),
                      const Divider(height: 24),
                      _InfoRow(
                        label: 'Created At',
                        value: dateFormat.format(site.createdAt),
                        icon: Icons.info,
                      ),
                      const Divider(height: 24),
                      _InfoRow(
                        label: 'Created By',
                        value: site.createdBy,
                        icon: Icons.person_outline,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Labour Section
                Text(
                  'Labour',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.people, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text(
                          'Labour management coming soon',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Attendance Section
                Text(
                  'Attendance',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Builder(
                  builder: (context) {
                    final attendanceAsync = ref.watch(attendanceBySiteStreamProvider(siteId));
                    return attendanceAsync.when(
                      data: (attendance) {
                        final presentCount = attendance
                            .where((entry) => entry.status.toLowerCase() == 'present')
                            .length;
                        final absentCount = attendance
                            .where((entry) => entry.status.toLowerCase() == 'absent')
                            .length;
                        final halfDayCount = attendance
                            .where((entry) => entry.status.toLowerCase() == 'half day')
                            .length;

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Recent attendance records',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _MiniStat(label: 'Present', value: presentCount.toString()),
                                  _MiniStat(label: 'Absent', value: absentCount.toString()),
                                  _MiniStat(label: 'Half Day', value: halfDayCount.toString()),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Total records: ${attendance.length}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        );
                      },
                      loading: () => Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      error: (error, _) => Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('Unable to load attendance: $error'),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Expenses Section
                Text(
                  'Expenses',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.money_off,
                            size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text(
                          'Expense tracking coming soon',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Edit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        '/edit-site',
                        arguments: siteId,
                      );
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Site'),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          );
        },
        loading: () {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
        error: (error, stackTrace) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error loading site: ${error.toString()}'),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

Color _getStatusColor(SiteStatus status) {
  switch (status) {
    case SiteStatus.active:
      return Colors.green;

    case SiteStatus.inactive:
      return Colors.grey;
      
    case SiteStatus.completed:
      return Colors.blue;

    case SiteStatus.onHold:
      return Colors.orange;
  }
}
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
