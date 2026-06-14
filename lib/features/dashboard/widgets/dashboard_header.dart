import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:civilhelp/app/theme.dart';
import 'package:civilhelp/core/providers/user_role_provider.dart';
import 'package:civilhelp/core/providers/tenant_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';

class DashboardHeader extends ConsumerWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final userDataAsync = ref.watch(userDataProvider);
    final tenantCompanyAsync = ref.watch(tenantCompanyStreamProvider);
    final role = ref.watch(userRoleProvider);
    final themeMode = ref.watch(themeProvider);

    final isDark = context.isDarkMode;

    final companyName = tenantCompanyAsync.maybeWhen(
      data: (company) => company?.name ?? 'PalliVerse Technologies',
      orElse: () => 'PalliVerse Technologies',
    );

    final userName = userDataAsync.maybeWhen(
      data: (userData) => userData?['name'] as String? ?? currentUser?.displayName ?? 'User',
      orElse: () => currentUser?.displayName ?? 'User',
    );

    final String greeting;
    final hour = DateTime.now().hour;
    if (hour < 12) {
      greeting = 'Good Morning 👋';
    } else if (hour < 17) {
      greeting = 'Good Afternoon 👋';
    } else {
      greeting = 'Good Evening 👋';
    }

    final roleTitle = '${role.displayName} Dashboard';

    Widget glassButton({required Widget child, required VoidCallback onTap}) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
          ),
        ),
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: child,
              ),
            ),
          ),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Greetings & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isMobile) ...[
                      IconButton(
                        icon: Icon(
                          Icons.menu,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        onPressed: () {
                          Scaffold.of(context).openDrawer();
                        },
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      greeting,
                      style: TextStyle(
                        fontFamily: 'NotoSans',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFB4B8D0) : Colors.black54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  companyName,
                  style: TextStyle(
                    fontFamily: 'NotoSans',
                    fontSize: isMobile ? 24 : 32,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  roleTitle,
                  style: TextStyle(
                    fontFamily: 'NotoSans',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFF7B4DFF) : context.colors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Right: Notifications, Theme toggle, Avatar
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              glassButton(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No new notifications')),
                  );
                },
                child: Icon(
                  Icons.notifications_none_rounded,
                  color: isDark ? Colors.white : Colors.black87,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              glassButton(
                onTap: () {
                  ref.read(themeProvider.notifier).setThemeMode(
                    isDark ? AppThemeMode.light : AppThemeMode.dark,
                  );
                },
                child: Icon(
                  isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  color: isDark ? Colors.white : Colors.black87,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              // User Initial Avatar
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.12),
                    width: 1.5,
                  ),
                ),
                child: ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Center(
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
