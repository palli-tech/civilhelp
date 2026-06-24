import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:civilhelp/app/theme.dart';
import 'package:civilhelp/core/auth/permissions.dart';
import 'package:civilhelp/core/providers/user_role_provider.dart';
import 'package:civilhelp/app/router.dart';
import 'package:civilhelp/core/providers/tenant_provider.dart';
import 'package:civilhelp/core/enums/user_role.dart';
import '../../features/auth/providers/auth_provider.dart';

class AppDrawer extends ConsumerStatefulWidget {
  const AppDrawer({super.key});

  @override
  ConsumerState<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends ConsumerState<AppDrawer> {
  bool _isMenuOpen = false;
  bool _isHovered = false;
  bool _isPressed = false;

  Widget _buildAccountMenuItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isDark,
    required VoidCallback onTap,
    String? routeName,
    bool isLogout = false,
  }) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final isActive = routeName != null && currentRoute == routeName;

    Color? textColor;
    Color? iconColor;
    Color? backgroundColor;

    if (isLogout) {
      textColor = Colors.redAccent;
      iconColor = Colors.redAccent.withValues(alpha: 0.8);
    } else {
      if (isActive) {
        textColor = const Color(0xFF7B4DFF);
        iconColor = const Color(0xFF7B4DFF);
        backgroundColor = const Color(0xFF7B4DFF).withValues(alpha: 0.08);
      } else {
        textColor = isDark ? Colors.white70 : Colors.black87;
        iconColor = isDark ? Colors.white54 : Colors.black54;
      }
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: backgroundColor,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          hoverColor: isLogout
              ? Colors.redAccent.withValues(alpha: 0.08)
              : const Color(0xFF7B4DFF).withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: iconColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'NotoSans',
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAppearanceDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final activeThemeMode = ref.watch(themeProvider);
            return AlertDialog(
              title: const Text('Appearance Preferences'),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<AppThemeMode>(
                    title: const Text('Light Theme'),
                    secondary: const Icon(Icons.light_mode_outlined),
                    value: AppThemeMode.light,
                    groupValue: activeThemeMode,
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(themeProvider.notifier).setThemeMode(val);
                      }
                    },
                  ),
                  RadioListTile<AppThemeMode>(
                    title: const Text('Dark Theme'),
                    secondary: const Icon(Icons.dark_mode_outlined),
                    value: AppThemeMode.dark,
                    groupValue: activeThemeMode,
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(themeProvider.notifier).setThemeMode(val);
                      }
                    },
                  ),
                  RadioListTile<AppThemeMode>(
                    title: const Text('System Default'),
                    secondary: const Icon(Icons.settings_brightness_outlined),
                    value: AppThemeMode.system,
                    groupValue: activeThemeMode,
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(themeProvider.notifier).setThemeMode(val);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildProfileCard(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final userDataAsync = ref.watch(userDataProvider);
    final tenantCompanyAsync = ref.watch(tenantCompanyStreamProvider);

    final isDark = context.isDarkMode;

    final companyName = tenantCompanyAsync.maybeWhen(
      data: (company) => company?.name ?? 'PalliVerse Technologies',
      orElse: () => 'PalliVerse Technologies',
    );

    final userName = userDataAsync.maybeWhen(
      data: (userData) => userData?['name'] as String? ?? currentUser?.displayName ?? 'User',
      orElse: () => currentUser?.displayName ?? 'User',
    );

    final initials = userName.isNotEmpty
        ? userName.trim().split(RegExp(r'\s+')).map((s) => s[0]).take(2).join().toUpperCase()
        : 'U';

    double scale = 1.0;
    if (_isPressed) {
      scale = 0.99;
    } else if (_isHovered) {
      scale = 1.01;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: isDark
                  ? const LinearGradient(
                      colors: [
                        Color(0xFF130D32),
                        Color(0xFF1A1140),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : LinearGradient(
                      colors: [
                        Colors.white,
                        Color.lerp(Colors.white, const Color(0xFF7B4DFF), 0.03)!,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              border: Border.all(
                color: _isMenuOpen
                    ? const Color(0xFF7B4DFF).withValues(alpha: 0.20)
                    : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06)),
                width: _isMenuOpen ? 1.5 : 1.0,
              ),
              boxShadow: [
                if (_isMenuOpen)
                  BoxShadow(
                    color: const Color(0xFF7B4DFF).withValues(alpha: 0.18),
                    blurRadius: 24,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  )
                else
                  BoxShadow(
                    color: isDark
                        ? const Color(0xFF7B4DFF).withValues(alpha: _isHovered ? 0.15 : 0.08)
                        : Colors.black.withValues(alpha: _isHovered ? 0.08 : 0.04),
                    blurRadius: _isHovered ? 20 : 12,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  Positioned(
                    bottom: -20,
                    right: -20,
                    child: Icon(
                      Icons.domain_outlined,
                      size: 80,
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _isMenuOpen = !_isMenuOpen;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                            child: Row(
                              children: [
                                Stack(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [
                                            Color(0xFF7B4DFF),
                                            Color(0xFF5F2EEA),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          initials,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF00C853),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isDark ? const Color(0xFF130D32) : Colors.white,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        userName,
                                        style: TextStyle(
                                          color: isDark ? Colors.white : Colors.black87,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.3,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        companyName,
                                        style: TextStyle(
                                          color: isDark ? Colors.white70 : Colors.black54,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                AnimatedRotation(
                                  turns: _isMenuOpen ? 0.5 : 0.0,
                                  duration: const Duration(milliseconds: 220),
                                  child: Icon(
                                    Icons.expand_more_rounded,
                                    color: isDark ? Colors.white70 : Colors.black54,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeInOut,
                        child: AnimatedOpacity(
                          opacity: _isMenuOpen ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeInOut,
                          child: _isMenuOpen
                              ? Padding(
                                  padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(height: 4),
                                      _buildAccountMenuItem(
                                        context: context,
                                        icon: Icons.person_outline_rounded,
                                        label: 'My Profile',
                                        routeName: AppRoutes.profileSetup,
                                        isDark: isDark,
                                        onTap: () {
                                          setState(() {
                                            _isMenuOpen = false;
                                          });
                                          Navigator.of(context).pushNamed(AppRoutes.profileSetup);
                                        },
                                      ),
                                      const SizedBox(height: 6),
                                      _buildAccountMenuItem(
                                        context: context,
                                        icon: Icons.palette_outlined,
                                        label: 'Appearance',
                                        isDark: isDark,
                                        onTap: () {
                                          setState(() {
                                            _isMenuOpen = false;
                                          });
                                          _showAppearanceDialog(context, ref);
                                        },
                                      ),
                                      const SizedBox(height: 6),
                                      _buildAccountMenuItem(
                                        context: context,
                                        icon: Icons.logout_outlined,
                                        label: 'Logout',
                                        isDark: isDark,
                                        isLogout: true,
                                        onTap: () async {
                                          setState(() {
                                            _isMenuOpen = false;
                                          });
                                          final authService = ref.read(authServiceProvider);
                                          await authService.signOut();
                                          if (context.mounted) {
                                            Navigator.of(context).pushReplacementNamed('/login');
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(userRoleProvider);
    final isDark = context.isDarkMode;
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
                      color: const Color(0xFF7B4DFF).withValues(alpha: 0.35),
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
                          : (isDark ? Colors.white70 : Colors.black54),
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
                              : (isDark ? Colors.white70 : Colors.black87),
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

    final sidebarContent = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: isDark
            ? const LinearGradient(
                colors: [
                  Color(0xFF130D32),
                  Color(0xFF1A1140),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : LinearGradient(
                colors: [
                  Colors.white,
                  Color.lerp(Colors.white, const Color(0xFF7B4DFF), 0.03)!,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Theme.of(context).dividerColor.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              bottom: -40,
              right: -40,
              child: Icon(
                Icons.domain_outlined,
                size: 150,
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0),
                  child: _buildProfileCard(context, ref),
                ),
                const SizedBox(height: 12),
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
                      if (role == UserRole.admin) ...[
                        buildNavItem(
                          icon: Icons.business_outlined,
                          title: 'Company Management',
                          routeName: AppRoutes.companyManagement,
                          onTap: () {
                            if (currentRoute != AppRoutes.companyManagement) {
                              if (Scaffold.of(context).isDrawerOpen) Navigator.pop(context);
                              Navigator.of(context).pushNamed(AppRoutes.companyManagement);
                            }
                          },
                        ),
                        buildNavItem(
                          icon: Icons.analytics_outlined,
                          title: 'System Analytics',
                          routeName: AppRoutes.adminAnalytics,
                          onTap: () {
                            if (currentRoute != AppRoutes.adminAnalytics) {
                              if (Scaffold.of(context).isDrawerOpen) Navigator.pop(context);
                              Navigator.of(context).pushNamed(AppRoutes.adminAnalytics);
                            }
                          },
                        ),
                      ],
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
                      if (role.canAccessExpenses)
                        buildNavItem(
                          icon: Icons.receipt_long_outlined,
                          title: 'Expenses',
                          routeName: AppRoutes.expenses,
                          onTap: () {
                            if (currentRoute != AppRoutes.expenses) {
                              if (Scaffold.of(context).isDrawerOpen) Navigator.pop(context);
                              Navigator.of(context).pushNamed(AppRoutes.expenses);
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
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) {
      return Drawer(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 0.0, 16.0),
            child: sidebarContent,
          ),
        ),
      );
    }
    return sidebarContent;
  }
}
