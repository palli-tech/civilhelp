import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:civilhelp/app/theme.dart';
import '../../../shared/layouts/app_scaffold.dart';
import '../../../shared/widgets/civil_empty_state.dart';
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
            return CivilEmptyState(
              icon: Icons.location_on_outlined,
              title: 'No Sites Yet',
              description: 'Create your first site to start tracking attendance and labour.',
              ctaLabel: 'Add Site',
              onCta: () => Navigator.of(context).pushNamed('/add-site'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(sitesStreamProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              itemCount: sites.length,
              itemBuilder: (context, index) {
                final site = sites[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.listGap),
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
          return CivilEmptyState(
            icon: Icons.error_outline,
            title: 'Error Loading Sites',
            description: error.toString(),
            iconColor: context.colors.error,
            ctaLabel: 'Retry',
            onCta: () => ref.invalidate(sitesStreamProvider),
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
            child: Text('Delete', style: TextStyle(color: context.colors.error)),
          ),
        ],
      ),
    );
  }
}
