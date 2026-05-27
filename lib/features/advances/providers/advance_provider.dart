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
        .map((advances) => advances.fold<double>(0.0, (sum, item) => sum + item.amount)),
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
    siteId: params.$3,
    siteName: params.$4,
    amount: params.$5,
    reason: params.$6,
    date: params.$7,
    paidBack: false,
    companyId: companyId,
    createdBy: 'system',
  );

  ref.invalidate(advancesStreamProvider);
  ref.invalidate(outstandingAdvancesStreamProvider);
  ref.invalidate(outstandingAdvanceTotalProvider);

  return advance;
});
