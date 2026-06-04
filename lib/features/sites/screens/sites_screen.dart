import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/layouts/app_scaffold.dart';
import '../providers/site_provider.dart';
import '../widgets/site_card.dart';

class SitesScreen extends ConsumerWidget {
  const SitesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sitesAsync = ref.watch(sitesStreamProvider);

    final FloatingActionButton? fab = sitesAsync.when(
      data: (sites) => sites.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/add-site');
              },
              tooltip: 'Add Site',
              child: const Icon(Icons.add),
            ),
      loading: () => null,
      error: (_, _) => null,
    );

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Sites'),
        elevation: 0,
      ),
      fab: fab,
      child: sitesAsync.when(
        data: (sites) {
          if (sites.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_on,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No sites yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first site to get started',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/add-site');
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Site'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(sitesStreamProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sites.length,
              itemBuilder: (context, index) {
                final site = sites[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SiteCard(
                    site: site,
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
                  'Error loading sites',
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
                    ref.invalidate(sitesStreamProvider);
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
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
