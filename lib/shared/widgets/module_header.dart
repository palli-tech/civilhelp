import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:civilhelp/app/theme.dart';


class ModuleHeaderConstants {
  static const double minHeaderHeight = 80.0;
  static const double headerHorizontalPadding = 24.0;
  static const double headerVerticalPadding = 16.0;
  static const double headerGap = 16.0;
  static const double avatarSize = 42.0;
  static const double actionButtonSize = 36.0;
}

class ModuleHeader extends ConsumerWidget {
  final String title;
  final String? subtitle;
  final bool showBackButton;
  final String? breadcrumbs;
  final PreferredSizeWidget? bottom;
  final List<Widget>? actions;

  const ModuleHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showBackButton = true,
    this.breadcrumbs,
    this.bottom,
    this.actions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDarkMode;



    Widget buildBackButton() {
      return StatefulHoverBackButton(
        isDark: isDark,
        onTap: () {
          Navigator.maybePop(context);
        },
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: ModuleHeaderConstants.minHeaderHeight,
            ),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(
                horizontal: ModuleHeaderConstants.headerHorizontalPadding,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left: Back button + Title/Subtitle
                Expanded(
                  child: Row(
                    children: [
                      if (showBackButton) ...[
                        buildBackButton(),
                        const SizedBox(width: ModuleHeaderConstants.headerGap),
                      ] else if (isMobile) ...[
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
                            if (breadcrumbs != null && breadcrumbs!.isNotEmpty) ...[
                              Text(
                                breadcrumbs!,
                                style: TextStyle(
                                  fontFamily: 'NotoSans',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFFB4B8D0).withOpacity(0.6) : Colors.black38,
                                  letterSpacing: 0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                            ],
                            Text(
                              title,
                              style: TextStyle(
                                fontFamily: 'NotoSans',
                                fontSize: isMobile ? 18 : 22,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : Colors.black87,
                                height: 1.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (subtitle != null && subtitle!.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                subtitle!,
                                style: TextStyle(
                                  fontFamily: 'NotoSans',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? const Color(0xFFB4B8D0) : Colors.black54,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (actions != null && actions!.isNotEmpty) ...[
                  const SizedBox(width: 16),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: actions!,
                  ),
                ],
              ],
            ),
          ),
        ),
        if (bottom != null) bottom!,
      ],
    ),
  );
}
}

class StatefulHoverBackButton extends StatefulWidget {
  final bool isDark;
  final VoidCallback onTap;

  const StatefulHoverBackButton({
    super.key,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<StatefulHoverBackButton> createState() => _StatefulHoverBackButtonState();
}

class _StatefulHoverBackButtonState extends State<StatefulHoverBackButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: ModuleHeaderConstants.actionButtonSize,
          height: ModuleHeaderConstants.actionButtonSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.isDark
                ? (_isHovered ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.04))
                : (_isHovered ? Colors.black.withOpacity(0.08) : Colors.black.withOpacity(0.03)),
            border: Border.all(
              color: widget.isDark
                  ? (_isHovered ? const Color(0xFF7B4DFF) : Colors.white.withOpacity(0.08))
                  : (_isHovered ? const Color(0xFF7B4DFF) : Colors.black.withOpacity(0.08)),
              width: 1.5,
            ),
            boxShadow: [
              if (_isHovered)
                BoxShadow(
                  color: const Color(0xFF7B4DFF).withOpacity(widget.isDark ? 0.2 : 0.1),
                  blurRadius: 10,
                ),
            ],
          ),
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: InkWell(
                onTap: widget.onTap,
                child: const Center(
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 14,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
