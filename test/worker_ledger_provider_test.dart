import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:civilhelp/core/providers/company_provider.dart';
import 'package:civilhelp/features/sites/providers/site_provider.dart';
import 'package:civilhelp/features/labour/presentation/providers/labour_provider.dart';
import 'package:civilhelp/features/reports/screens/worker_ledger_screen.dart';
import 'package:civilhelp/features/auth/providers/auth_provider.dart';
import 'package:civilhelp/features/auth/services/auth_service.dart';
import 'package:civilhelp/core/providers/tenant_provider.dart';
import 'package:civilhelp/core/providers/user_role_provider.dart';
import 'package:civilhelp/core/enums/user_role.dart';

class MockAuthService implements AuthService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Create a dummy widget test to trigger the providers
void main() {
  testWidgets('Load WorkerLedgerScreen to check provider logs', (WidgetTester tester) async {
    // We just want to see the debug prints
    debugPrint('=== TEST STARTED ===');
    try {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userCompanyIdProvider.overrideWith((ref) => 'mock_company_id'),
            sitesStreamProvider.overrideWith((ref) => Stream.value([])),
            labourStreamProvider.overrideWith((ref) => Stream.value([])),
            currentUserProvider.overrideWith((ref) => null),
            authServiceProvider.overrideWith((ref) => MockAuthService()),
            userDataProvider.overrideWith((ref) => Stream.value(null)),
            userRoleProvider.overrideWith((ref) => UserRole.owner),
            tenantContextProvider.overrideWith((ref) => null),
            tenantCompanyStreamProvider.overrideWith((ref) => Stream.value(null)),
          ],
          child: const MaterialApp(
            home: WorkerLedgerScreen(),
          ),
        ),
      );
      // Give it a moment to resolve streams/futures if possible
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 500));
    } catch (e, st) {
      debugPrint('Exception in test: $e');
      debugPrint(st.toString());
    }
    debugPrint('=== TEST ENDED ===');
  });
}
