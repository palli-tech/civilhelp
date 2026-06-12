import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/tenant_context.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../data/repositories/company_repository.dart';

final companyRepositoryProvider = Provider<CompanyRepository>((ref) {
  return CompanyRepository();
});

final tenantContextProvider = FutureProvider<TenantContext?>((ref) async {
  final user = ref.watch(currentUserProvider);
  
  if (user == null) {
    return null;
  }

  final firestore = FirebaseFirestore.instance;
  final userDoc = await firestore.collection('users').doc(user.uid).get();
  
  if (!userDoc.exists) {
    return null;
  }

  final companyId = userDoc.data()?['companyId'] as String?;
  if (companyId == null || companyId.isEmpty) {
    return null;
  }

  final companyRepo = ref.watch(companyRepositoryProvider);
  final company = await companyRepo.getCompany(companyId);
  
  if (company == null || !company.isActive) {
    return null;
  }

  return TenantContext(
    companyId: company.id,
    companyName: company.name,
    logoUrl: company.logoUrl,
    tenantStatus: company.isActive ? 'active' : 'inactive',
    createdAt: company.createdAt,
  );
});

final requireTenantContextProvider = Provider<TenantContext>((ref) {
  final tenantState = ref.watch(tenantContextProvider);
  return tenantState.maybeWhen(
    data: (tenant) {
      if (tenant == null) {
        throw StateError('TenantContext is null. User not associated with an active company.');
      }
      return tenant;
    },
    orElse: () => throw StateError('TenantContext is not yet loaded.'),
  );
});

// A stream provider to listen to live updates of the tenant's company
final tenantCompanyStreamProvider = StreamProvider((ref) {
  final tenant = ref.watch(tenantContextProvider).value;
  if (tenant == null) return const Stream.empty();
  
  final companyRepo = ref.watch(companyRepositoryProvider);
  return companyRepo.watchCompany(tenant.companyId);
});
