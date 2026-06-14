import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:civilhelp/core/providers/company_provider.dart';
import '../models/advance_model.dart';
import '../repositories/advance_repository.dart';

final advanceRepositoryProvider = Provider<AdvanceRepository>((ref) {
  return AdvanceRepository();
});

final advancesStreamProvider = StreamProvider<List<AdvanceModel>>((ref) {
  final repository = ref.watch(advanceRepositoryProvider);
  final companyId = ref.watch(userCompanyIdProvider);

  return companyId.when(
    data: (id) => repository.getAdvancesByCompanyStream(id),
    loading: () => Stream.value([]),
    error: (error, _) => Stream.error(error),
  );
});

final outstandingAdvancesStreamProvider = StreamProvider<List<AdvanceModel>>((ref) {
  final repository = ref.watch(advanceRepositoryProvider);
  final companyId = ref.watch(userCompanyIdProvider);

  return companyId.when(
    data: (id) => repository.getOutstandingAdvancesByCompanyStream(id),
    loading: () => Stream.value([]),
    error: (error, _) => Stream.error(error),
  );
});

final outstandingAdvanceTotalProvider = StreamProvider<double>((ref) {
  final repository = ref.watch(advanceRepositoryProvider);
  final companyId = ref.watch(userCompanyIdProvider);

  return companyId.when(
    data: (id) => repository
        .getOutstandingAdvancesByCompanyStream(id)
        .map((advances) => advances.fold<double>(0.0, (sum, item) => sum + (item.amount - item.recoveredAmount))),
    loading: () => Stream.value(0.0),
    error: (error, _) => Stream.error(error),
  );
});

final createAdvanceProvider = FutureProvider.family<AdvanceModel, (
  String labourId,
  String labourName,
  String siteId,
  String siteName,
  double amount,
  String reason,
  DateTime date,
)>((ref, params) async {
  final repository = ref.watch(advanceRepositoryProvider);
  final companyId = await ref.watch(userCompanyIdProvider.future);

  final advance = await repository.createAdvance(
    labourId: params.$1,
    labourName: params.$2,
    amount: params.$5,
    description: params.$6,
    date: params.$7,
    companyId: companyId,
    createdBy: 'system',
  );

  ref.invalidate(advancesStreamProvider);
  ref.invalidate(outstandingAdvancesStreamProvider);
  ref.invalidate(outstandingAdvanceTotalProvider);

  return advance;
});

final updateAdvanceProvider =
    FutureProvider.family<void, AdvanceModel>((ref, advance) async {
  await ref.read(advanceRepositoryProvider).updateAdvance(advance);

  ref.invalidate(advancesStreamProvider);
  ref.invalidate(outstandingAdvancesStreamProvider);
  ref.invalidate(outstandingAdvanceTotalProvider);
});

final deleteAdvanceProvider =
    FutureProvider.family<void, String>((ref, advanceId) async {
  final companyId = await ref.watch(userCompanyIdProvider.future);

  await ref.read(advanceRepositoryProvider).deleteAdvance(
        advanceId: advanceId,
        companyId: companyId,
      );

  ref.invalidate(advancesStreamProvider);
  ref.invalidate(outstandingAdvancesStreamProvider);
  ref.invalidate(outstandingAdvanceTotalProvider);
});

