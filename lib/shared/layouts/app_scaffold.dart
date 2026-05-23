import 'package:flutter/material.dart';

import 'app_drawer.dart';
import 'bottom_nav.dart';
import 'responsive_layout.dart';

class AppScaffold extends StatelessWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;
  final FloatingActionButton? fab;

  const AppScaffold({
    super.key,
    required this.child,
    this.appBar,
    this.fab,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      appBar: appBar,
      mobileBody: child,
      tabletBody: child,
      desktopBody: child,
      drawer: const AppDrawer(),
      bottomNav: const BottomNav(),
      fab: fab,
    );
  }
}
