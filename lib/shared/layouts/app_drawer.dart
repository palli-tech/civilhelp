import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:civilhelp/app/theme.dart';
import 'package:civilhelp/core/auth/permissions.dart';
import 'package:civilhelp/core/providers/user_role_provider.dart';
import 'package:civilhelp/app/router.dart';
import 'package:civilhelp/core/providers/tenant_provider.dart';
import '../../features/auth/providers/auth_provider.dart';

class WavePainter extends CustomPainter {
  final Color color;

  WavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.55,
      size.width * 0.5,
      size.height * 0.7,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.85,
      size.width,
      size.height * 0.6,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);

    final path2 = Path();
    path2.moveTo(0, size.height * 0.8);
    path2.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.9,
      size.width * 0.6,
      size.height * 0.75,
    );
    path2.quadraticBezierTo(
      size.width * 0.85,
      size.height * 0.6,
      size.width,
      size.height * 0.75,
    );
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();

    final paint2 = Paint()
      ..color = color.withValues(alpha: color.opacity * 0.5)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final userDataAsync = ref.watch(userDataProvider);
    final tenantCompanyAsync = ref.watch(tenantCompanyStreamProvider);
    final role = ref.watch(userRoleProvider);

    final isDark = context.isDarkMode;

    // Check currently active route
    final currentRoute = ModalRoute.of(context)?.settings.name;

    Widget buildNavItem({
      required IconData icon,
      required String title,
      required String routeName,
      required VoidCallback onTap,
    }) {
      final isActive = currentRoute == routeName;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isActive
                ? const LinearGradient(
                    colors: [
                      Color(0xFF7B4DFF),
                      Color(0xFF5F2EEA),
                    ],
                  )
                : null,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFF7B4DFF).withOpacity(0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      color: isActive
                          ? Colors.white
                          : (isDark ? const Color(0xFFB4B8D0) : Colors.black54),
                      size: 20,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'NotoSans',
                          fontSize: 14,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                          color: isActive
                              ? Colors.white
                              : (isDark ? const Color(0xFFB4B8D0) : Colors.black87),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final companyName = tenantCompanyAsync.maybeWhen(
      data: (company) => company?.name ?? 'PalliVerse Technologies',
      orElse: () => 'PalliVerse Technologies',
    );

    final companyLogoUrl = tenantCompanyAsync.maybeWhen(
      data: (company) => company?.logoUrl,
      orElse: () => null,
    );

    final userName = userDataAsync.maybeWhen(
      data: (userData) => userData?['name'] as String? ?? currentUser?.displayName ?? 'User',
      orElse: () => currentUser?.displayName ?? 'User',
    );

    final formattedRole = role.displayName;

    final sidebarContent = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: isDark
            ? const LinearGradient(
                colors: [
                  Color(0xFF1A1140),
                  Color(0xFF130D32),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : null,
        color: isDark ? null : Colors.white.withOpacity(0.95),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Redesigned Company Profile Card
                Container(
                  margin: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                              const Color(0xFF7B4DFF).withOpacity(0.15),
                              const Color(0xFF1B2142).withOpacity(0.4),
                            ]
                          : [
                              const Color(0xFF7B4DFF).withOpacity(0.08),
                              Colors.grey.shade100,
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        // Decorative wave patterns
                        Positioned.fill(
                          child: CustomPaint(
                            painter: WavePainter(
                              color: const Color(0xFF7B4DFF).withOpacity(isDark ? 0.08 : 0.04),
                            ),
                          ),
                        ),
                        // Profile details
                        Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  // Logo Avatar
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF7B4DFF).withOpacity(0.3),
                                        width: 1.5,
                                      ),
                                      color: isDark ? const Color(0xFF12182F) : Colors.white,
                                    ),
                                    child: ClipOval(
                                      child: companyLogoUrl != null
                                          ? Image.network(
                                              companyLogoUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) =>
                                                  const Icon(Icons.business, color: Color(0xFF7B4DFF), size: 20),
                                            )
                                          : const Icon(Icons.business, color: Color(0xFF7B4DFF), size: 20),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          companyName,
                                          style: TextStyle(
                                            color: isDark ? Colors.white : Colors.black87,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.2,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF7B4DFF).withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            formattedRole.toUpperCase(),
                                            style: const TextStyle(
                                              color: Color(0xFF7B4DFF),
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Active User Status
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 22,
                                          height: 22,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isDark ? const Color(0xFF1B2142) : Colors.grey.shade300,
                                          ),
                                          child: Center(
                                            child: Text(
                                              userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                                              style: TextStyle(
                                                color: isDark ? Colors.white : Colors.black87,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            userName,
                                            style: TextStyle(
                                              color: isDark ? const Color(0xFFB4B8D0) : Colors.black54,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color(0xFF00D68F),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'Active',
                                        style: TextStyle(
                                          color: Color(0xFF00D68F),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Navigation Items List
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      buildNavItem(
                        icon: Icons.dashboard_outlined,
                        title: 'Dashboard',
                        routeName: AppRoutes.dashboard,
                        onTap: () {
                          if (currentRoute != AppRoutes.dashboard) {
                            if (ModalRoute.of(context)?.isCurrent == false) {
                              Navigator.pop(context);
                            }
                            Navigator.of(context).pushNamed(AppRoutes.dashboard);
                          } else {
                            if (Scaffold.of(context).isDrawerOpen) {
                              Navigator.pop(context);
                            }
                          }
                        },
                      ),
                      if (role.canAccessSites)
                        buildNavItem(
                          icon: Icons.location_on_outlined,
                          title: 'Sites',
                          routeName: AppRoutes.sites,
                          onTap: () {
                            if (currentRoute != AppRoutes.sites) {
                              if (Scaffold.of(context).isDrawerOpen) Navigator.pop(context);
                              Navigator.of(context).pushNamed(AppRoutes.sites);
                            }
                          },
                        ),
                      if (role.canAccessLabour)
                        buildNavItem(
                          icon: Icons.people_outline,
                          title: 'Labour',
                          routeName: AppRoutes.labour,
                          onTap: () {
                            if (currentRoute != AppRoutes.labour) {
                              if (Scaffold.of(context).isDrawerOpen) Navigator.pop(context);
                              Navigator.of(context).pushNamed(AppRoutes.labour);
                            }
                          },
                        ),
                      if (role.canAccessAttendance)
                        buildNavItem(
                          icon: Icons.calendar_today_outlined,
                          title: 'Attendance',
                          routeName: AppRoutes.attendance,
                          onTap: () {
                            if (currentRoute != AppRoutes.attendance) {
                              if (Scaffold.of(context).isDrawerOpen) Navigator.pop(context);
                              Navigator.of(context).pushNamed(AppRoutes.attendance);
                            }
                          },
                        ),
                      if (role.hasPermission(Permission.managePayments))
                        buildNavItem(
                          icon: Icons.receipt_long_outlined,
                          title: 'Payroll',
                          routeName: AppRoutes.payroll,
                          onTap: () {
                            if (currentRoute != AppRoutes.payroll) {
                              if (Scaffold.of(context).isDrawerOpen) Navigator.pop(context);
                              Navigator.of(context).pushNamed(AppRoutes.payroll);
                            }
                          },
                        ),
                      if (role.canAccessAdvances)
                        buildNavItem(
                          icon: Icons.account_balance_wallet_outlined,
                          title: 'Advances',
                          routeName: AppRoutes.advances,
                          onTap: () {
                            if (currentRoute != AppRoutes.advances) {
                              if (Scaffold.of(context).isDrawerOpen) Navigator.pop(context);
                              Navigator.of(context).pushNamed(AppRoutes.advances);
                            }
                          },
                        ),
                      if (role.canAccessReports)
                        buildNavItem(
                          icon: Icons.assessment_outlined,
                          title: 'Reports',
                          routeName: AppRoutes.reports,
                          onTap: () {
                            if (currentRoute != AppRoutes.reports) {
                              if (Scaffold.of(context).isDrawerOpen) Navigator.pop(context);
                              Navigator.of(context).pushNamed(AppRoutes.reports);
                            }
                          },
                        ),
                      
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                        child: Divider(
                          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black12,
                          height: 1,
                        ),
                      ),

                      if (role.canAccessSettings)
                        buildNavItem(
                          icon: Icons.settings_outlined,
                          title: 'Settings',
                          routeName: AppRoutes.settings,
                          onTap: () {
                            if (currentRoute != AppRoutes.settings) {
                              if (Scaffold.of(context).isDrawerOpen) Navigator.pop(context);
                              Navigator.of(context).pushNamed(AppRoutes.settings);
                            }
                          },
                        ),
                      buildNavItem(
                        icon: Icons.logout_outlined,
                        title: 'Logout',
                        routeName: '/logout',
                        onTap: () async {
                          if (Scaffold.of(context).isDrawerOpen) Navigator.pop(context);
                          final authService = ref.read(authServiceProvider);
                          await authService.signOut();
                          if (context.mounted) {
                            Navigator.of(context).pushReplacementNamed('/login');
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // If displayed on mobile, wrap with standard Drawer wrapper so it slides nicely
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) {
      return Drawer(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: sidebarContent,
      );
    }
    return sidebarContent;
  }
}
