import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:civilhelp/app/theme.dart';
import 'package:civilhelp/app/router.dart';
import '../../../shared/layouts/app_scaffold.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/dashboard_metrics_provider.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/quick_action_tile.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/hero_kpi_strip.dart';

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

    // Determine grid cross axis count and aspect ratio based on width
    final screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount;
    final double childAspectRatio;
    if (screenWidth >= 1200) {
      crossAxisCount = 3;
      childAspectRatio = 1.35;
    } else if (screenWidth >= 600) {
      crossAxisCount = 2;
      childAspectRatio = 1.35;
    } else {
      crossAxisCount = 1;
      childAspectRatio = 1.6;
    }

    Widget buildDashboardCard(int index) {
      switch (index) {
        case 0:
          return DashboardCard(
            title: 'Total Sites',
            value: formatCount(totalSites),
            icon: Icons.location_on,
            gradient: const LinearGradient(
              colors: [Color(0xFF251A55), Color(0xFF1A123D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            overlayIcon: Icons.business_outlined,
            iconColor: const Color(0xFF7B4DFF),
            iconBackgroundColor: const Color(0xFF7B4DFF).withOpacity(0.15),
            glowColor: const Color(0xFF7B4DFF),
            onTap: () {
              Navigator.of(context).pushNamed(AppRoutes.sites);
            },
          );
        case 1:
          return DashboardCard(
            title: 'Active Labour',
            value: formatCount(activeLabour),
            icon: Icons.people,
            gradient: const LinearGradient(
              colors: [Color(0xFF103B2C), Color(0xFF132E27)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            overlayIcon: Icons.groups_rounded,
            iconColor: const Color(0xFF00D68F),
            iconBackgroundColor: const Color(0xFF00D68F).withOpacity(0.15),
            glowColor: const Color(0xFF00D68F),
            onTap: () {
              Navigator.of(context).pushNamed(AppRoutes.labour);
            },
          );
        case 2:
          return DashboardCard(
            title: "Today's Attendance",
            value: formatCount(todayAttendance),
            icon: Icons.today,
            gradient: const LinearGradient(
              colors: [Color(0xFF102F55), Color(0xFF152A4B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            overlayIcon: Icons.calendar_today_rounded,
            iconColor: const Color(0xFF3D8BFF),
            iconBackgroundColor: const Color(0xFF3D8BFF).withOpacity(0.15),
            glowColor: const Color(0xFF3D8BFF),
            onTap: () {
              Navigator.of(context).pushNamed(AppRoutes.attendance);
            },
          );
        case 3:
          return DashboardCard(
            title: 'Outstanding Advances',
            value: formatAmount(outstandingAdvances),
            icon: Icons.account_balance_wallet,
            gradient: const LinearGradient(
              colors: [Color(0xFF4A1630), Color(0xFF321022)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            overlayIcon: Icons.account_balance_wallet_rounded,
            iconColor: const Color(0xFFFF5A7A),
            iconBackgroundColor: const Color(0xFFFF5A7A).withOpacity(0.15),
            glowColor: const Color(0xFFFF5A7A),
            onTap: () {
              Navigator.of(context).pushNamed(AppRoutes.advances);
            },
          );
        case 4:
          return DashboardCard(
            title: 'Pending Payments',
            value: formatCount(pendingPayments),
            icon: Icons.payment,
            gradient: const LinearGradient(
              colors: [Color(0xFF3E1B57), Color(0xFF2A143D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            overlayIcon: Icons.analytics_rounded,
            iconColor: const Color(0xFFFFAA00),
            iconBackgroundColor: const Color(0xFFFFAA00).withOpacity(0.15),
            glowColor: const Color(0xFFFFAA00),
            onTap: () {
              Navigator.of(context).pushNamed(AppRoutes.payments);
            },
          );
        case 5:
          return DashboardCard(
            title: 'Current Month Payroll',
            value: formatAmount(currentMonthPayroll),
            icon: Icons.money,
            gradient: const LinearGradient(
              colors: [Color(0xFF4D3110), Color(0xFF35200C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            overlayIcon: Icons.receipt_long_rounded,
            iconColor: const Color(0xFFFFAA00),
            iconBackgroundColor: const Color(0xFFFFAA00).withOpacity(0.15),
            glowColor: const Color(0xFFFFAA00),
            onTap: () {
              Navigator.of(context).pushNamed(AppRoutes.payroll);
            },
          );
        default:
          return const SizedBox.shrink();
      }
    }

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
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: 6,
            itemBuilder: (context, index) {
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
                child: buildDashboardCard(index),
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
              color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
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
                      color: isDark ? Colors.white.withOpacity(0.08) : Colors.black12,
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
                      color: isDark ? Colors.white.withOpacity(0.08) : Colors.black12,
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
                      color: isDark ? Colors.white.withOpacity(0.08) : Colors.black12,
                    ),
                    QuickActionTile(
                      label: 'Partner Management',
                      icon: Icons.people_outline,
                      onTap: () {},
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
