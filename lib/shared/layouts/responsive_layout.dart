import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'premium_background.dart';
import 'package:civilhelp/core/theme/context_extensions.dart';

class ResponsiveLayout extends ConsumerWidget {
  final Widget mobileBody;
  final Widget? tabletBody;
  final Widget? desktopBody;
  final PreferredSizeWidget? appBar;
  final Widget? drawer;
  final Widget? bottomNav;
  final FloatingActionButton? fab;
  final bool usePremiumBackground;

  static const double drawerWidth = 280.0;
  static const EdgeInsets drawerPadding = EdgeInsets.only(
    left: 16.0,
    top: 16.0,
    bottom: 16.0,
    right: 8.0,
  );

  const ResponsiveLayout({
    super.key,
    required this.mobileBody,
    this.tabletBody,
    this.desktopBody,
    this.appBar,
    this.drawer,
    this.bottomNav,
    this.fab,
    this.usePremiumBackground = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Determine layout based on screen width
    bool isTablet = screenWidth >= 600;
    bool isDesktop = screenWidth >= 1200;

    Widget body = isDesktop
        ? (desktopBody ?? tabletBody ?? mobileBody)
        : isTablet
            ? (tabletBody ?? mobileBody)
            : mobileBody;

    final isDark = context.isDarkMode;

    Widget mainScaffold = Scaffold(
      backgroundColor: usePremiumBackground && isDark ? Colors.transparent : null,
      appBar: appBar,
      drawer: isTablet ? null : drawer,
      body: SafeArea(
        top: appBar == null,
        bottom: bottomNav == null,
        child: isTablet
            ? Row(
                children: [
                  if (drawer != null && isTablet)
                    Padding(
                      padding: drawerPadding,
                      child: SizedBox(
                        width: drawerWidth,
                        child: drawer,
                      ),
                    ),
                  Expanded(child: body),
                ],
              )
            : body,
      ),
      bottomNavigationBar: isTablet ? null : bottomNav,
      floatingActionButton: fab,
    );

    if (usePremiumBackground) {
      Widget content = PremiumBackground(child: mainScaffold);
      if (isDark) {
        content = Theme(
          data: Theme.of(context).copyWith(
            scaffoldBackgroundColor: const Color(0xFF090B1A),
            cardTheme: CardThemeData(
              color: const Color(0xFF12182F),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            colorScheme: Theme.of(context).colorScheme.copyWith(
              background: const Color(0xFF090B1A),
              surface: const Color(0xFF12182F),
              surfaceVariant: const Color(0xFF0E1327),
              primary: const Color(0xFF7B4DFF),
              onBackground: Colors.white,
              onSurface: Colors.white,
              outline: const Color(0xFFB4B8D0),
            ),
          ),
          child: content,
        );
      }
      return content;
    }

    return mainScaffold;
  }
}
