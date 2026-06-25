import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'package:civilhelp/app/theme.dart';
import '../providers/auth_provider.dart';
import '../../../core/enums/user_type.dart';
import '../../../core/enums/account_status.dart';
import '../../../app/router.dart';

class CompanyAccessRequiredScreen extends ConsumerWidget {
  const CompanyAccessRequiredScreen({super.key});

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final authService = ref.read(authServiceProvider);
    await authService.signOut();
    if (context.mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final userDataAsync = ref.watch(userDataProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              context.colors.primaryContainer.withValues(alpha: 0.35),
              context.colors.secondaryContainer.withValues(alpha: 0.15),
              context.colors.surface,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                elevation: 10,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding,
                    vertical: AppSpacing.sectionGap,
                  ),
                  child: userDataAsync.when(
                    data: (userData) {
                      if (userData == null) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final userTypeStr = userData['userType'] as String?;
                      final userType = UserType.fromString(userTypeStr);
                      final accountStatusStr = userData['accountStatus'] as String?;
                      final accountStatus = AccountStatus.fromString(accountStatusStr);

                      debugPrint('CompanyAccessRequiredScreen Build: userTypeStr=$userTypeStr, userType=$userType, accountStatusStr=$accountStatusStr, accountStatus=$accountStatus');

                      if (userType == UserType.employee) {
                        return _buildEmployeeContent(context, ref);
                      } else {
                        return _buildOwnerContent(context, ref, user, accountStatus);
                      }
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Center(
                      child: Text('Error: ${error.toString()}'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeContent(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: context.colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.mark_email_unread_outlined,
                size: 32,
                color: context.colors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'Waiting For Company Invitation',
                style: context.text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.colors.onSurface,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Your account is set up as an Employee / Supervisor.',
          style: context.text.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: context.colors.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Please contact your company administrator and request an invitation.',
          style: context.text.bodyMedium?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Once they add you to the company, you will be invited via email and can sign in to access CivilHelp.',
          style: context.text.bodyMedium?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () => _handleLogout(context, ref),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              side: BorderSide(
                color: context.colors.outline,
              ),
            ),
            icon: const Icon(Icons.logout),
            label: const Text(
              'Logout',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        _buildDevAdminButton(ref),
      ],
    );
  }

  Widget _buildOwnerContent(
      BuildContext context, WidgetRef ref, User? user, AccountStatus accountStatus) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('company_requests')
          .where('ownerUid', isEqualTo: user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                'Error loading requests: ${snapshot.error}',
                style: TextStyle(color: context.colors.error, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          // No request exists yet
          return _buildRequestAccessFormCTA(context, ref);
        }

        // Sort in-memory descending by submittedAt to get the latest request
        final sortedDocs = List<QueryDocumentSnapshot>.from(docs);
        sortedDocs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>? ?? {};
          final bData = b.data() as Map<String, dynamic>? ?? {};
          final aTime = aData['submittedAt'] as Timestamp?;
          final bTime = bData['submittedAt'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime); // descending
        });

        final requestDoc = sortedDocs.first;
        final requestStatus = requestDoc['status'] as String? ?? 'pending';
        final requestId = requestDoc.id;
        final submittedAt = (requestDoc['submittedAt'] as Timestamp?)?.toDate();
        final rejectionReason = requestDoc['rejectionReason'] as String? ?? '';

        if (requestStatus == 'pending') {
          return _buildPendingContent(context, ref, requestId, submittedAt);
        } else if (requestStatus == 'rejected') {
          return _buildRejectedContent(context, ref, rejectionReason);
        } else if (requestStatus == 'approved') {
          return _buildApprovedContent(context, ref);
        } else {
          // completed or active
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Widget _buildRequestAccessFormCTA(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: context.colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.business_center_outlined,
                size: 32,
                color: context.colors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'Request Company Access',
                style: context.text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.colors.onSurface,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'To start managing your workforce, you must first request approval to create a company profile.',
          style: context.text.bodyLarge?.copyWith(
            color: context.colors.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Our platform administrators will review your application details before granting company creation permission.',
          style: context.text.bodyMedium?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.companyRequest);
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: context.colors.primary,
              foregroundColor: context.colors.onPrimary,
            ),
            icon: const Icon(Icons.add_task_rounded),
            label: const Text(
              'Submit Company Request',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () => _handleLogout(context, ref),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              side: BorderSide(
                color: context.colors.outline,
              ),
            ),
            icon: const Icon(Icons.logout),
            label: const Text(
              'Logout',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        _buildDevAdminButton(ref),
      ],
    );
  }

  Widget _buildPendingContent(
      BuildContext context, WidgetRef ref, String requestId, DateTime? submittedAt) {
    final dateStr = submittedAt != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(submittedAt)
        : 'Processing...';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.pending_actions_rounded,
                size: 32,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'Company Request Submitted',
                style: context.text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.colors.onSurface,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.orange.withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pending Approval',
                style: context.text.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Submitted Date: $dateStr',
                style: context.text.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Request ID: $requestId',
                style: context.text.bodySmall?.copyWith(
                  color: context.colors.outline,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Our administrators are currently reviewing your company pre-approval application.',
          style: context.text.bodyMedium?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () => _handleLogout(context, ref),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              side: BorderSide(
                color: context.colors.outline,
              ),
            ),
            icon: const Icon(Icons.logout),
            label: const Text(
              'Logout',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        _buildDevAdminButton(ref),
      ],
    );
  }

  Widget _buildRejectedContent(BuildContext context, WidgetRef ref, String reason) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: context.colors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.gpp_bad_outlined,
                size: 32,
                color: context.colors.error,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'Request Rejected',
                style: context.text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.colors.onSurface,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: context.colors.error.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: context.colors.error.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rejection Reason',
                style: context.text.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.colors.error,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                reason.isNotEmpty ? reason : 'No specific reason provided. Please contact support.',
                style: context.text.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'You may adjust your details and resubmit another company access request for approval.',
          style: context.text.bodyMedium?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.companyRequest);
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: context.colors.primary,
              foregroundColor: context.colors.onPrimary,
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text(
              'Submit New Request',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () => _handleLogout(context, ref),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              side: BorderSide(
                color: context.colors.outline,
              ),
            ),
            icon: const Icon(Icons.logout),
            label: const Text(
              'Logout',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        _buildDevAdminButton(ref),
      ],
    );
  }

  Widget _buildApprovedContent(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                size: 32,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'Company Request Approved',
                style: context.text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.colors.onSurface,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Your company pre-approval request has been approved by the platform administrators!',
          style: context.text.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: context.colors.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'You may now complete the setup form to initialize your construction company profile and start using CivilHelp.',
          style: context.text.bodyMedium?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.companySetup);
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.domain_add_rounded),
            label: const Text(
              'Create Company',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () => _handleLogout(context, ref),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              side: BorderSide(
                color: context.colors.outline,
              ),
            ),
            icon: const Icon(Icons.logout),
            label: const Text(
              'Logout',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        _buildDevAdminButton(ref),
      ],
    );
  }

  Widget _buildDevAdminButton(WidgetRef ref) {
    if (!kDebugMode) return const SizedBox.shrink();
    return Column(
      children: [
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: TextButton.icon(
            onPressed: () async {
              final currentUser = ref.read(currentUserProvider);
              if (currentUser != null) {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUser.uid)
                    .update({'role': 'admin'});
                ref.invalidate(userDataProvider);
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Colors.orange),
              ),
            ),
            icon: const Icon(Icons.security),
            label: const Text(
              '[DEV] Promote to Super Admin',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
