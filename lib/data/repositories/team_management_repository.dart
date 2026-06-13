import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import '../../core/enums/user_role.dart';
import '../../core/enums/invitation_status.dart';
import '../../core/utils/email_helper.dart';

/// Provider for TeamManagementRepository.
final teamManagementRepositoryProvider = Provider<TeamManagementRepository>((ref) {
  return TeamManagementRepository();
});

/// Stream provider for all team members in a company.
final teamMembersStreamProvider = StreamProvider.family<List<UserModel>, String>((ref, companyId) {
  final repository = ref.watch(teamManagementRepositoryProvider);
  return repository.getTeamMembers(companyId);
});

/// Stream provider for all supervisors in a company.
final supervisorsStreamProvider = StreamProvider.family<List<UserModel>, String>((ref, companyId) {
  final repository = ref.watch(teamManagementRepositoryProvider);
  return repository.getSupervisors(companyId);
});

/// Repository for team management operations.
///
/// This is the foundation for future "Settings → Team Management" features.
/// Provides:
/// - Supervisor invitation
/// - Site assignment
/// - User role updates
/// - User enable/disable
class TeamManagementRepository {
  final FirebaseFirestore _firestore;

  TeamManagementRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Invite a new supervisor to the company.
  ///
  /// Replace user document creation with invitation creation.
  Future<void> inviteSupervisor({
    required String tenantId,
    required String companyId,
    required String email,
    required UserRole role,
    required List<String> assignedSiteIds,
    required String invitedBy,
  }) async {
    final normalized = normalizeEmail(email);
    if (normalized.isEmpty || !normalized.contains('@')) {
      throw Exception('Invalid email address.');
    }

    // 1. Check active/disabled company users first (optimization)
    final userQuery = await _firestore
        .collection('users')
        .where('companyId', isEqualTo: companyId)
        .where('email', isEqualTo: normalized)
        .limit(1)
        .get();

    if (userQuery.docs.isNotEmpty) {
      throw Exception('A user with this email is already a member of this company.');
    }

    // 2. Only if no user exists, check invitations
    final inviteQuery = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('invitations')
        .where('email', isEqualTo: normalized)
        .get();

    for (final doc in inviteQuery.docs) {
      final statusStr = doc.data()['status'] as String? ?? '';
      if (statusStr == InvitationStatus.pending.name || statusStr == InvitationStatus.accepted.name) {
        throw Exception('An active or accepted invitation already exists for this email.');
      }
    }

    // 3. Create invitation document
    final now = DateTime.now();
    final expiresAt = now.add(const Duration(days: 14));
    
    final docRef = _firestore
        .collection('companies')
        .doc(companyId)
        .collection('invitations')
        .doc();

    final invitation = {
      'id': docRef.id,
      'tenantId': tenantId,
      'companyId': companyId,
      'email': normalized,
      'role': role.name,
      'assignedSiteIds': assignedSiteIds,
      'status': InvitationStatus.pending.name,
      'invitedBy': invitedBy,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'resendCount': 0,
    };

    await docRef.set(invitation);
  }

  /// Assign sites to a user (typically a supervisor).
  ///
  /// Replaces the current assignedSiteIds list entirely.
  Future<void> assignSites({
    required String userId,
    required List<String> siteIds,
  }) async {
    await _firestore.collection('users').doc(userId).update({
      'assignedSiteIds': siteIds,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Add a single site to a user's assignments.
  Future<void> addSiteAssignment({
    required String userId,
    required String siteId,
  }) async {
    await _firestore.collection('users').doc(userId).update({
      'assignedSiteIds': FieldValue.arrayUnion([siteId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Remove a single site from a user's assignments.
  Future<void> removeSiteAssignment({
    required String userId,
    required String siteId,
  }) async {
    await _firestore.collection('users').doc(userId).update({
      'assignedSiteIds': FieldValue.arrayRemove([siteId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update a user's role.
  Future<void> updateRole({
    required String userId,
    required UserRole role,
  }) async {
    await _firestore.collection('users').doc(userId).update({
      'role': role.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Disable a user (soft delete).
  Future<void> disableUser({
    required String userId,
  }) async {
    await _firestore.collection('users').doc(userId).update({
      'active': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Re-enable a disabled user.
  Future<void> enableUser({
    required String userId,
  }) async {
    await _firestore.collection('users').doc(userId).update({
      'active': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get all team members for a company.
  Stream<List<UserModel>> getTeamMembers(String companyId) {
    return _firestore
        .collection('users')
        .where('companyId', isEqualTo: companyId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList());
  }

  /// Get all supervisors for a company.
  Stream<List<UserModel>> getSupervisors(String companyId) {
    return _firestore
        .collection('users')
        .where('companyId', isEqualTo: companyId)
        .where('role', isEqualTo: UserRole.supervisor.name)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList());
  }
}
