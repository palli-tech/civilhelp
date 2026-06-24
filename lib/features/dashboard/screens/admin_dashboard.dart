import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:civilhelp/app/theme.dart';
import 'package:civilhelp/app/router.dart';
import '../../../shared/layouts/app_scaffold.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/quick_action_tile.dart';
import '../widgets/dashboard_header.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDarkMode;

    // Grid sizes computed dynamically below in LayoutBuilder

    Widget buildCard(int index, int totalCompanies, int pendingRequests, int totalOwners, int totalSites) {
      switch (index) {
        case 0:
          return DashboardCard(
            title: 'Total Companies',
            value: '$totalCompanies',
            icon: Icons.business,
            overlayIcon: Icons.business_outlined,
            iconColor: const Color(0xFF7B4DFF),
            iconBackgroundColor: const Color(0x227B4DFF),
            glowColor: const Color(0xFF7B4DFF),
          );
        case 1:
          return DashboardCard(
            title: 'Pending Requests',
            value: '$pendingRequests',
            icon: Icons.pending_actions,
            overlayIcon: Icons.pending_actions_rounded,
            iconColor: Colors.orange,
            iconBackgroundColor: Colors.orange.withOpacity(0.1),
            glowColor: Colors.orange,
          );
        case 2:
          return DashboardCard(
            title: 'Total Owners',
            value: '$totalOwners',
            icon: Icons.people,
            overlayIcon: Icons.people_outline,
            iconColor: const Color(0xFF3D8BFF),
            iconBackgroundColor: const Color(0x223D8BFF),
            glowColor: const Color(0xFF3D8BFF),
          );
        case 3:
          return DashboardCard(
            title: 'Total Sites',
            value: '$totalSites',
            icon: Icons.location_on,
            overlayIcon: Icons.location_on_outlined,
            iconColor: const Color(0xFF00D68F),
            iconBackgroundColor: const Color(0x2200D68F),
            glowColor: const Color(0xFF00D68F),
          );
        default:
          return const SizedBox.shrink();
      }
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('companies').snapshots(),
      builder: (context, companiesSnap) {
        final totalCompanies = companiesSnap.data?.docs.length ?? 0;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('company_requests')
              .where('status', isEqualTo: 'pending')
              .snapshots(),
          builder: (context, requestsSnap) {
            final pendingRequests = requestsSnap.data?.docs.length ?? 0;

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'owner')
                  .snapshots(),
              builder: (context, ownersSnap) {
                final totalOwners = ownersSnap.data?.docs.length ?? 0;

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collectionGroup('sites').snapshots(),
                  builder: (context, sitesSnap) {
                    final totalSites = sitesSnap.data?.docs.length ?? 0;

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
                            'Platform Overview',
                            style: TextStyle(
                              fontFamily: 'NotoSans',
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Responsive grid layout of cards
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final availableWidth = constraints.maxWidth;
                              final textScale = MediaQuery.maybeTextScalerOf(context)?.scale(1.0) ?? 1.0;
                              final int crossAxisCount;
                              final double childAspectRatio;

                              if (availableWidth >= 1000) {
                                crossAxisCount = 4;
                                childAspectRatio = 1.35 / textScale;
                              } else if (availableWidth >= 750) {
                                crossAxisCount = 3;
                                childAspectRatio = 1.35 / textScale;
                              } else if (availableWidth >= 500) {
                                crossAxisCount = 2;
                                childAspectRatio = 1.45 / textScale;
                              } else {
                                crossAxisCount = 1;
                                childAspectRatio = 1.8 / textScale;
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
                                    child: buildCard(
                                      index,
                                      totalCompanies,
                                      pendingRequests,
                                      totalOwners,
                                      totalSites,
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 40),

                          // Administration Quick Actions
                          Text(
                            'Administration',
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
                                      label: 'Company Management',
                                      icon: Icons.business_outlined,
                                      trailing: pendingRequests > 0
                                          ? Badge.count(count: pendingRequests)
                                          : null,
                                      onTap: () {
                                        Navigator.pushNamed(context, AppRoutes.companyManagement);
                                      },
                                    ),
                                    Divider(
                                      height: 1,
                                      color: isDark ? Colors.white.withOpacity(0.08) : Colors.black12,
                                    ),
                                    QuickActionTile(
                                      label: 'System Analytics',
                                      icon: Icons.analytics_outlined,
                                      onTap: () {
                                        Navigator.pushNamed(context, AppRoutes.adminAnalytics);
                                      },
                                    ),
                                    Divider(
                                      height: 1,
                                      color: isDark ? Colors.white.withOpacity(0.08) : Colors.black12,
                                    ),
                                    QuickActionTile(
                                      label: 'System Reports',
                                      icon: Icons.bar_chart_outlined,
                                      onTap: () {
                                        Navigator.pushNamed(context, AppRoutes.adminAnalytics);
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
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
