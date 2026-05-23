import 'package:flutter/material.dart';

import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/sites/screens/sites_screen.dart';
import '../features/sites/screens/add_site_screen.dart';
import '../features/sites/screens/edit_site_screen.dart';
import '../features/sites/screens/site_details_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
        );
      case '/login':
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        );
      case '/dashboard':
        return MaterialPageRoute(
          builder: (_) => const DashboardScreen(),
        );
      case '/sites':
        return MaterialPageRoute(
          builder: (_) => const SitesScreen(),
        );
      case '/add-site':
        return MaterialPageRoute(
          builder: (_) => const AddSiteScreen(),
        );
      case '/edit-site':
        final siteId = settings.arguments as String?;
        if (siteId == null) {
          return MaterialPageRoute(
            builder: (_) => Scaffold(
              body: Center(child: Text('Missing site id')),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => EditSiteScreen(siteId: siteId),
        );
      case '/site-details':
        final siteId = settings.arguments as String?;
        if (siteId == null) {
          return MaterialPageRoute(
            builder: (_) => Scaffold(
              body: Center(child: Text('Missing site id')),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => SiteDetailsScreen(siteId: siteId),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
