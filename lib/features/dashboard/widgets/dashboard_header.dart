import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:civilhelp/features/auth/providers/auth_provider.dart';

import 'package:civilhelp/app/theme.dart';



class DashboardHeader extends ConsumerWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDarkMode;
    final currentUser = ref.watch(currentUserProvider);
    final userDataAsync = ref.watch(userDataProvider);

    final userName = userDataAsync.maybeWhen(
      data: (userData) => userData?['name'] as String? ?? currentUser?.displayName ?? 'User',
      orElse: () => currentUser?.displayName ?? 'User',
    );

    final firstName = userName.trim().split(RegExp(r'\s+')).first;



    final String greeting;
    final hour = DateTime.now().hour;
    if (hour < 12) {
      greeting = 'Good Morning, $firstName 👋';
    } else if (hour < 17) {
      greeting = 'Good Afternoon, $firstName 👋';
    } else {
      greeting = 'Good Evening, $firstName 👋';
    }





    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
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
            child: Text(
              greeting,
              style: TextStyle(
                fontFamily: 'NotoSans',
                fontSize: isMobile ? 16 : 22,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black87,
                height: 1.25,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
