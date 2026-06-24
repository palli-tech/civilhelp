import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:civilhelp/app/theme.dart';
import 'package:civilhelp/app/router.dart';
import 'package:civilhelp/features/expenses/providers/expense_provider.dart';
import '../../../shared/layouts/app_scaffold.dart';
import '../providers/dashboard_metrics_provider.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/quick_action_tile.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/hero_kpi_strip.dart';

class _DashboardCardConfig {
  final String title;
  final String value;
  final IconData icon;
  final LinearGradient gradient;
  final IconData overlayIcon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final Color glowColor;
  final VoidCallback onTap;

  const _DashboardCardConfig({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
    required this.overlayIcon,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.glowColor,
    required this.onTap,
  });
}

class OwnerDashboard extends ConsumerWidget {
  const OwnerDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalSites = ref.watch(totalSitesCountProvider);
    final activeLabour = ref.watch(activeLabourCountProvider);
    final todayAttendance = ref.watch(todayAttendanceCountProvider);
    final outstandingAdvances = ref.watch(outstandingAdvanceTotalProvider);
    final pendingPayments = ref.watch(pendingPaymentsCountProvider);
    final currentMonthPayroll = ref.watch(currentMonthPayrollProvider);
    final currentMonthExpenses = ref.watch(currentMonthExpensesTotalProvider);

    final isDark = context.isDarkMode;

    String formatCount(AsyncValue<int> value) {
      return value.when(
        data: (count) => count.toString(),
        loading: () => '--',
        error: (_, _) => 'N/A',
      );
    }

    String formatAmount(AsyncValue<double> value) {
      return value.when(
        data: (amount) => '₹${amount.toStringAsFixed(0)}',
        loading: () => '--',
        error: (_, _) => 'N/A',
      );
    }

    final cards = [
      _DashboardCardConfig(
        title: 'Total Sites',
        value: formatCount(totalSites),
        icon: Icons.location_on,
        gradient: isDark
            ? const LinearGradient(
                colors: [Color(0xFF251A55), Color(0xFF1A123D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFFF4F0FF), Color(0xFFE8DDFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        overlayIcon: Icons.business_outlined,
        iconColor: const Color(0xFF7B4DFF),
        iconBackgroundColor: const Color(0xFF7B4DFF).withValues(alpha: 0.15),
        glowColor: const Color(0xFF7B4DFF),
        onTap: () {
          Navigator.of(context).pushNamed(AppRoutes.sites);
        },
      ),
      _DashboardCardConfig(
        title: 'Active Labour',
        value: formatCount(activeLabour),
        icon: Icons.people,
        gradient: isDark
            ? const LinearGradient(
                colors: [Color(0xFF103B2C), Color(0xFF132E27)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFFE8FDF5), Color(0xFFD0FBEB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        overlayIcon: Icons.groups_rounded,
        iconColor: const Color(0xFF00D68F),
        iconBackgroundColor: const Color(0xFF00D68F).withValues(alpha: 0.15),
        glowColor: const Color(0xFF00D68F),
        onTap: () {
          Navigator.of(context).pushNamed(AppRoutes.labour);
        },
      ),
      _DashboardCardConfig(
        title: "Today's Attendance",
        value: formatCount(todayAttendance),
        icon: Icons.today,
        gradient: isDark
            ? const LinearGradient(
                colors: [Color(0xFF102F55), Color(0xFF152A4B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFFEBF3FF), Color(0xFFD6E7FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        overlayIcon: Icons.calendar_today_rounded,
        iconColor: const Color(0xFF3D8BFF),
        iconBackgroundColor: const Color(0xFF3D8BFF).withValues(alpha: 0.15),
        glowColor: const Color(0xFF3D8BFF),
        onTap: () {
          Navigator.of(context).pushNamed(AppRoutes.attendance);
        },
      ),
      _DashboardCardConfig(
        title: 'Outstanding Advances',
        value: formatAmount(outstandingAdvances),
        icon: Icons.account_balance_wallet,
        gradient: isDark
            ? const LinearGradient(
                colors: [Color(0xFF4A1630), Color(0xFF321022)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFFFFECEF), Color(0xFFFFD6DD)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        overlayIcon: Icons.account_balance_wallet_rounded,
        iconColor: const Color(0xFFFF5A7A),
        iconBackgroundColor: const Color(0xFFFF5A7A).withValues(alpha: 0.15),
        glowColor: const Color(0xFFFF5A7A),
        onTap: () {
          Navigator.of(context).pushNamed(AppRoutes.advances);
        },
      ),
      _DashboardCardConfig(
        title: 'Pending Payments',
        value: formatCount(pendingPayments),
        icon: Icons.payment,
        gradient: isDark
            ? const LinearGradient(
                colors: [Color(0xFF3E1B57), Color(0xFF2A143D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFFFFF7E6), Color(0xFFFFEBD0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        overlayIcon: Icons.analytics_rounded,
        iconColor: const Color(0xFFFFAA00),
        iconBackgroundColor: const Color(0xFFFFAA00).withValues(alpha: 0.15),
        glowColor: const Color(0xFFFFAA00),
        onTap: () {
          Navigator.of(context).pushNamed(AppRoutes.payments);
        },
      ),
      _DashboardCardConfig(
        title: 'Current Month Payroll',
        value: formatAmount(currentMonthPayroll),
        icon: Icons.money,
        gradient: isDark
            ? const LinearGradient(
                colors: [Color(0xFF4D3110), Color(0xFF35200C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        overlayIcon: Icons.receipt_long_rounded,
        iconColor: const Color(0xFFFFAA00),
        iconBackgroundColor: const Color(0xFFFFAA00).withValues(alpha: 0.15),
        glowColor: const Color(0xFFFFAA00),
        onTap: () {
          Navigator.of(context).pushNamed(AppRoutes.payroll);
        },
      ),
      _DashboardCardConfig(
        title: 'Current Month Expenses',
        value: formatAmount(currentMonthExpenses),
        icon: Icons.receipt_long,
        gradient: isDark
            ? const LinearGradient(
                colors: [Color(0xFF551A20), Color(0xFF3D1216)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFFFFF0F2), Color(0xFFFFD6DC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        overlayIcon: Icons.receipt_long_outlined,
        iconColor: const Color(0xFFFF3D57),
        iconBackgroundColor: const Color(0xFFFF3D57).withValues(alpha: 0.15),
        glowColor: const Color(0xFFFF3D57),
        onTap: () {
          Navigator.of(context).pushNamed(AppRoutes.expenses);
        },
      ),
    ];

    final pageContent = SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: 24.0,
        vertical: 32.0, // Generous spacing!
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Executive Dashboard Header
          const DashboardHeader(),
          const SizedBox(height: 12),

          // Hero KPI strip with animated metrics
          const HeroKpiStrip(),
          const SizedBox(height: 36),

          // Section Title: Executive Analytics
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              'Detailed Operations',
              style: TextStyle(
                fontFamily: 'NotoSans',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),

          // Responsive layout grid of KPI cards
          LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;
              final textScale = MediaQuery.maybeTextScalerOf(context)?.scale(1.0) ?? 1.0;
              final int crossAxisCount;
              final double childAspectRatio;
              
              if (availableWidth >= 900) {
                crossAxisCount = 3;
                childAspectRatio = 1.35 / textScale;
              } else if (availableWidth >= 550) {
                crossAxisCount = 2;
                childAspectRatio = 1.35 / textScale;
              } else {
                crossAxisCount = 1;
                childAspectRatio = 1.6 / textScale;
              }
              
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: childAspectRatio,
                ),
                itemCount: cards.length,
                itemBuilder: (context, index) {
                  final card = cards[index];
                  return TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 300 + (index * 100)),
                    curve: Curves.easeOutCubic,
                    builder: (context, val, child) {
                      return Opacity(
                        opacity: val,
                        child: Transform.translate(
                          offset: Offset(0, 15 * (1.0 - val)),
                          child: child,
                        ),
                      );
                    },
                    child: DashboardCard(
                      title: card.title,
                      value: card.value,
                      icon: card.icon,
                      gradient: card.gradient,
                      overlayIcon: card.overlayIcon,
                      iconColor: card.iconColor,
                      iconBackgroundColor: card.iconBackgroundColor,
                      glowColor: card.glowColor,
                      onTap: card.onTap,
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 40),

          // Quick Actions section
          Text(
            'Quick Actions',
            style: TextStyle(
              fontFamily: 'NotoSans',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          // Glass-like container for quick actions list
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.02),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Column(
                  children: [
                    QuickActionTile(
                      label: 'Financial Reports',
                      icon: Icons.assessment_outlined,
                      onTap: () {
                        Navigator.pushNamed(context, '/reports');
                      },
                    ),
                    Divider(
                      height: 1,
                      color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black12,
                    ),
                    QuickActionTile(
                      label: 'Payroll Dashboard',
                      icon: Icons.receipt_long_outlined,
                      onTap: () {
                        Navigator.pushNamed(context, '/payroll');
                      },
                    ),
                    Divider(
                      height: 1,
                      color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black12,
                    ),
                    QuickActionTile(
                      label: 'Manage Sites',
                      icon: Icons.location_on_outlined,
                      onTap: () {
                        Navigator.pushNamed(context, '/sites');
                      },
                    ),
                    Divider(
                      height: 1,
                      color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black12,
                    ),
                    QuickActionTile(
                      label: 'Co-Owner Management',
                      icon: Icons.people_outline,
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.teamManagement);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    // Staggered page entrance animation
    return AppScaffold(
      usePremiumBackground: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        builder: (context, animValue, child) {
          return Opacity(
            opacity: animValue,
            child: Transform.translate(
              offset: Offset(0, 30 * (1.0 - animValue)),
              child: child,
            ),
          );
        },
        child: pageContent,
      ),
    );
  }
}
