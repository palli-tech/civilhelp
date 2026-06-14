import 'package:flutter/material.dart';
import 'package:civilhelp/app/theme.dart';
import 'package:civilhelp/shared/widgets/status_chip.dart';

class LabourCard extends StatelessWidget {
  final dynamic labour;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const LabourCard({
    super.key,
    required this.labour,
    required this.onTap,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
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
                      labour.fullName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      if (onEdit != null)
                        PopupMenuItem(
                          onTap: onEdit,
                          child: const Text('Edit'),
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
                  Icon(Icons.phone, size: 16, color: context.colors.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      labour.phoneNumber,
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
                  Icon(Icons.location_on, size: 16, color: context.colors.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      labour.assignedSiteName,
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
                    '₹${labour.dailyWage.toStringAsFixed(2)}/day',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  StatusChip(status: labour.status.toString().split('.').last),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
