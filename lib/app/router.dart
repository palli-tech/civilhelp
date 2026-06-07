import 'package:flutter/material.dart';

import 'package:civilhelp/features/auth/screens/login_screen.dart';
import 'package:civilhelp/features/auth/screens/splash_screen.dart';
import 'package:civilhelp/features/dashboard/screens/dashboard_screen.dart';
import 'package:civilhelp/features/labour/presentation/screens/add_edit_labour_screen.dart';
import 'package:civilhelp/features/labour/presentation/screens/labour_details_screen.dart';
import 'package:civilhelp/features/labour/presentation/screens/labour_list_screen.dart';
import 'package:civilhelp/features/sites/screens/add_site_screen.dart';
import 'package:civilhelp/features/sites/screens/edit_site_screen.dart';
import 'package:civilhelp/features/sites/screens/site_details_screen.dart';
import 'package:civilhelp/features/sites/screens/sites_screen.dart';
import 'package:civilhelp/features/attendance/screens/attendance_screen.dart';
import 'package:civilhelp/features/payments/screens/payments_screen.dart';
import 'package:civilhelp/features/advances/screens/advances_screen.dart';
import 'package:civilhelp/features/reports/screens/reports_dashboard_screen.dart';
import 'package:civilhelp/features/reports/screens/worker_ledger_screen.dart';

class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const dashboard = '/dashboard';
  static const sites = '/sites';
  static const addSite = '/add-site';
  static const siteDetails = '/site-details';
  static const editSite = '/edit-site';
  static const labour = '/labour';
  static const addLabour = '/add-labour';
  static const labourDetails = '/labour-details';
  static const editLabour = '/edit-labour';
  static const attendance = '/attendance';
  static const payments = '/payments';
  static const advances = '/advances';
  static const reports = '/reports';
  static const workerLedger = '/worker-ledger';
}

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );
      case AppRoutes.login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );
      case AppRoutes.dashboard:
        return MaterialPageRoute(
          builder: (_) => const DashboardScreen(),
          settings: settings,
        );
      case AppRoutes.sites:
        return MaterialPageRoute(
          builder: (_) => const SitesScreen(),
          settings: settings,
        );
      case AppRoutes.addSite:
        return MaterialPageRoute(
          builder: (_) => const AddSiteScreen(),
          settings: settings,
        );
      case AppRoutes.siteDetails:
        if (args is String) {
          return MaterialPageRoute(
            builder: (_) => SiteDetailsScreen(siteId: args),
            settings: settings,
          );
        }
        return _errorRoute('Site ID is missing.');
      case AppRoutes.editSite:
        if (args is String) {
          return MaterialPageRoute(
            builder: (_) => EditSiteScreen(siteId: args),
            settings: settings,
          );
        }
        return _errorRoute('Site ID is missing.');
      case AppRoutes.labour:
        return MaterialPageRoute(
          builder: (_) => const LabourListScreen(),
          settings: settings,
        );
      case AppRoutes.addLabour:
        return MaterialPageRoute(
          builder: (_) => const AddEditLabourScreen(),
          settings: settings,
        );
      case AppRoutes.labourDetails:
        if (args is String) {
          return MaterialPageRoute(
            builder: (_) => LabourDetailsScreen(labourId: args),
            settings: settings,
          );
        }
        return _errorRoute('Labour ID is missing.');
      case AppRoutes.editLabour:
        if (args is String) {
          return MaterialPageRoute(
            builder: (_) => AddEditLabourScreen(labourId: args),
            settings: settings,
          );
        }
        return _errorRoute('Labour ID is missing.');
      case AppRoutes.attendance:
        return MaterialPageRoute(
          builder: (_) => const AttendanceScreen(),
          settings: settings,
        );
      case AppRoutes.payments:
        return MaterialPageRoute(
          builder: (_) => const PaymentsScreen(),
          settings: settings,
        );
      case AppRoutes.advances:
        return MaterialPageRoute(
          builder: (_) => const AdvancesScreen(),
          settings: settings,
        );
      case AppRoutes.reports:
        return MaterialPageRoute(
          builder: (_) => const ReportsDashboardScreen(),
          settings: settings,
        );
      case AppRoutes.workerLedger:
        return MaterialPageRoute(
          builder: (_) => const WorkerLedgerScreen(),
          settings: settings,
        );
      default:
        return _errorRoute('Route not found: ${settings.name}');
    }
  }

  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Navigation error')),
        body: Center(child: Text(message)),
      ),
    );
  }
}


