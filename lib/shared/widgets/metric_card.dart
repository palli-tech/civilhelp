import 'package:flutter/material.dart';
import 'app_design_system.dart';

/// A standardized summary metric card for use in list screens.
///
/// Used in summary bars above lists (advances outstanding, payroll totals, etc.)
/// NOT the same as [DashboardCard] which is for the 2x2 dashboard grid.
///
/// Usage:
/// ```dart
/// MetricCard(
///   label: 'Total Outstanding',
///   value: '₹12,500',
///   icon: Icons.account_balance_wallet,
///   color: AppDesignSystem.warningColor,
/// )
/// ```
class MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? color.withValues(alpha: 0.08);

    return Expanded(
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(AppDesignSystem.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDesignSystem.spacingSm,
              vertical: AppDesignSystem.spacingMd,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(height: AppDesignSystem.spacingXs),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    height: 1.2,
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
