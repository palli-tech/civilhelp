import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/enums/user_role.dart';
import '../../../core/enums/invitation_status.dart';
import '../../../core/utils/email_helper.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  AuthService({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  Future<UserCredential> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        throw Exception('Sign in aborted by user');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      
      final user = userCredential.user;
      if (user == null) {
        throw Exception('User is null after sign-in');
      }

      await _createUserIfNotExists(user);

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _createUserIfNotExists(User user) async {
    final userEmail = normalizeEmail(user.email ?? '');
    if (userEmail.isEmpty) {
      await _createNormalPendingUser(user);
      return;
    }

    // 1. Search invitations collection group for a pending invitation matching this email
    final inviteQuery = await _firestore
        .collectionGroup('invitations')
        .where('email', isEqualTo: userEmail)
        .where('status', isEqualTo: InvitationStatus.pending.name)
        .limit(1)
        .get();

    if (inviteQuery.docs.isEmpty) {
      await _createNormalPendingUser(user);
      return;
    }

    final inviteSnap = inviteQuery.docs.first;
    final inviteData = inviteSnap.data();
    final expiresAtTimestamp = inviteData['expiresAt'] as Timestamp?;
    final expiresAt = expiresAtTimestamp?.toDate();

    // 2. Check if expired
    if (expiresAt != null && expiresAt.isBefore(DateTime.now())) {
      // Expiration Processing: Mark status = expired, update updatedAt, do not delete
      await inviteSnap.reference.update({
        'status': InvitationStatus.expired.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await _createNormalPendingUser(user);
      return;
    }

    // 3. Pending invitation exists. Perform atomic transaction.
    try {
      await _firestore.runTransaction((transaction) async {
        final freshInviteSnap = await transaction.get(inviteSnap.reference);
        if (!freshInviteSnap.exists) {
          throw Exception('Invitation document does not exist.');
        }

        final freshData = freshInviteSnap.data() as Map<String, dynamic>;
        final statusStr = freshData['status'] as String? ?? '';
        final freshExpiresAtTimestamp = freshData['expiresAt'] as Timestamp?;
        final freshExpiresAt = freshExpiresAtTimestamp?.toDate();

        if (statusStr != InvitationStatus.pending.name) {
          throw Exception('Invitation is no longer pending.');
        }

        if (freshExpiresAt != null && freshExpiresAt.isBefore(DateTime.now())) {
          transaction.update(inviteSnap.reference, {
            'status': InvitationStatus.expired.name,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          throw Exception('Invitation has expired during transaction.');
        }

        final userDocRef = _firestore.collection('users').doc(user.uid);
        final userSnap = await transaction.get(userDocRef);

        if (!userSnap.exists) {
          transaction.set(userDocRef, {
            'tenantId': freshData['tenantId'] ?? freshData['companyId'] ?? '',
            'name': user.displayName ?? '',
            'email': user.email ?? '',
            'photoUrl': user.photoURL ?? '',
            'companyId': freshData['companyId'] ?? '',
            'role': freshData['role'] ?? 'pending',
            'assignedSiteIds': freshData['assignedSiteIds'] ?? [],
            'active': true,
            'onboarded': false,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          final userData = userSnap.data() as Map<String, dynamic>;
          final existingEmail = normalizeEmail(userData['email'] as String? ?? '');
          final existingCompanyId = userData['companyId'] as String? ?? '';

          if (existingEmail != userEmail) {
            throw Exception('Authenticated email does not match user document.');
          }

          if (existingCompanyId.isEmpty) {
            transaction.update(userDocRef, {
              'tenantId': freshData['tenantId'] ?? freshData['companyId'] ?? '',
              'companyId': freshData['companyId'] ?? '',
              'role': freshData['role'] ?? 'pending',
              'assignedSiteIds': freshData['assignedSiteIds'] ?? [],
              'updatedAt': FieldValue.serverTimestamp(),
            });
          } else if (existingCompanyId == freshData['companyId']) {
            transaction.update(userDocRef, {
              'role': freshData['role'] ?? 'pending',
              'assignedSiteIds': freshData['assignedSiteIds'] ?? [],
              'updatedAt': FieldValue.serverTimestamp(),
            });
          } else {
            throw Exception('This account already belongs to another company. Please use a different email address or contact support.');
          }
        }

        transaction.update(inviteSnap.reference, {
          'status': InvitationStatus.accepted.name,
          'acceptedAt': FieldValue.serverTimestamp(),
          'acceptedByUid': user.uid,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      if (e.toString().contains('already belongs to another company')) {
        rethrow;
      }
      await _createNormalPendingUser(user);
    }
  }

  Future<void> _createNormalPendingUser(User user) async {
    final userDoc = _firestore.collection('users').doc(user.uid);
    final docSnapshot = await userDoc.get();

    if (!docSnapshot.exists) {
      await userDoc.set({
        'tenantId': '',
        'name': user.displayName ?? '',
        'email': user.email ?? '',
        'photoUrl': user.photoURL ?? '',
        'companyId': '',
        'role': UserRole.pending.name,
        'assignedSiteIds': [],
        'active': true,
        'onboarded': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> signOut() async {
    try {
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      rethrow;
    }
  }
}
