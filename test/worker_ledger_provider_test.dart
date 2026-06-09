import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:civilhelp/features/reports/screens/worker_ledger_screen.dart';

// Create a dummy widget test to trigger the providers
void main() {
  testWidgets('Load WorkerLedgerScreen to check provider logs', (WidgetTester tester) async {
    // We just want to see the debug prints
    debugPrint('=== TEST STARTED ===');
    try {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
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
