import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/invitation_model.dart';
import '../../core/enums/invitation_status.dart';
import '../../core/utils/email_helper.dart';

final invitationRepositoryProvider = Provider<InvitationRepository>((ref) {
  return InvitationRepository();
});

final companyInvitationsStreamProvider = StreamProvider.family<List<InvitationModel>, String>((ref, companyId) {
  final repo = ref.watch(invitationRepositoryProvider);
  return repo.getCompanyInvitations(companyId);
});

class InvitationRepository {
  final FirebaseFirestore _firestore;

  InvitationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Creates a new invitation inside the company's subcollection.
  Future<void> createInvitation(InvitationModel invitation) async {
    final docRef = _firestore
        .collection('companies')
        .doc(invitation.companyId)
        .collection('invitations')
        .doc();
        
    final completeInvitation = invitation.copyWith(id: docRef.id);
    await docRef.set(completeInvitation.toFirestore());
  }

  /// Searches the invitations collection group for a pending invitation matching the email.
  Future<InvitationModel?> getPendingInvitationByEmail(String email) async {
    final normalized = normalizeEmail(email);
    final snapshot = await _firestore
        .collectionGroup('invitations')
        .where('email', isEqualTo: normalized)
        .where('status', isEqualTo: InvitationStatus.pending.name)
        .where('expiresAt', isGreaterThan: Timestamp.fromDate(DateTime.now()))
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return InvitationModel.fromFirestore(snapshot.docs.first);
  }

  /// Revokes an invitation (audit update).
  Future<void> revokeInvitation({
    required String companyId,
    required String invitationId,
    required String revokedBy,
  }) async {
    await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('invitations')
        .doc(invitationId)
        .update({
      'status': InvitationStatus.revoked.name,
      'revokedAt': FieldValue.serverTimestamp(),
      'revokedBy': revokedBy,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Resends an invitation (audit update, updates lastSentAt and increments resendCount, keeps status as pending).
  ///
  /// Only allows resending if current status is pending or expired.
  Future<void> resendInvitation({
    required String companyId,
    required String invitationId,
  }) async {
    final docRef = _firestore
        .collection('companies')
        .doc(companyId)
        .collection('invitations')
        .doc(invitationId);

    await _firestore.runTransaction((transaction) async {
      final snap = await transaction.get(docRef);
      if (!snap.exists) {
        throw Exception('Invitation not found.');
      }
      final data = snap.data() as Map<String, dynamic>;
      final statusStr = data['status'] as String? ?? '';

      if (statusStr == InvitationStatus.revoked.name) {
        throw Exception('Cannot resend a revoked invitation.');
      }
      if (statusStr == InvitationStatus.accepted.name) {
        throw Exception('Cannot resend an already accepted invitation.');
      }

      transaction.update(docRef, {
        'status': InvitationStatus.pending.name,
        'lastSentAt': FieldValue.serverTimestamp(),
        'resendCount': FieldValue.increment(1),
        'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(days: 14))),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Explicitly marks an invitation as expired (audit update).
  Future<void> expireInvitation({
    required String companyId,
    required String invitationId,
  }) async {
    await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('invitations')
        .doc(invitationId)
        .update({
      'status': InvitationStatus.expired.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Streams invitations for a company, ordered by creation date descending.
  Stream<List<InvitationModel>> getCompanyInvitations(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('invitations')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => InvitationModel.fromFirestore(doc))
          .toList();
    });
  }
}
