import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../core/providers/tenant_provider.dart';
import '../../core/enums/user_role.dart';
import '../../core/providers/user_role_provider.dart';

class TenantGuard extends ConsumerWidget {
  final Widget child;

  const TenantGuard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed('/login');
          });
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final userDataAsync = ref.watch(userDataProvider);

        return userDataAsync.when(
          data: (userData) {
            final bool onboarded = userData?['onboarded'] as bool? ?? 
                ((userData?['companyId'] as String? ?? '').isNotEmpty);

            if (!onboarded) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context).pushReplacementNamed('/profile-setup');
              });
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final role = ref.watch(userRoleProvider);
            if (role == UserRole.admin) {
              return child;
            }

            final tenantState = ref.watch(tenantContextProvider);

            return tenantState.when(
              data: (tenant) {
                if (tenant == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Navigator.of(context).pushReplacementNamed('/company-access-required');
                  });
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                return child;
              },
              loading: () => const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => Scaffold(
                body: Center(
                  child: Text('Error loading tenant context: $error'),
                ),
              ),
            );
          },
          loading: () => const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => Scaffold(
            body: Center(
              child: Text('Error loading user profile: $error'),
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Text('Authentication error: $error'),
        ),
      ),
    );
  }
}

class CompanyAccessRequiredGuard extends ConsumerWidget {
  final Widget child;

  const CompanyAccessRequiredGuard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed('/login');
          });
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final userDataAsync = ref.watch(userDataProvider);

        return userDataAsync.when(
          data: (userData) {
            final bool onboarded = userData?['onboarded'] as bool? ?? 
                ((userData?['companyId'] as String? ?? '').isNotEmpty);

            if (!onboarded) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context).pushReplacementNamed('/profile-setup');
              });
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final role = ref.watch(userRoleProvider);
            if (role == UserRole.admin) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context).pushReplacementNamed('/dashboard');
              });
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final tenantState = ref.watch(tenantContextProvider);

            return tenantState.when(
              data: (tenant) {
                if (tenant != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Navigator.of(context).pushReplacementNamed('/dashboard');
                  });
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                return child;
              },
              loading: () => const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => child,
            );
          },
          loading: () => const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => child,
        );
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Text('Authentication error: $error'),
        ),
      ),
    );
  }
}
