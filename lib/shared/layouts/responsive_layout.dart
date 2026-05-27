import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class ResponsiveLayout extends ConsumerWidget {
  final Widget mobileBody;
  final Widget? tabletBody;
  final Widget? desktopBody;
  final PreferredSizeWidget? appBar;
  final Widget? drawer;
  final Widget? bottomNav;
  final FloatingActionButton? fab;

  const ResponsiveLayout({
    super.key,
    required this.mobileBody,
    this.tabletBody,
    this.desktopBody,
    this.appBar,
    this.drawer,
    this.bottomNav,
    this.fab,
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

    return Scaffold(
      appBar: appBar,
      drawer: isTablet ? null : drawer,
      body: isTablet
          ? Row(
              children: [
                if (drawer != null && isTablet)
                  SizedBox(
                    width: 280,
                    child: drawer,
                  ),
                Expanded(child: body),
              ],
            )
          : body,
      bottomNavigationBar: isTablet ? null : bottomNav,
      floatingActionButton: fab,
    );
  }
}
