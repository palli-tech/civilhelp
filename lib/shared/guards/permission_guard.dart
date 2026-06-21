import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/permissions.dart';
import '../../core/enums/user_role.dart';
import '../../core/providers/user_role_provider.dart';
import '../../features/auth/providers/auth_provider.dart';

/// A guard widget that restricts access based on a specific [Permission].
///
/// Preferred over [RoleGuard] for fine-grained access control.
/// Uses the permission mapping from [rolePermissions] to determine access.
///
/// Example:
/// ```dart
/// PermissionGuard(
///   permission: Permission.managePayments,
///   child: PaymentsScreen(),
/// )
/// ```
class PermissionGuard extends ConsumerWidget {
  final Permission permission;
  final Widget child;

  const PermissionGuard({
    super.key,
    required this.permission,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userDataAsync = ref.watch(userDataProvider);

    return userDataAsync.when(
      data: (_) {
        final role = ref.watch(userRoleProvider);
        final hasAccess = role.hasPermission(permission);

        if (hasAccess) {
          return child;
        }

        return _PermissionDeniedScreen(
          currentRole: role,
          requiredPermission: permission,
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

/// Inline widget that hides its child if the user lacks the given [Permission].
///
/// Use this for hiding individual buttons, FABs, or actions within a screen
/// that the user is allowed to access but certain actions within are restricted.
///
/// Example:
/// ```dart
/// PermissionWidget(
///   permission: Permission.deleteAttendance,
///   child: IconButton(icon: Icon(Icons.delete), onPressed: onDelete),
/// )
/// ```
class PermissionWidget extends ConsumerWidget {
  final Permission permission;
  final Widget child;
  final Widget? fallback;

  const PermissionWidget({
    super.key,
    required this.permission,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(userRoleProvider);
    final hasAccess = role.hasPermission(permission);

    if (hasAccess) {
      return child;
    }

    return fallback ?? const SizedBox.shrink();
  }
}

class _PermissionDeniedScreen extends StatelessWidget {
  final UserRole currentRole;
  final Permission requiredPermission;

  const _PermissionDeniedScreen({
    required this.currentRole,
    required this.requiredPermission,
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
                'You do not have permission to access this feature.',
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
