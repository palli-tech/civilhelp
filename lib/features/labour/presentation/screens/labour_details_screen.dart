import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:civilhelp/core/enums/labour_status.dart';
import 'package:civilhelp/shared/layouts/app_scaffold.dart';
import 'package:civilhelp/features/labour/presentation/providers/labour_provider.dart';
import 'package:civilhelp/features/labour/presentation/widgets/labour_status_chip.dart';

class LabourDetailsScreen extends ConsumerWidget {
  final String labourId;

  const LabourDetailsScreen({
    super.key,
    required this.labourId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labourAsync = ref.watch(labourByIdProvider(labourId));

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Labour Details'),
        elevation: 0,
      ),
      child: labourAsync.when(
        data: (labour) {
          if (labour == null) {
            return const Center(child: Text('Labour not found'));
          }

          final dateFormat = DateFormat('MMM dd, yyyy');
          final dateTimeFormat = DateFormat('MMM dd, yyyy - hh:mm a');

          return SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[400]!, Colors.blue[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        labour.fullName,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      LabourStatusChip(
                        status: labour.status,
                        fontSize: 14,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _DetailCard(
                        title: 'Contact Information',
                        children: [
                          _DetailRow(
                            icon: Icons.phone,
                            label: 'Phone Number',
                            value: labour.phoneNumber,
                          ),
                          const SizedBox(height: 12),
                          _DetailRow(
                            icon: Icons.credit_card,
                            label: 'Aadhaar Number',
                            value: labour.aadhaarNumber,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _DetailCard(
                        title: 'Work Information',
                        children: [
                          _DetailRow(
                            icon: Icons.location_on,
                            label: 'Assigned Site',
                            value: labour.assignedSiteName,
                          ),
                          const SizedBox(height: 12),
                          _DetailRow(
                            icon: Icons.currency_rupee,
                            label: 'Daily Wage',
                            value: '₹${labour.dailyWage.toStringAsFixed(2)}',
                          ),
                          const SizedBox(height: 12),
                          _DetailRow(
                            icon: Icons.calendar_today,
                            label: 'Joined Date',
                            value: dateFormat.format(labour.joinedDate),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _DetailCard(
                        title: 'Additional Information',
                        children: [
                          _DetailRow(
                            icon: Icons.person_outline,
                            label: 'Created By',
                            value: labour.createdBy,
                          ),
                          const SizedBox(height: 12),
                          _DetailRow(
                            icon: Icons.schedule,
                            label: 'Created At',
                            value: dateTimeFormat.format(labour.createdAt),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildActionButtons(context, ref, labour),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[400],
              ),
              const SizedBox(height: 16),
              Text('Error loading labour details'),
              const SizedBox(height: 8),
              Text(error.toString()),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(labourByIdProvider(labourId));
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    dynamic labour,
  ) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamed(
                '/edit-labour',
                arguments: labour.id,
              );
            },
            icon: const Icon(Icons.edit),
            label: const Text('Edit'),
          ),
        ),
        if (labour.status == LabourStatus.active)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                _showStatusChangeDialog(
                  context,
                  ref,
                  labour.id,
                  LabourStatus.onLeave,
                );
              },
              icon: const Icon(Icons.pause),
              label: const Text('Mark as On Leave'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
            ),
          ),
        if (labour.status != LabourStatus.inactive)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                _showStatusChangeDialog(
                  context,
                  ref,
                  labour.id,
                  LabourStatus.inactive,
                );
              },
              icon: const Icon(Icons.block),
              label: const Text('Mark as Inactive'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
              ),
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              _showDeleteDialog(context, ref, labour.id);
            },
            icon: const Icon(Icons.delete),
            label: const Text('Delete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
          ),
        ),
      ],
    );
  }

  void _showStatusChangeDialog(
    BuildContext context,
    WidgetRef ref,
    String labourId,
    LabourStatus newStatus,
  ) {
    final statusValue = newStatus.toString().split('.').last;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Status'),
        content: Text('Change status to $statusValue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(
                  updateLabourStatusProvider((labourId, statusValue)).future,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Status updated to $statusValue')),
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
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    String labourId,
  ) {
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
                  Navigator.of(context).pop();
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
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DetailCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
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
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue[400]),
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
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
