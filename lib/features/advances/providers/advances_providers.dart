import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/company_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../repositories/advance_repository.dart';
import '../models/advance_model.dart';

final advanceRepositoryProvider = Provider<AdvanceRepository>((ref) {
  return AdvanceRepository();
});

final advancesListStreamProvider = StreamProvider<List<AdvanceModel>>((ref) {
  final repository = ref.watch(advanceRepositoryProvider);
  final companyIdAsync = ref.watch(userCompanyIdProvider);

  return companyIdAsync.when(
    data: (companyId) {
      if (companyId.isEmpty) return Stream.value([]);
      return repository.getAdvancesByCompanyStream(companyId);
    },
    loading: () => Stream.value([]),
    error: (e, _) => Stream.error(e),
  );
});

final outstandingAdvancesProvider = StreamProvider<List<AdvanceModel>>((ref) {
  final repository = ref.watch(advanceRepositoryProvider);
  final companyIdAsync = ref.watch(userCompanyIdProvider);

  return companyIdAsync.when(
    data: (companyId) {
      if (companyId.isEmpty) return Stream.value([]);
      return repository.getOutstandingAdvancesByCompanyStream(companyId);
    },
    loading: () => Stream.value([]),
    error: (e, _) => Stream.error(e),
  );
});

final advancesByLabourStreamProvider = StreamProvider.family<List<AdvanceModel>, String>((ref, labourId) {
  final repository = ref.watch(advanceRepositoryProvider);
  final companyIdAsync = ref.watch(userCompanyIdProvider);

  return companyIdAsync.when(
    data: (companyId) {
      if (companyId.isEmpty) return Stream.value([]);
      return repository.getAdvancesByLabourStream(companyId, labourId);
    },
    loading: () => Stream.value([]),
    error: (e, _) => Stream.error(e),
  );
});

final createAdvanceProvider = FutureProvider.family<AdvanceModel, ({String labourId, String labourName, double amount, String description, DateTime date})>((ref, params) async {
  final repository = ref.read(advanceRepositoryProvider);
  final companyId = await ref.read(userCompanyIdProvider.future);
  final currentUser = ref.read(currentUserProvider);

  final advance = await repository.createAdvance(
    labourId: params.labourId,
    labourName: params.labourName,
    amount: params.amount,
    description: params.description,
    date: params.date,
    companyId: companyId,
    createdBy: currentUser?.uid ?? 'unknown',
  );

  // Invalidate affected streams
  ref.invalidate(advancesListStreamProvider);
  ref.invalidate(outstandingAdvancesProvider);
  ref.invalidate(advancesByLabourStreamProvider(params.labourId));
  return advance;
});

final deleteAdvanceProvider = FutureProvider.family<void, String>((ref, advanceId) async {
  final repository = ref.read(advanceRepositoryProvider);
  final companyId = await ref.read(userCompanyIdProvider.future);

  await repository.deleteAdvance(
    advanceId: advanceId,
    companyId: companyId,
  );

  ref.invalidate(advancesListStreamProvider);
  ref.invalidate(outstandingAdvancesProvider);
});
