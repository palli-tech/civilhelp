import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:civilhelp/features/auth/providers/auth_provider.dart';
import 'package:civilhelp/core/providers/user_company_id_provider.dart';

import 'package:civilhelp/features/labour/data/models/labour_model.dart';
import 'package:civilhelp/features/labour/data/repositories/labour_repository_impl.dart';

final labourRepositoryProvider = Provider<LabourRepository>((ref) {
  return LabourRepository();
});

/// Stream of all labour records for the user's company
final labourStreamProvider = StreamProvider<List<LabourModel>>((ref) {
  debugPrint('[DEBUG] labourStreamProvider started');
  final repository = ref.watch(labourRepositoryProvider);

  return ref.watch(userCompanyIdProvider).when<Stream<List<LabourModel>>>(
    data: (companyId) {
      debugPrint('[DEBUG] labourStreamProvider companyId: $companyId');
      return repository.getLabourByCompanyStream(companyId).map((data) {
debugPrint('[DEBUG] labourStreamProvider yielded ${data.length} items');
        return data;
      }).handleError((error) {
        debugPrint('[DEBUG] labourStreamProvider error: $error');
        throw error;
      });
    },
    loading: () => const Stream<List<LabourModel>>.empty(),
    error: (error, stackTrace) => const Stream<List<LabourModel>>.empty(),
  );
});

/// Get labour records by site
final labourBySiteStreamProvider =
    StreamProvider.family<List<LabourModel>, String>((ref, siteId) {
  final repository = ref.watch(labourRepositoryProvider);
  final companyIdAsync = ref.watch(userCompanyIdProvider);

  return companyIdAsync.when<Stream<List<LabourModel>>>(
    data: (companyId) => repository.getLabourBySiteStream(companyId, siteId),
    loading: () => Stream.value(const <LabourModel>[]),
    error: (error, stackTrace) => Stream.value(const <LabourModel>[]),
  );
});














/// Get labour records by status
final labourByStatusStreamProvider =
    StreamProvider.family<List<LabourModel>, String>((ref, status) {
  final repository = ref.watch(labourRepositoryProvider);
  final companyIdAsync = ref.watch(userCompanyIdProvider);

  return companyIdAsync.when<Stream<List<LabourModel>>>(
    data: (companyId) {
      // companyId comes from userCompanyIdProvider; it should be non-null here.
      return repository.getLabourByStatusStream(companyId, status);
    },
    loading: () => const Stream<List<LabourModel>>.empty(),
    error: (error, stackTrace) => const Stream<List<LabourModel>>.empty(),
  );
});

/// Get a single labour by ID
final labourByIdProvider = FutureProvider.family<LabourModel?, String>(
  (ref, labourId) async {
    final repository = ref.watch(labourRepositoryProvider);
    final companyId = await ref.watch(userCompanyIdProvider.future);
    return repository.getLabourById(
      companyId: companyId,
      labourId: labourId,
    );
  },
);


/// Search labour by name
final searchLabourProvider =
    FutureProvider.family<List<LabourModel>, String>((ref, searchTerm) async {
  final repository = ref.watch(labourRepositoryProvider);
  final companyId = await ref.watch(userCompanyIdProvider.future);

  if (searchTerm.isEmpty) {
    return [];
  }

  return repository.searchLabourByName(companyId, searchTerm);
});

/// Create a new labour
final createLabourProvider = FutureProvider.family<LabourModel, (
  String fullName,
  String phoneNumber,
  String aadhaarNumber,
  double dailyWage,
  String assignedSiteId,
  String assignedSiteName,
  DateTime joinedDate,
  String status,
)>((ref, params) async {
  final repository = ref.watch(labourRepositoryProvider);
  final currentUser = ref.watch(currentUserProvider);
  final companyId = await ref.watch(userCompanyIdProvider.future);

  final labour = await repository.createLabour(
    fullName: params.$1,
    phoneNumber: params.$2,
    aadhaarNumber: params.$3,
    dailyWage: params.$4,
    assignedSiteId: params.$5,
    assignedSiteName: params.$6,
    joinedDate: params.$7,
    status: params.$8,
    companyId: companyId,
    createdBy: currentUser?.uid ?? 'unknown',
  );

  ref.invalidate(labourStreamProvider);

  return labour;
});

/// Update an existing labour
final updateLabourProvider = FutureProvider.family<void, (
  String labourId,
  String fullName,
  String phoneNumber,
  String aadhaarNumber,
  double dailyWage,
  String assignedSiteId,
  String assignedSiteName,
  DateTime joinedDate,
  String status,
)>((ref, params) async {
  final repository = ref.watch(labourRepositoryProvider);

  final companyId = await ref.watch(userCompanyIdProvider.future);

await repository.updateLabour(
    companyId: companyId,
      labourId: params.$1,
      fullName: params.$2,
      phoneNumber: params.$3,
      aadhaarNumber: params.$4,
      dailyWage: params.$5,
      assignedSiteId: params.$6,
      assignedSiteName: params.$7,
      joinedDate: params.$8,
      status: params.$9,
    );

  ref.invalidate(labourStreamProvider);
  ref.invalidate(labourByIdProvider(params.$1));
});

/// Update labour status
final updateLabourStatusProvider =
    FutureProvider.family<void, (String labourId, String status)>(
  (ref, params) async {
    final repository = ref.watch(labourRepositoryProvider);

    final companyId = await ref.watch(userCompanyIdProvider.future);

    await repository.updateLabourStatus(
      companyId: companyId,
      labourId: params.$1,
      status: params.$2,
    );

    ref.invalidate(labourStreamProvider);
    ref.invalidate(labourByIdProvider(params.$1));
  },
);

/// Delete a labour
final deleteLabourProvider =
    FutureProvider.family<void, String>((ref, labourId) async {
  final repository = ref.watch(labourRepositoryProvider);
  final companyId = await ref.watch(userCompanyIdProvider.future);

  await repository.deleteLabour(
    companyId: companyId,
    labourId: labourId,
  );

  ref.invalidate(labourStreamProvider);
});


