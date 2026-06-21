import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:civilhelp/app/theme.dart';
import '../../../shared/layouts/app_scaffold.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/quick_action_tile.dart';
import '../widgets/dashboard_header.dart';

class PartnerDashboard extends StatelessWidget {
  const PartnerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    final screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount;
    final double childAspectRatio;
    if (screenWidth >= 1200) {
      crossAxisCount = 4;
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
          return const DashboardCard(
            title: 'Active Projects',
            value: '8',
            icon: Icons.work,
            overlayIcon: Icons.business_center_outlined,
            iconColor: Color(0xFF7B4DFF),
            iconBackgroundColor: Color(0x227B4DFF),
            glowColor: Color(0xFF7B4DFF),
          );
        case 1:
          return const DashboardCard(
            title: 'Total Revenue',
            value: '₹2.4L',
            icon: Icons.trending_up,
            overlayIcon: Icons.trending_up_rounded,
            iconColor: Color(0xFF00D68F),
            iconBackgroundColor: Color(0x2200D68F),
            glowColor: Color(0xFF00D68F),
          );
        case 2:
          return const DashboardCard(
            title: 'Labour Assigned',
            value: '156',
            icon: Icons.people,
            overlayIcon: Icons.groups_rounded,
            iconColor: Color(0xFF3D8BFF),
            iconBackgroundColor: Color(0x223D8BFF),
            glowColor: Color(0xFF3D8BFF),
          );
        case 3:
          return const DashboardCard(
            title: 'Pending Bills',
            value: '5',
            icon: Icons.receipt,
            overlayIcon: Icons.receipt_long_rounded,
            iconColor: Color(0xFFFF5A7A),
            iconBackgroundColor: Color(0x22FFFF5A7A),
            glowColor: Color(0xFFFF5A7A),
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
            'Partner Analytics',
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
            itemCount: 4,
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

          // Partner Quick Actions
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
                      label: 'View Projects',
                      icon: Icons.work_outline,
                      onTap: () {},
                    ),
                    Divider(
                      height: 1,
                      color: isDark ? Colors.white.withOpacity(0.08) : Colors.black12,
                    ),
                    QuickActionTile(
                      label: 'Billing',
                      icon: Icons.payment_outlined,
                      onTap: () {},
                    ),
                    Divider(
                      height: 1,
                      color: isDark ? Colors.white.withOpacity(0.08) : Colors.black12,
                    ),
                    QuickActionTile(
                      label: 'Performance',
                      icon: Icons.bar_chart_outlined,
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
