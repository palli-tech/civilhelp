import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:civilhelp/app/theme.dart';
import 'package:civilhelp/shared/widgets/status_chip.dart';

class SiteCard extends StatelessWidget {
  final dynamic site;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const SiteCard({
    super.key,
    required this.site,
    required this.onTap,
    this.onDelete,
  });

  String _statusName() {
    return site.status.toString().split('.').last;
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            border: Border.all(color: context.colors.outlineVariant),
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
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: const Text('Edit'),
                        onTap: () => Navigator.of(context)
                            .pushNamed('/edit-site', arguments: site.id),
                      ),
                      if (onDelete != null)
                        PopupMenuItem(
                          onTap: onDelete,
                          child: const Text('Delete'),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.listGap),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: context.colors.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      site.location,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: context.colors.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      site.client,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.listGap),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateFormat.format(site.startDate),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                  ),
                  StatusChip(status: _statusName()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
