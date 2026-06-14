import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:civilhelp/app/theme.dart';
import 'package:civilhelp/shared/layouts/app_scaffold.dart';
import 'package:civilhelp/shared/widgets/civil_empty_state.dart';
import 'package:civilhelp/features/labour/presentation/widgets/labour_card.dart';
import 'package:civilhelp/features/labour/presentation/providers/labour_provider.dart';

class LabourListScreen extends ConsumerWidget {
  const LabourListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labourAsync = ref.watch(labourStreamProvider);

    final FloatingActionButton? fab = labourAsync.when(
      data: (labourList) => labourList.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/add-labour');
              },
              tooltip: 'Add Labour',
              child: const Icon(Icons.add),
            ),
      loading: () => null,
      error: (_, _) => null,
    );

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Labour'),
        elevation: 0,
      ),
      fab: fab,
      child: labourAsync.when(
        data: (labourList) {
          if (labourList.isEmpty) {
            return CivilEmptyState(
              icon: Icons.people_outline,
              title: 'No Labour Records Yet',
              description: 'Create your first labour record to start tracking attendance, advances, and payouts.',
              ctaLabel: 'Add Labour',
              onCta: () => Navigator.of(context).pushNamed('/add-labour'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(labourStreamProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              itemCount: labourList.length,
              itemBuilder: (context, index) {
                final labour = labourList[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.listGap),
                  child: LabourCard(
                    labour: labour,
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
              },
            ),
          );
        },
        loading: () {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
        error: (error, stackTrace) {
          return CivilEmptyState(
            icon: Icons.error_outline,
            title: 'Error Loading Labour Records',
            description: error.toString(),
            iconColor: context.colors.error,
            ctaLabel: 'Retry',
            onCta: () => ref.invalidate(labourStreamProvider),
          );
        },
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

