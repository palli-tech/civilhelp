import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import 'package:civilhelp/app/theme.dart';
import 'package:civilhelp/core/providers/tenant_provider.dart';
import '../../../shared/widgets/profile_menu_button.dart';

class DashboardHeader extends ConsumerWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenantCompanyAsync = ref.watch(tenantCompanyStreamProvider);
    final isDark = context.isDarkMode;

    final companyName = tenantCompanyAsync.maybeWhen(
      data: (company) => company?.name ?? 'PalliVerse Technologies',
      orElse: () => 'PalliVerse Technologies',
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



    Widget glassButton({required Widget child, required VoidCallback onTap}) {
      return Container(
        width: 36,
        height: 36,
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
              child: Center(child: child),
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Greetings, Date & Company Name
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
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
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        greeting,
                        style: TextStyle(
                          fontFamily: 'NotoSans',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFFB4B8D0) : Colors.black54,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        companyName,
                        style: TextStyle(
                          fontFamily: 'NotoSans',
                          fontSize: isMobile ? 24 : 32,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.black87,
                          height: 1.15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Right: Theme toggle & Clickable Profile Avatar Menu
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              glassButton(
                onTap: () {
                  ref.read(themeProvider.notifier).setThemeMode(
                    isDark ? AppThemeMode.light : AppThemeMode.dark,
                  );
                },
                child: Icon(
                  isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  color: isDark ? Colors.white : Colors.black87,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const ProfileMenuButton(),
            ],
          ),
        ],
      ),
    );
  }
}
