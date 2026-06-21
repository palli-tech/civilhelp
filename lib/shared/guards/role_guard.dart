import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/enums/user_role.dart';
import '../../core/providers/user_role_provider.dart';
import '../../features/auth/providers/auth_provider.dart';

/// A guard widget that restricts access based on the user's [UserRole].
///
/// Works alongside [TenantGuard] — the route should first pass through
/// TenantGuard (ensuring authentication + tenant membership) and then
/// through RoleGuard (ensuring the user's role is authorized).
///
/// If the user's role is not in [allowedRoles], an "Access Denied" screen
/// is shown instead of the child.
class RoleGuard extends ConsumerWidget {
  final List<UserRole> allowedRoles;
  final Widget child;

  const RoleGuard({
    super.key,
    required this.allowedRoles,
    required this.child,
  });

  /// Convenience: only [UserRole.owner] can access.
  const RoleGuard.ownerOnly({
    super.key,
    required this.child,
  }) : allowedRoles = const [UserRole.owner];

  /// Convenience: [UserRole.owner] and [UserRole.supervisor] can access.
  const RoleGuard.ownerAndSupervisor({
    super.key,
    required this.child,
  }) : allowedRoles = const [UserRole.owner, UserRole.supervisor];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userDataAsync = ref.watch(userDataProvider);

    return userDataAsync.when(
      data: (userData) {
        final role = ref.watch(userRoleProvider);

        if (allowedRoles.contains(role)) {
          return child;
        }

        return _AccessDeniedScreen(
          currentRole: role,
          requiredRoles: allowedRoles,
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
    );
  }
}

/// A full-screen "Access Denied" view displayed when a user navigates to
/// a route they are not authorized to access.
class _AccessDeniedScreen extends StatelessWidget {
  final UserRole currentRole;
  final List<UserRole> requiredRoles;

  const _AccessDeniedScreen({
    required this.currentRole,
    required this.requiredRoles,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Access Denied'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacementNamed('/dashboard');
            }
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Access Denied',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'You do not have permission to access this page.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Your role: ${currentRole.displayName}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    Navigator.of(context).pushReplacementNamed('/dashboard');
                  }
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
