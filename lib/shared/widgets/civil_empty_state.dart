import 'package:flutter/material.dart';

/// Standardized empty state widget used across all CivilHelp list screens.
///
/// Follows the pattern: Icon → Title → Description → Optional CTA button.
/// Replaces all inline empty state implementations for consistency.
///
/// Usage:
/// ```dart
/// CivilEmptyState(
///   icon: Icons.monetization_on_outlined,
///   title: 'No Outstanding Advances',
///   description: 'All advances have been recovered.',
/// )
///
/// CivilEmptyState(
///   icon: Icons.receipt_long,
///   title: 'No Payroll Periods',
///   description: 'Create a new payroll period to get started.',
///   ctaLabel: 'Create Period',
///   onCta: () => ...,
/// )
/// ```
class CivilEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? ctaLabel;
  final VoidCallback? onCta;
  final Color? iconColor;

  const CivilEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.ctaLabel,
    this.onCta,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? Colors.grey[400]!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 72, color: color),
            const SizedBox(height: 20),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
              textAlign: TextAlign.center,
            ),
            if (ctaLabel != null && onCta != null) ...[
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: onCta,
                icon: const Icon(Icons.add),
                label: Text(ctaLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
