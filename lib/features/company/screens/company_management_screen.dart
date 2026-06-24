import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'package:civilhelp/app/theme.dart';
import 'package:civilhelp/app/router.dart';
import 'package:civilhelp/shared/widgets/module_header.dart';
import 'package:civilhelp/shared/widgets/status_chip.dart';
import 'package:civilhelp/data/models/company.dart';
import 'package:civilhelp/core/enums/account_status.dart';
import '../../auth/providers/auth_provider.dart';

class CompanyManagementScreen extends ConsumerWidget {
  const CompanyManagementScreen({super.key});

  Future<void> _handleApprove(BuildContext context, WidgetRef ref, String requestId, String ownerUid) async {
    final admin = ref.read(currentUserProvider);
    if (admin == null) return;

    try {
      final batch = FirebaseFirestore.instance.batch();

      // 1. Update company request
      final requestRef = FirebaseFirestore.instance.collection('company_requests').doc(requestId);
      batch.update(requestRef, {
        'status': 'approved',
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': admin.uid,
      });

      // 2. Update user status
      final userRef = FirebaseFirestore.instance.collection('users').doc(ownerUid);
      batch.update(userRef, {
        'accountStatus': AccountStatus.approved.name,
      });

      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Company request approved!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to approve request: ${e.toString()}'),
            backgroundColor: context.colors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleReject(BuildContext context, WidgetRef ref, String requestId, String ownerUid) async {
    final admin = ref.read(currentUserProvider);
    if (admin == null) return;

    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reject Company Request'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason *',
                hintText: 'Enter reason for rejection...',
              ),
              maxLines: 3,
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Reason is required' : null,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Reject', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        final batch = FirebaseFirestore.instance.batch();

        // 1. Update company request
        final requestRef = FirebaseFirestore.instance.collection('company_requests').doc(requestId);
        batch.update(requestRef, {
          'status': 'rejected',
          'rejectionReason': reasonController.text.trim(),
          'reviewedAt': FieldValue.serverTimestamp(),
          'reviewedBy': admin.uid,
        });

        // 2. Update user status
        final userRef = FirebaseFirestore.instance.collection('users').doc(ownerUid);
        batch.update(userRef, {
          'accountStatus': AccountStatus.rejected.name,
        });

        await batch.commit();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Company request rejected.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to reject: ${e.toString()}'),
              backgroundColor: context.colors.error,
            ),
          );
        }
      }
    }
  }

  void _showRequestDetails(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final submittedAt = (data['submittedAt'] as Timestamp?)?.toDate();
    final dateStr = submittedAt != null ? DateFormat('dd MMM yyyy, hh:mm a').format(submittedAt) : '-';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            data['companyName'] ?? 'Request Details',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailRow('Owner Name', data['ownerName']),
                _detailRow('Owner Email', data['ownerEmail']),
                _detailRow('Mobile Number', data['mobileNumber']),
                _detailRow('Business Type', data['businessType']),
                _detailRow('Estimated Labour', data['estimatedLabourCount']),
                _detailRow('Estimated Supervisors', data['estimatedSupervisorCount']),
                _detailRow('Address', '${data['address'] ?? ""}, ${data['city'] ?? ""}, ${data['state'] ?? ""} - ${data['pinCode'] ?? ""}'),
                _detailRow('GST Number', data['gstNumber']),
                _detailRow('Website', data['website']),
                _detailRow('Notes', data['notes']),
                _detailRow('Submitted Date', dateStr),
                _detailRow('Status', data['status']?.toString().toUpperCase()),
                if (data['status'] == 'rejected')
                  _detailRow('Rejection Reason', data['rejectionReason']),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(String label, dynamic value) {
    final valStr = value?.toString().trim() ?? '';
    if (valStr.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(valStr, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDarkMode;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                context.colors.primaryContainer.withValues(alpha: 0.15),
                context.colors.surface,
              ],
            ),
          ),
          child: Column(
            children: [
              ModuleHeader(
                title: 'Company Management',
                subtitle: 'Platform requests & company registration',
                showBackButton: true,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.add_business_rounded),
                    tooltip: 'Create Company',
                    onPressed: () {
                      Navigator.of(context).pushNamed(AppRoutes.companySetup);
                    },
                  ),
                ],
              ),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('company_requests')
                    .where('status', isEqualTo: 'pending')
                    .snapshots(),
                builder: (context, pendingSnap) {
                  final pendingCount = pendingSnap.data?.docs.length ?? 0;
                  return TabBar(
                    labelColor: context.colors.primary,
                    unselectedLabelColor: context.colors.outline,
                    indicatorColor: context.colors.primary,
                    tabs: [
                      const Tab(text: 'Companies'),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Requests'),
                            if (pendingCount > 0) ...[
                              const SizedBox(width: 8),
                              Badge.count(count: pendingCount),
                            ],
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildCompaniesTab(context, isDark),
                    _buildRequestsTab(context, ref, isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompaniesTab(BuildContext context, bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('companies')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading companies: ${snapshot.error}'));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.business_center_outlined, size: 64, color: context.colors.outline),
                const SizedBox(height: 16),
                Text('No companies registered yet', style: context.text.titleLarge?.copyWith(color: context.colors.outline)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final company = Company.fromFirestore(docs[index]);
            return Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            company.name,
                            style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        StatusChip(status: company.isActive ? 'active' : 'inactive'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),
                    if (company.legalName.isNotEmpty) ...[
                      _iconLabelRow(context, Icons.gavel_outlined, 'Legal Name: ${company.legalName}'),
                      const SizedBox(height: 4),
                    ],
                    if (company.email.isNotEmpty) ...[
                      _iconLabelRow(context, Icons.email_outlined, company.email),
                      const SizedBox(height: 4),
                    ],
                    if (company.phone.isNotEmpty) ...[
                      _iconLabelRow(context, Icons.phone_outlined, company.phone),
                      const SizedBox(height: 4),
                    ],
                    if (company.address.isNotEmpty) ...[
                      _iconLabelRow(context, Icons.location_on_outlined, company.address),
                      const SizedBox(height: 4),
                    ],
                    _iconLabelRow(context, Icons.person_outline, 'Owner UID: ${company.ownerUid}'),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRequestsTab(BuildContext context, WidgetRef ref, bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('company_requests')
          .orderBy('submittedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading requests: ${snapshot.error}'));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pending_actions_rounded, size: 64, color: context.colors.outline),
                const SizedBox(height: 16),
                Text('No company requests found', style: context.text.titleLarge?.copyWith(color: context.colors.outline)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>? ?? {};
            final status = data['status'] as String? ?? 'pending';
            final ownerUid = data['ownerUid'] as String? ?? '';
            final submittedAt = (data['submittedAt'] as Timestamp?)?.toDate();
            final dateStr = submittedAt != null ? DateFormat('dd MMM yyyy').format(submittedAt) : '-';

            return Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            data['companyName'] ?? 'New Company Request',
                            style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        StatusChip(status: status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),
                    _iconLabelRow(context, Icons.person_outline, 'Owner: ${data['ownerName'] ?? "-"}'),
                    const SizedBox(height: 4),
                    _iconLabelRow(context, Icons.email_outlined, data['ownerEmail'] ?? "-"),
                    const SizedBox(height: 4),
                    _iconLabelRow(context, Icons.phone_outlined, data['mobileNumber'] ?? "-"),
                    const SizedBox(height: 4),
                    _iconLabelRow(context, Icons.category_outlined, 'Business: ${data['businessType'] ?? "-"}'),
                    const SizedBox(height: 4),
                    _iconLabelRow(context, Icons.people_outline, 'Est. Labour: ${data['estimatedLabourCount'] ?? "-"}'),
                    const SizedBox(height: 4),
                    _iconLabelRow(context, Icons.calendar_today_outlined, 'Submitted: $dateStr'),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => _showRequestDetails(context, doc),
                          icon: const Icon(Icons.info_outline),
                          label: const Text('View'),
                        ),
                        const SizedBox(width: 8),
                        if (status == 'pending') ...[
                          OutlinedButton.icon(
                            onPressed: () => _handleReject(context, ref, doc.id, ownerUid),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(color: Colors.redAccent),
                            ),
                            icon: const Icon(Icons.close),
                            label: const Text('Reject'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => _handleApprove(context, ref, doc.id, ownerUid),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.check),
                            label: const Text('Approve'),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _iconLabelRow(BuildContext context, IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: context.colors.outline),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: context.text.bodyMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
