import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../enums/user_role.dart';
import '../auth/permissions.dart';
import '../../features/auth/providers/auth_provider.dart';

/// Single source of truth for the currently authenticated user's role.
///
/// Derives the [UserRole] from the user document streamed by [userDataProvider].
/// All guards, screens, and providers that need to make role-based decisions
/// should watch this provider instead of parsing the role string themselves.
final userRoleProvider = Provider<UserRole>((ref) {
  final userData = ref.watch(userDataProvider).value;
  final roleStr = userData?['role'] as String?;
  return UserRole.fromString(roleStr);
});

/// Convenience provider: the set of permissions for the current user.
final userPermissionsProvider = Provider<Set<Permission>>((ref) {
  final role = ref.watch(userRoleProvider);
  return role.permissions;
});

/// Convenience provider: check if the current user has a specific permission.
final hasPermissionProvider = Provider.family<bool, Permission>((ref, permission) {
  final permissions = ref.watch(userPermissionsProvider);
  return permissions.contains(permission);
});

/// The list of site IDs assigned to the current user (for supervisors).
///
/// Returns an empty list for owners (who see all sites) or if no assignment exists.
final assignedSiteIdsProvider = Provider<List<String>>((ref) {
  final userData = ref.watch(userDataProvider).value;
  final ids = userData?['assignedSiteIds'] as List<dynamic>?;
  return ids?.map((e) => e.toString()).toList() ?? [];
});
