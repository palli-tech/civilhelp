import 'package:flutter/material.dart';

import 'package:civilhelp/core/auth/permissions.dart';
import 'package:civilhelp/features/auth/screens/login_screen.dart';
import 'package:civilhelp/features/auth/screens/splash_screen.dart';
import 'package:civilhelp/features/auth/screens/profile_setup_screen.dart';
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
import 'package:civilhelp/features/payroll/screens/payroll_dashboard_screen.dart';
import 'package:civilhelp/features/payroll/screens/payroll_processing_screen.dart';
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
import 'package:civilhelp/features/settings/screens/team_management_screen.dart';
import 'package:civilhelp/features/settings/screens/theme_showcase_screen.dart';
import 'package:civilhelp/features/company/screens/company_setup_screen.dart';
import 'package:civilhelp/shared/layouts/tenant_guard.dart';
import 'package:civilhelp/shared/guards/permission_guard.dart';

class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const companySetup = '/company-setup';
  static const profileSetup = '/profile-setup';
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
  static const payroll = '/payroll';
  static const payrollProcessing = '/payroll-processing';
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
  static const teamManagement = '/settings/team-management';
  static const themeShowcase = '/theme-showcase';
}

class AppRouter {
  /// Standard guarded route: TenantGuard only (all authenticated tenant members).
  static Route<dynamic> _guardedRoute(Widget screen, RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => TenantGuard(child: screen),
      settings: settings,
    );
  }

  /// Permission-guarded route: TenantGuard + PermissionGuard.
  ///
  /// Only users with the specified [permission] can access the screen.
  /// Others see the "Access Denied" screen.
  static Route<dynamic> _permissionGuardedRoute(
    Widget screen,
    RouteSettings settings,
    Permission permission,
  ) {
    return MaterialPageRoute(
      builder: (_) => TenantGuard(
        child: PermissionGuard(
          permission: permission,
          child: screen,
        ),
      ),
      settings: settings,
    );
  }



  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      // --- Public / Auth routes (no guard) ---
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
      case AppRoutes.profileSetup:
        return MaterialPageRoute(
          builder: (_) => const ProfileSetupScreen(),
          settings: settings,
        );

      // --- All tenant members ---
      case AppRoutes.dashboard:
        return _guardedRoute(const DashboardScreen(), settings);
      case AppRoutes.about:
        return _guardedRoute(const AboutScreen(), settings);

      // --- Attendance (Owner + Supervisor) ---
      case AppRoutes.attendance:
        return _permissionGuardedRoute(const AttendanceScreen(), settings, Permission.viewAttendance);

      // --- Sites ---
      case AppRoutes.sites:
        return _permissionGuardedRoute(const SitesScreen(), settings, Permission.viewSites);
      case AppRoutes.addSite:
        return _permissionGuardedRoute(const AddSiteScreen(), settings, Permission.manageSites);
      case AppRoutes.siteDetails:
        if (args is String) {
          return _permissionGuardedRoute(SiteDetailsScreen(siteId: args), settings, Permission.viewSites);
        }
        return _errorRoute('Site ID is missing.');
      case AppRoutes.editSite:
        if (args is String) {
          return _permissionGuardedRoute(EditSiteScreen(siteId: args), settings, Permission.manageSites);
        }
        return _errorRoute('Site ID is missing.');

      // --- Labour ---
      case AppRoutes.labour:
        return _permissionGuardedRoute(const LabourListScreen(), settings, Permission.viewLabour);
      case AppRoutes.addLabour:
        return _permissionGuardedRoute(const AddEditLabourScreen(), settings, Permission.manageLabour);
      case AppRoutes.labourDetails:
        if (args is String) {
          return _permissionGuardedRoute(LabourDetailsScreen(labourId: args), settings, Permission.viewLabour);
        }
        return _errorRoute('Labour ID is missing.');
      case AppRoutes.editLabour:
        if (args is String) {
          return _permissionGuardedRoute(AddEditLabourScreen(labourId: args), settings, Permission.manageLabour);
        }
        return _errorRoute('Labour ID is missing.');

      // --- Payments ---
      case AppRoutes.payments:
        return _permissionGuardedRoute(const PaymentsScreen(), settings, Permission.viewPayments);

      // --- Advances ---
      case AppRoutes.advances:
        return _permissionGuardedRoute(const AdvancesScreen(), settings, Permission.viewAdvances);

      // --- Payroll ---
      case AppRoutes.payroll:
        return _permissionGuardedRoute(const PayrollDashboardScreen(), settings, Permission.managePayments);
      case AppRoutes.payrollProcessing:
        if (args is String) {
          return _permissionGuardedRoute(PayrollProcessingScreen(periodId: args), settings, Permission.managePayments);
        }
        return _errorRoute('Payroll period ID is missing.');

      // --- Reports ---
      case AppRoutes.reports:
        return _permissionGuardedRoute(const ReportsDashboardScreen(), settings, Permission.viewReports);
      case AppRoutes.workerLedger:
        return _permissionGuardedRoute(const WorkerLedgerScreen(), settings, Permission.viewReports);
      case AppRoutes.attendanceSummary:
        return _permissionGuardedRoute(const AttendanceSummaryScreen(), settings, Permission.viewReports);
      case AppRoutes.advanceReport:
        return _permissionGuardedRoute(const AdvanceReportScreen(), settings, Permission.viewReports);
      case AppRoutes.paymentReport:
        return _permissionGuardedRoute(const PaymentReportScreen(), settings, Permission.viewReports);
      case AppRoutes.monthlyPayroll:
        return _permissionGuardedRoute(const MonthlyPayrollScreen(), settings, Permission.viewReports);
      case AppRoutes.sitePerformance:
        return _permissionGuardedRoute(const SitePerformanceScreen(), settings, Permission.viewReports);
      case AppRoutes.outstandingBalance:
        return _permissionGuardedRoute(const OutstandingBalanceScreen(), settings, Permission.viewReports);

      // --- Settings & Profile ---
      case AppRoutes.settings:
        return _permissionGuardedRoute(const SettingsScreen(), settings, Permission.viewSettings);
      case AppRoutes.companyProfile:
        return _permissionGuardedRoute(const CompanyProfileScreen(), settings, Permission.manageCompany);
      case AppRoutes.teamManagement:
        return _permissionGuardedRoute(const TeamManagementScreen(), settings, Permission.manageUsers);
      case AppRoutes.themeShowcase:
        return _guardedRoute(const ThemeShowcaseScreen(), settings);

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
