import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:civilhelp/core/providers/company_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/site_model.dart';
import '../repositories/site_repository.dart';

final siteRepositoryProvider = Provider<SiteRepository>((ref) {
  return SiteRepository();
});

/// Stream of all sites for the user's company
final sitesStreamProvider = StreamProvider<List<SiteModel>>((ref) {
  final repository = ref.watch(siteRepositoryProvider);
  final userCompanyId = ref.watch(userCompanyIdProvider);

  return userCompanyId.when(
    data: (companyId) => repository.getSitesByCompanyStream(companyId),
    loading: () => Stream.value([]),
    error: (error, _) => Stream.error(error),
  );
});

/// Get a single site by ID
final siteByIdProvider = FutureProvider.family<SiteModel?, String>((ref, siteId) async {
  final repository = ref.watch(siteRepositoryProvider);
  final companyId = await ref.watch(userCompanyIdProvider.future);
  return repository.getSiteById(companyId: companyId, siteId: siteId);
});

/// Create a new site
final createSiteProvider = FutureProvider.family<SiteModel, (
  String name,
  String location,
  String client,
  DateTime startDate,
  String status,
)>((ref, params) async {
  final repository = ref.watch(siteRepositoryProvider);
  final currentUser = ref.watch(currentUserProvider);
  final companyId = ref.watch(userCompanyIdProvider).value ?? 'default-company';

  final site = await repository.createSite(
    name: params.$1,
    location: params.$2,
    client: params.$3,
    startDate: params.$4,
    status: params.$5,
    companyId: companyId,
    createdBy: currentUser?.uid ?? 'unknown',
  );

  // Refresh the sites list
  ref.invalidate(sitesStreamProvider);

  return site;
});

/// Update an existing site
final updateSiteProvider = FutureProvider.family<void, (
  String siteId,
  String name,
  String location,
  String client,
  DateTime startDate,
  String status,
)>((ref, params) async {
  final repository = ref.watch(siteRepositoryProvider);

  final companyId = await ref.watch(userCompanyIdProvider.future);

  await repository.updateSite(
    siteId: params.$1,
    name: params.$2,
    location: params.$3,
    client: params.$4,
    startDate: params.$5,
    status: params.$6,
    companyId: companyId,
  );


  // Refresh the sites list and single site
  ref.invalidate(sitesStreamProvider);
  ref.invalidate(siteByIdProvider(params.$1));
});

/// Delete a site
final deleteSiteProvider = FutureProvider.family<void, String>((ref, siteId) async {
  final repository = ref.watch(siteRepositoryProvider);

  final companyId = await ref.watch(userCompanyIdProvider.future);

  await repository.deleteSite(
    companyId: companyId,
    siteId: siteId,
  );

  // Refresh the sites list
  ref.invalidate(sitesStreamProvider);
});

