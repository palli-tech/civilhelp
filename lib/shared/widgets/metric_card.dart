import 'package:flutter/material.dart';
import 'package:civilhelp/app/theme.dart';
import 'app_design_system.dart';

/// A standardized summary metric card for use in list screens.
///
/// Used in summary bars above lists (advances outstanding, payroll totals, etc.)
/// NOT the same as [DashboardCard] which is for the 2x2 dashboard grid.
class MetricCard extends StatefulWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color? backgroundColor;
  final Gradient? gradient;
  final VoidCallback? onTap;

  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.backgroundColor,
    this.gradient,
    this.onTap,
  });

  @override
  State<MetricCard> createState() => _MetricCardState();
}

class _MetricCardState extends State<MetricCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    // Standard fallback backgrounds
    final bg = widget.backgroundColor ?? widget.color.withOpacity(0.08);
    final derivedGradient = widget.backgroundColor != null
        ? null
        : (widget.gradient ?? context.roleGradient(widget.color));

    // Modern SaaS styling in dark mode
    final glassBg = isDark ? Colors.white.withOpacity(0.04) : bg;
    final border = Border.all(
      color: isDark
          ? (_isHovered ? widget.color.withOpacity(0.4) : Colors.white.withOpacity(0.08))
          : Colors.black.withOpacity(0.06),
      width: 1,
    );

    final card = AnimatedScale(
      scale: _isHovered ? 1.02 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: isDark ? null : derivedGradient,
          color: isDark ? glassBg : (derivedGradient == null ? bg : null),
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusXl), // 24px
          border: border,
          boxShadow: [
            if (_isHovered)
              BoxShadow(
                color: widget.color.withOpacity(isDark ? 0.15 : 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            else
              BoxShadow(
                color: Colors.black.withOpacity(0.01),
                blurRadius: 2,
              ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusXl),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(AppDesignSystem.radiusXl),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDesignSystem.spacingMd,
                vertical: AppDesignSystem.spacingMd,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(widget.icon, color: widget.color, size: 20),
                      if (isDark && _isHovered)
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.color,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppDesignSystem.spacingSm),
                  Text(
                    widget.value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : widget.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? const Color(0xFFB4B8D0) : context.colors.onSurfaceVariant,
                      height: 1.2,
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return Expanded(
      child: widget.onTap != null
          ? MouseRegion(
              onEnter: (_) => setState(() => _isHovered = true),
              onExit: (_) => setState(() => _isHovered = false),
              child: card,
            )
          : card,
    );
  }
}
