import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:civilhelp/app/theme.dart';
import 'package:civilhelp/app/router.dart';
import 'package:civilhelp/core/providers/user_role_provider.dart';
import 'package:civilhelp/features/auth/providers/auth_provider.dart';

class ProfileMenuButton extends ConsumerWidget {
  const ProfileMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final userDataAsync = ref.watch(userDataProvider);
    final role = ref.watch(userRoleProvider);
    final isDark = context.isDarkMode;

    final userName = userDataAsync.maybeWhen(
      data: (userData) => userData?['name'] as String? ?? currentUser?.displayName ?? 'User',
      orElse: () => currentUser?.displayName ?? 'User',
    );

    final email = currentUser?.email ?? 'No email';
    final roleDisplayName = role.displayName;

    String getInitials(String name) {
      if (name.isEmpty) return 'U';
      final parts = name.trim().split(RegExp(r'\s+'));
      if (parts.length > 1) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return parts[0][0].toUpperCase();
    }

    final initials = getInitials(userName);

    return Theme(
      data: Theme.of(context).copyWith(
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: PopupMenuButton<String>(
        offset: const Offset(0, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
          ),
        ),
        color: isDark ? const Color(0xFF1B2142) : Colors.white,
        onSelected: (value) async {
          switch (value) {
            case 'profile':
              Navigator.of(context).pushNamed(AppRoutes.profileSetup);
              break;
            case 'appearance':
              _showAppearanceDialog(context, ref);
              break;
            case 'logout':
              final authService = ref.read(authServiceProvider);
              await authService.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
              break;
          }
        },
        itemBuilder: (context) => [
          // Header section displaying user profile information (disabled)
          PopupMenuItem<String>(
            enabled: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: isDark
                            ? const Color(0xFF7B4DFF).withOpacity(0.2)
                            : const Color(0xFF7B4DFF).withOpacity(0.1),
                        child: Text(
                          initials,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF5F2EEA),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              roleDisplayName,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFFB4B8D0) : Colors.black54,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? const Color(0xFFB4B8D0).withOpacity(0.6) : Colors.black38,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem(
            value: 'profile',
            child: Row(
              children: [
                Icon(Icons.person_outline_rounded, size: 18, color: isDark ? Colors.white70 : Colors.black87),
                const SizedBox(width: 8),
                Text('My Profile', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'appearance',
            child: Row(
              children: [
                Icon(Icons.palette_outlined, size: 18, color: isDark ? Colors.white70 : Colors.black87),
                const SizedBox(width: 8),
                Text('Appearance', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
              ],
            ),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'logout',
            child: Row(
              children: [
                Icon(Icons.logout_outlined, size: 18, color: Colors.redAccent),
                const SizedBox(width: 8),
                Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
        child: ProfileAvatarControl(
          initials: initials,
          isDark: isDark,
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
}

class ProfileAvatarControl extends StatefulWidget {
  final String initials;
  final bool isDark;

  const ProfileAvatarControl({
    key,
    required this.initials,
    required this.isDark,
  }) : super(key: key);

  @override
  State<ProfileAvatarControl> createState() => _ProfileAvatarControlState();
}

class _ProfileAvatarControlState extends State<ProfileAvatarControl> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: widget.isDark
              ? (_isHovered ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.04))
              : (_isHovered ? Colors.black.withOpacity(0.06) : Colors.black.withOpacity(0.03)),
          border: Border.all(
            color: widget.isDark
                ? (_isHovered ? const Color(0xFF7B4DFF) : Colors.white.withOpacity(0.12))
                : (_isHovered ? const Color(0xFF7B4DFF) : Colors.black.withOpacity(0.12)),
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.initials,
              style: TextStyle(
                fontFamily: 'NotoSans',
                color: widget.isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.fade,
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.expand_more_rounded,
              color: widget.isDark ? const Color(0xFFB4B8D0) : Colors.black54,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
