import 'package:flutter/material.dart';
import 'package:civilhelp/app/router.dart';
import 'package:civilhelp/shared/layouts/app_scaffold.dart';

class ReportsDashboardScreen extends StatelessWidget {
  const ReportsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        elevation: 0,
      ),
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.receipt_long, color: Colors.blue),
              title: const Text('Worker Ledger'),
              subtitle: const Text('View detailed chronological ledger of attendance, advances, and payments for a specific worker.'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.workerLedger);
              },
            ),
          ),
          // Future phase reports will go here
        ],
      ),
    );
  }
}
