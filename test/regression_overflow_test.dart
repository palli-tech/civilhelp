import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

import 'package:civilhelp/core/providers/company_provider.dart';
import 'package:civilhelp/core/providers/tenant_provider.dart';
import 'package:civilhelp/core/providers/user_role_provider.dart';
import 'package:civilhelp/core/enums/user_role.dart';
import 'package:civilhelp/features/auth/providers/auth_provider.dart';
import 'package:civilhelp/features/auth/services/auth_service.dart';
import 'package:civilhelp/features/dashboard/screens/owner_dashboard.dart';
import 'package:civilhelp/features/sites/screens/sites_screen.dart';
import 'package:civilhelp/features/sites/providers/site_provider.dart';
import 'package:civilhelp/features/labour/presentation/screens/labour_list_screen.dart';
import 'package:civilhelp/features/labour/presentation/providers/labour_provider.dart';
import 'package:civilhelp/features/attendance/screens/attendance_screen.dart';
import 'package:civilhelp/features/attendance/providers/attendance_provider.dart';
import 'package:civilhelp/features/payroll/screens/payroll_dashboard_screen.dart';
import 'package:civilhelp/features/payroll/providers/payroll_providers.dart';
import 'package:civilhelp/features/advances/screens/advances_screen.dart';
import 'package:civilhelp/features/advances/providers/advances_providers.dart';
import 'package:civilhelp/features/reports/screens/reports_dashboard_screen.dart';
import 'package:civilhelp/features/settings/screens/settings_screen.dart';

class MockAuthService implements AuthService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockAuthService mockAuth;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockAuthService();
  });

  // Helper function to build the ProviderScope and Pump the Screen
  Widget makeTestableWidget(Widget screen) {
    return ProviderScope(
      overrides: [
        userCompanyIdProvider.overrideWith((ref) => 'mock_comp_123'),
        userRoleProvider.overrideWith((ref) => UserRole.owner),
        currentUserProvider.overrideWith((ref) => null),
        authServiceProvider.overrideWith((ref) => mockAuth),
        userDataProvider.overrideWith((ref) => Stream.value({
          'name': 'Dileep',
          'email': 'dileep@test.com',
          'companyId': 'mock_comp_123',
          'role': 'owner',
        })),
        tenantContextProvider.overrideWith((ref) => null),
        tenantCompanyStreamProvider.overrideWith((ref) => Stream.value(null)),
        firestoreProvider.overrideWith((ref) => fakeFirestore),
        
        // Mock stream providers for empty states / standard renders
        sitesStreamProvider.overrideWith((ref) => Stream.value([])),
        labourStreamProvider.overrideWith((ref) => Stream.value([])),
        roleAwareAttendanceStreamProvider.overrideWith((ref) => Stream.value([])),
        attendanceTodayStreamProvider.overrideWith((ref) => Stream.value([])),
        advancesListStreamProvider.overrideWith((ref) => Stream.value([])),
        payrollPeriodsStreamProvider.overrideWith((ref) => Stream.value([])),
      ],
      child: MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        home: screen,
      ),
    );
  }

  // Target viewports
  final Map<String, Size> viewports = {
    'Mobile': const Size(360, 800),
    'Tablet': const Size(768, 1024),
    'Desktop': const Size(1280, 800),
  };

  // Target Text Scale Factors
  final List<double> textScales = [1.0, 1.3, 1.5];

  // Map of Screen Names to widgets
  final Map<String, Widget> screens = {
    'Dashboard': const OwnerDashboard(),
    'Sites': const SitesScreen(),
    'Labour': const LabourListScreen(),
    'Attendance': const AttendanceScreen(),
    'Payroll': const PayrollDashboardScreen(),
    'Advances': const AdvancesScreen(),
    'Reports': const ReportsDashboardScreen(),
    'Settings': const SettingsScreen(),
  };

  group('Operational Screens Overflow & Layout Regression Tests', () {
    for (final screenName in screens.keys) {
      for (final viewportName in viewports.keys) {
        for (final textScale in textScales) {
          testWidgets(
            'Render $screenName on $viewportName viewport with TextScale=$textScale',
            (WidgetTester tester) async {
              final size = viewports[viewportName]!;
              
              // Set viewport constraints
              tester.view.physicalSize = Size(size.width, size.height);
              tester.view.devicePixelRatio = 1.0;
              tester.platformDispatcher.textScaleFactorTestValue = textScale;

              addTearDown(() {
                tester.view.resetPhysicalSize();
                tester.view.resetDevicePixelRatio();
                tester.platformDispatcher.clearTextScaleFactorTestValue();
              });

              // Pump the screen
              final widget = makeTestableWidget(screens[screenName]!);
              await tester.pumpWidget(widget);
              await tester.pumpAndSettle();

              // Verify that the screen is rendered
              expect(find.byWidgetPredicate((widget) => widget is MaterialApp), findsOneWidget);
            },
          );
        }
      }
    }
  });
}
