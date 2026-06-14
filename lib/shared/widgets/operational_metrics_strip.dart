import 'package:flutter/material.dart';
import 'package:civilhelp/app/theme.dart';
import 'premium_module_card.dart';

class OperationalMetricData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const OperationalMetricData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });
}

class OperationalMetricsStrip extends StatelessWidget {
  final List<OperationalMetricData> metrics;

  const OperationalMetricsStrip({
    super.key,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth >= 1024) {
      // Desktop: 4 cards side-by-side
      return Row(
        children: metrics.map((m) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: _buildMetricCard(context, m),
          ),
        )).toList(),
      );
    } else if (screenWidth >= 600) {
      // Tablet: 2x2 grid
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: Padding(padding: const EdgeInsets.all(6.0), child: _buildMetricCard(context, metrics[0]))),
              Expanded(child: Padding(padding: const EdgeInsets.all(6.0), child: _buildMetricCard(context, metrics[1]))),
            ],
          ),
          Row(
            children: [
              Expanded(child: Padding(padding: const EdgeInsets.all(6.0), child: _buildMetricCard(context, metrics[2]))),
              Expanded(child: Padding(padding: const EdgeInsets.all(6.0), child: _buildMetricCard(context, metrics[3]))),
            ],
          ),
        ],
      );
    } else {
      // Mobile: Horizontal scroll
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: metrics.map((m) => SizedBox(
            width: 180,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0),
              child: _buildMetricCard(context, m),
            ),
          )).toList(),
        ),
      );
    }
  }

  Widget _buildMetricCard(BuildContext context, OperationalMetricData data) {
    final isDark = context.isDarkMode;

    // Use a custom PremiumModuleCard wrapper
    return PremiumModuleCard(
      onTap: data.onTap,
      borderRadius: 16.0,
      glowColor: data.color,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  data.icon,
                  color: data.color,
                  size: 18,
                ),
              ),
              if (isDark)
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: data.color.withValues(alpha: 0.4),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            builder: (context, anim, child) {
              return Opacity(
                opacity: anim,
                child: Transform.translate(
                  offset: Offset(0, 8 * (1.0 - anim)),
                  child: Text(
                    data.value,
                    style: TextStyle(
                      fontFamily: 'NotoSans',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : data.color,
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            data.label,
            style: TextStyle(
              fontFamily: 'NotoSans',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFFB4B8D0) : context.colors.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
