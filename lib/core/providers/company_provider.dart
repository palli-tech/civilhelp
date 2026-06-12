import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tenant_provider.dart';

/// Backward-compatible provider used across many screens/providers.
///
/// Source of truth is the resolved [TenantContext].
///
/// IMPORTANT: This still keeps existing root `users/{uid}` reads
/// centralized inside `tenant_provider.dart`.
final companyIdProvider = Provider<String>((ref) {
  final tenantAsync = ref.watch(tenantContextProvider);

  return tenantAsync.maybeWhen(
    data: (tenant) => tenant?.companyId ?? '',
    orElse: () => '',
  );
});

/// Optional company id (some legacy providers/screens expect nullable).
///
/// IMPORTANT: Uses the same tenant resolution logic.
final userCompanyIdProvider = FutureProvider<String>((ref) async {
  final tenant = await ref.watch(tenantContextProvider.future);
  return tenant?.companyId ?? '';
});


