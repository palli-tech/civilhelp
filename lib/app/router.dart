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
import 'package:civilhelp/features/reports/screens/attendance_summary_screen.dart';
import 'package:civilhelp/features/reports/screens/advance_report_screen.dart';
import 'package:civilhelp/features/reports/screens/payment_report_screen.dart';
import 'package:civilhelp/features/reports/screens/monthly_payroll_screen.dart';
import 'package:civilhelp/features/reports/screens/outstanding_balance_screen.dart';
import 'package:civilhelp/features/reports/screens/site_performance_screen.dart';
import 'package:civilhelp/features/settings/screens/settings_screen.dart';
import 'package:civilhelp/features/settings/screens/company_profile_screen.dart';
import 'package:civilhelp/features/settings/screens/about_screen.dart';
import 'package:civilhelp/features/company/screens/company_setup_screen.dart';
import 'package:civilhelp/shared/layouts/tenant_guard.dart';

class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const companySetup = '/company-setup';
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
  static const attendanceSummary = '/attendance-summary';
  static const advanceReport = '/advance-report';
  static const paymentReport = '/payment-report';
  static const monthlyPayroll = '/monthly-payroll';
  static const outstandingBalance = '/outstanding-balance';
  static const sitePerformance = '/site-performance';
  static const settings = '/settings';
  static const companyProfile = '/settings/company-profile';
  static const about = '/settings/about';
}

class AppRouter {
  static Route<dynamic> _guardedRoute(Widget screen, RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => TenantGuard(child: screen),
      settings: settings,
    );
  }

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
      case AppRoutes.companySetup:
        return MaterialPageRoute(
          builder: (_) => const CompanySetupGuard(child: CompanySetupScreen()),
          settings: settings,
        );
      case AppRoutes.dashboard:
        return _guardedRoute(const DashboardScreen(), settings);
      case AppRoutes.sites:
        return _guardedRoute(const SitesScreen(), settings);
      case AppRoutes.addSite:
        return _guardedRoute(const AddSiteScreen(), settings);
      case AppRoutes.siteDetails:
        if (args is String) {
          return _guardedRoute(SiteDetailsScreen(siteId: args), settings);
        }
        return _errorRoute('Site ID is missing.');
      case AppRoutes.editSite:
        if (args is String) {
          return _guardedRoute(EditSiteScreen(siteId: args), settings);
        }
        return _errorRoute('Site ID is missing.');
      case AppRoutes.labour:
        return _guardedRoute(const LabourListScreen(), settings);
      case AppRoutes.addLabour:
        return _guardedRoute(const AddEditLabourScreen(), settings);
      case AppRoutes.labourDetails:
        if (args is String) {
          return _guardedRoute(LabourDetailsScreen(labourId: args), settings);
        }
        return _errorRoute('Labour ID is missing.');
      case AppRoutes.editLabour:
        if (args is String) {
          return _guardedRoute(AddEditLabourScreen(labourId: args), settings);
        }
        return _errorRoute('Labour ID is missing.');
      case AppRoutes.attendance:
        return _guardedRoute(const AttendanceScreen(), settings);
      case AppRoutes.payments:
        return _guardedRoute(const PaymentsScreen(), settings);
      case AppRoutes.advances:
        return _guardedRoute(const AdvancesScreen(), settings);
      case AppRoutes.reports:
        return _guardedRoute(const ReportsDashboardScreen(), settings);
      case AppRoutes.workerLedger:
        return _guardedRoute(const WorkerLedgerScreen(), settings);
      case AppRoutes.attendanceSummary:
        return _guardedRoute(const AttendanceSummaryScreen(), settings);
      case AppRoutes.advanceReport:
        return _guardedRoute(const AdvanceReportScreen(), settings);
      case AppRoutes.paymentReport:
        return _guardedRoute(const PaymentReportScreen(), settings);
      case AppRoutes.monthlyPayroll:
        return _guardedRoute(const MonthlyPayrollScreen(), settings);
      case AppRoutes.sitePerformance:
        return _guardedRoute(const SitePerformanceScreen(), settings);
      case AppRoutes.outstandingBalance:
        return _guardedRoute(const OutstandingBalanceScreen(), settings);
      case AppRoutes.settings:
        return _guardedRoute(const SettingsScreen(), settings);
      case AppRoutes.companyProfile:
        return _guardedRoute(const CompanyProfileScreen(), settings);
      case AppRoutes.about:
        return _guardedRoute(const AboutScreen(), settings);
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


