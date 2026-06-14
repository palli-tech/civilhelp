import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:civilhelp/app/theme.dart';
import '../providers/dashboard_metrics_provider.dart';

class HeroKpiCard extends StatefulWidget {
  final String label;
  final AsyncValue<num> valueAsync;
  final IconData icon;
  final Color accentColor;
  final bool isCurrency;
  final double? width;

  const HeroKpiCard({
    super.key,
    required this.label,
    required this.valueAsync,
    required this.icon,
    required this.accentColor,
    this.isCurrency = false,
    this.width,
  });

  @override
  State<HeroKpiCard> createState() => _HeroKpiCardState();
}

class _HeroKpiCardState extends State<HeroKpiCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    final cardContent = widget.valueAsync.when(
      data: (number) {
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: number.toDouble()),
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeOutCubic,
          builder: (context, animVal, child) {
            final formattedValue = widget.isCurrency
                ? '₹${animVal.toStringAsFixed(0)}'
                : animVal.toStringAsFixed(0);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.label,
                      style: TextStyle(
                        fontFamily: 'NotoSans',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFB4B8D0) : Colors.black54,
                      ),
                    ),
                    Icon(
                      widget.icon,
                      color: widget.accentColor.withOpacity(0.8),
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  formattedValue,
                  style: TextStyle(
                    fontFamily: 'NotoSans',
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                // Subtle status accent dot
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.accentColor,
                        boxShadow: [
                          BoxShadow(
                            color: widget.accentColor,
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Live Metrics',
                      style: TextStyle(
                        fontFamily: 'NotoSans',
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFFB4B8D0).withOpacity(0.7) : Colors.black38,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
      loading: () => const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, __) => Center(
        child: Text(
          'N/A',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: widget.width,
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
            border: Border.all(
              color: isDark
                  ? (_isHovered ? widget.accentColor.withOpacity(0.4) : Colors.white.withOpacity(0.08))
                  : Colors.black.withOpacity(0.08),
              width: 1,
            ),
            boxShadow: [
              if (_isHovered)
                BoxShadow(
                  color: widget.accentColor.withOpacity(isDark ? 0.15 : 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                )
              else
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: cardContent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HeroKpiStrip extends ConsumerWidget {
  const HeroKpiStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalSites = ref.watch(totalSitesCountProvider);
    final activeLabour = ref.watch(activeLabourCountProvider);
    final todayAttendance = ref.watch(todayAttendanceCountProvider);
    final currentMonthPayroll = ref.watch(currentMonthPayrollProvider);

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1200;

    final cards = [
      HeroKpiCard(
        label: 'Active Workers',
        valueAsync: activeLabour.when(
          data: (val) => AsyncValue.data(val),
          loading: () => const AsyncValue.loading(),
          error: (err, stack) => AsyncValue.error(err, stack),
        ),
        icon: Icons.groups_rounded,
        accentColor: const Color(0xFF00D68F), // Green
      ),
      HeroKpiCard(
        label: 'Total Sites',
        valueAsync: totalSites.when(
          data: (val) => AsyncValue.data(val),
          loading: () => const AsyncValue.loading(),
          error: (err, stack) => AsyncValue.error(err, stack),
        ),
        icon: Icons.location_on_outlined,
        accentColor: const Color(0xFF7B4DFF), // Purple
      ),
      HeroKpiCard(
        label: "Today's Attendance",
        valueAsync: todayAttendance.when(
          data: (val) => AsyncValue.data(val),
          loading: () => const AsyncValue.loading(),
          error: (err, stack) => AsyncValue.error(err, stack),
        ),
        icon: Icons.check_circle_outline_rounded,
        accentColor: const Color(0xFF3D8BFF), // Blue
      ),
      HeroKpiCard(
        label: 'Monthly Payroll',
        valueAsync: currentMonthPayroll.when(
          data: (val) => AsyncValue.data(val),
          loading: () => const AsyncValue.loading(),
          error: (err, stack) => AsyncValue.error(err, stack),
        ),
        icon: Icons.receipt_long_outlined,
        accentColor: const Color(0xFFFFAA00), // Orange
        isCurrency: true,
      ),
    ];

    if (isDesktop) {
      return Row(
        children: cards
            .map((card) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: card,
                  ),
                ))
            .toList(),
      );
    }

    // Horizontal scrollable strip for mobile and tablet
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      child: Row(
        children: cards
            .map((card) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: SizedBox(
                    width: 180,
                    child: card,
                  ),
                ))
            .toList(),
      ),
    );
  }
}
