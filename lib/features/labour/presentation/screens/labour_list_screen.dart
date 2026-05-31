import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:civilhelp/shared/layouts/app_scaffold.dart';
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
      error: (_, __) => null,
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No labour records',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add labour records to get started',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/add-labour');
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Labour'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(labourStreamProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: labourList.length,
              itemBuilder: (context, index) {
                final labour = labourList[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading labour records',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(labourStreamProvider);
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
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
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

