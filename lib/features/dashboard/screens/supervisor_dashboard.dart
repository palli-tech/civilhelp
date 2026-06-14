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

class SupervisorDashboard extends ConsumerWidget {
  const SupervisorDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignedSitesCount = ref.watch(supervisorAssignedSitesCountProvider);
    final todayAttendanceCount = ref.watch(supervisorTodayAttendanceCountProvider);
    final presentWorkersCount = ref.watch(supervisorPresentWorkersCountProvider);
    final absentWorkersCount = ref.watch(supervisorAbsentWorkersCountProvider);
    final pendingAttendanceCount = ref.watch(supervisorPendingAttendanceCountProvider);

    final isDark = context.isDarkMode;

    String formatCount(AsyncValue<int> value) {
      return value.when(
        data: (count) => count.toString(),
        loading: () => '--',
        error: (_, _) => 'N/A',
      );
    }

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

    Widget buildCard(int index) {
      switch (index) {
        case 0:
          return DashboardCard(
            title: 'Assigned Sites',
            value: formatCount(assignedSitesCount),
            icon: Icons.location_on,
            overlayIcon: Icons.business_outlined,
            gradient: const LinearGradient(
              colors: [Color(0xFF251A55), Color(0xFF1A123D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            iconColor: const Color(0xFF7B4DFF),
            iconBackgroundColor: const Color(0xFF7B4DFF).withOpacity(0.15),
            glowColor: const Color(0xFF7B4DFF),
            onTap: () {
              Navigator.of(context).pushNamed(AppRoutes.sites);
            },
          );
        case 1:
          return DashboardCard(
            title: "Today's Attendance",
            value: formatCount(todayAttendanceCount),
            icon: Icons.today,
            overlayIcon: Icons.calendar_today_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFF102F55), Color(0xFF152A4B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            iconColor: const Color(0xFF3D8BFF),
            iconBackgroundColor: const Color(0xFF3D8BFF).withOpacity(0.15),
            glowColor: const Color(0xFF3D8BFF),
            onTap: () {
              Navigator.of(context).pushNamed(AppRoutes.attendance);
            },
          );
        case 2:
          return DashboardCard(
            title: 'Present Workers',
            value: formatCount(presentWorkersCount),
            icon: Icons.check_circle,
            overlayIcon: Icons.check_circle_outline_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFF103B2C), Color(0xFF132E27)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            iconColor: const Color(0xFF00D68F),
            iconBackgroundColor: const Color(0xFF00D68F).withOpacity(0.15),
            glowColor: const Color(0xFF00D68F),
          );
        case 3:
          return DashboardCard(
            title: 'Absent Workers',
            value: formatCount(absentWorkersCount),
            icon: Icons.cancel,
            overlayIcon: Icons.cancel_outlined,
            gradient: const LinearGradient(
              colors: [Color(0xFF4A1630), Color(0xFF321022)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            iconColor: const Color(0xFFFF5A7A),
            iconBackgroundColor: const Color(0xFFFF5A7A).withOpacity(0.15),
            glowColor: const Color(0xFFFF5A7A),
          );
        case 4:
          return DashboardCard(
            title: 'Pending Attendance',
            value: formatCount(pendingAttendanceCount),
            icon: Icons.pending_actions,
            overlayIcon: Icons.pending_actions_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFF3E1B57), Color(0xFF2A143D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            iconColor: const Color(0xFFFFAA00),
            iconBackgroundColor: const Color(0xFFFFAA00).withOpacity(0.15),
            glowColor: const Color(0xFFFFAA00),
            onTap: () {
              Navigator.of(context).pushNamed(AppRoutes.attendance);
            },
          );
        default:
          return const SizedBox.shrink();
      }
    }

    final pageContent = SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: 24.0,
        vertical: 32.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DashboardHeader(),
          const SizedBox(height: 16),

          Text(
            'Supervisor Overview',
            style: TextStyle(
              fontFamily: 'NotoSans',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          // Responsive grid layout of cards
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: 5,
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
                child: buildCard(index),
              );
            },
          ),
          const SizedBox(height: 40),

          // Supervisor Quick Actions
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
                      label: 'Mark Attendance',
                      icon: Icons.check_circle_outline_rounded,
                      onTap: () {
                        Navigator.of(context).pushNamed(AppRoutes.attendance);
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
