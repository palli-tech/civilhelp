# Implementation Plan: Critical Fixes for CivilHelp

---

## 🚨 Priority 1: Fix Navigation & Rendering Errors
**Issue**: `SplashScreen` navigation occurs before widget layout is complete, causing:
- `Cannot hit test a render box that has never been laid out`
- `Assertion failed: box.dart:2251:12`

**Files Impacted**:
- `lib/features/auth/screens/splash_screen.dart`

**Fix Strategy**:
1. Replace `Future.microtask` with `SchedulerBinding.instance.addPostFrameCallback`
2. Ensure `mounted` check before navigation
3. Move logic to `initState` for lifecycle safety

**Implementation**:
```dart
// lib/features/auth/screens/splash_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      final authState = await ref.read(authStateProvider.future);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(
        authState != null ? '/dashboard' : '/login',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
```

**Validation**:
- ✅ No navigation before widget layout
- ✅ No render box errors
- ✅ Proper lifecycle handling

---

## 🔐 Priority 2: Null Safety in AuthService
**Issue**: Force-unwrapping `userCredential.user!` in `_createUserIfNotExists` risks runtime crashes.

**Files Impacted**:
- `lib/features/auth/services/auth_service.dart`

**Fix Strategy**:
1. Add null check for `userCredential.user`
2. Early return if user is null
3. Preserve existing Firestore logic

**Implementation**:
```dart
// lib/features/auth/services/auth_service.dart
Future<void> _createUserIfNotExists(User user) async {
  final userDoc = _firestore.collection('users').doc(user.uid);
  final docSnapshot = await userDoc.get();

  if (!docSnapshot.exists) {
    await userDoc.set({
      'name': user.displayName ?? '',
      'email': user.email ?? '',
      'photoUrl': user.photoURL ?? '',
      'role': 'supervisor',
      'companyId': '',
      'assignedSiteIds': [],
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

Future<UserCredential> signInWithGoogle() async {
  try {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('Sign in aborted by user');

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user == null) throw Exception('User is null after sign-in');

    await _createUserIfNotExists(user);
    return userCredential;
  } catch (e) {
    rethrow;
  }
}
```

**Validation**:
- ✅ No force-unwrapping
- ✅ Early null checks
- ✅ Preserved Firestore logic

---

## 🧱 Priority 3: Router Error Handling
**Issue**: Missing `companyId` enforcement in Firestore user creation, risking multi-tenancy violations.

**Files Impacted**:
- `lib/features/auth/services/auth_service.dart`

**Fix Strategy**:
1. Add `companyId` validation in `_createUserIfNotExists`
2. Default to empty string for new users
3. Ensure backward compatibility

**Implementation**:
```dart
// lib/features/auth/services/auth_service.dart
Future<void> _createUserIfNotExists(User user) async {
  final userDoc = _firestore.collection('users').doc(user.uid);
  final docSnapshot = await userDoc.get();

  if (!docSnapshot.exists) {
    await userDoc.set({
      'name': user.displayName ?? '',
      'email': user.email ?? '',
      'photoUrl': user.photoURL ?? '',
      'role': 'supervisor',
      'companyId': '', // Explicit default for multi-tenancy
      'assignedSiteIds': [],
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
```

**Validation**:
- ✅ Explicit `companyId` handling
- ✅ No breaking changes
- ✅ Multi-tenancy safety

---

## 📅 Rollout Plan
| Step | Action | Owner | ETA |
|------|--------|-------|-----|
| 1 | Implement `SplashScreen` fix | Dev | 1h |
| 2 | Test navigation flow | QA | 1h |
| 3 | Implement `AuthService` null safety | Dev | 1h |
| 4 | Validate Firestore writes | QA | 1h |
| 5 | Deploy to staging | DevOps | 2h |
| 6 | Regression test | QA | 2h |
| 7 | Production release | DevOps | 1h |

---

## 🛡️ Risk Mitigation
- **Rollback Plan**: Revert to commit `HEAD~1` if navigation/auth fails
- **Monitoring**: Track `NullPointerException` and `RenderBox` errors in Sentry
- **Feature Flags**: Disable Google Sign-In if Firestore writes fail

---

## ✅ Success Criteria
1. No `RenderBox` or `Assertion` errors in production
2. Zero null-related crashes in auth flow
3. 100% Firestore user documents contain `companyId`
4. All navigation routes work without layout glitches