import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.currentUser;
});

final signInWithGoogleProvider = FutureProvider.family<void, void>((ref, _) async {
  final authService = ref.watch(authServiceProvider);
  await authService.signInWithGoogle();
});

final signOutProvider = FutureProvider.family<void, void>((ref, _) async {
  final authService = ref.watch(authServiceProvider);
  await authService.signOut();
});
