import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/company_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../repositories/payroll_repository.dart';
import '../models/payroll_period_model.dart';
import '../models/payroll_register_model.dart';
import '../models/payroll_summary_model.dart';

final payrollRepositoryProvider = Provider<PayrollRepository>((ref) {
  return PayrollRepository();
});

final payrollPeriodsStreamProvider = StreamProvider<List<PayrollPeriodModel>>((ref) {
  final repository = ref.watch(payrollRepositoryProvider);
  final companyIdAsync = ref.watch(userCompanyIdProvider);

  return companyIdAsync.when(
    data: (companyId) {
      if (companyId.isEmpty) return Stream.value([]);
      return repository.getPayrollPeriodsStream(companyId);
    },
    loading: () => Stream.value([]),
    error: (e, _) => Stream.error(e),
  );
});

final payrollPeriodStreamProvider =
    StreamProvider.family<PayrollPeriodModel?, String>((ref, periodId) {
  final repository = ref.watch(payrollRepositoryProvider);
  final companyIdAsync = ref.watch(userCompanyIdProvider);

  return companyIdAsync.when(
    data: (companyId) {
      if (companyId.isEmpty) return Stream.value(null);
      return repository.getPayrollPeriodStream(companyId, periodId);
    },
    loading: () => Stream.value(null),
    error: (e, _) => Stream.error(e),
  );
});

final payrollSummaryStreamProvider =
    StreamProvider.family<PayrollSummaryModel?, String>((ref, periodId) {
  final repository = ref.watch(payrollRepositoryProvider);
  final companyIdAsync = ref.watch(userCompanyIdProvider);

  return companyIdAsync.when(
    data: (companyId) {
      if (companyId.isEmpty) return Stream.value(null);
      return repository.getPayrollSummaryStream(companyId, periodId);
    },
    loading: () => Stream.value(null),
    error: (e, _) => Stream.error(e),
  );
});

final payrollRegistersStreamProvider =
    StreamProvider.family<List<PayrollRegisterModel>, String>((ref, periodId) {
  final repository = ref.watch(payrollRepositoryProvider);
  final companyIdAsync = ref.watch(userCompanyIdProvider);

  return companyIdAsync.when(
    data: (companyId) {
      if (companyId.isEmpty) return Stream.value([]);
      return repository.getPayrollRegistersStream(companyId, periodId);
    },
    loading: () => Stream.value([]),
    error: (e, _) => Stream.error(e),
  );
});

final payrollCalculationProvider =
    FutureProvider.family<List<PayrollCalculationResult>, String>((ref, periodId) async {
  final repository = ref.watch(payrollRepositoryProvider);
  final companyId = await ref.watch(userCompanyIdProvider.future);
  if (companyId.isEmpty) return [];
  return repository.calculatePayroll(companyId: companyId, periodId: periodId);
});

final finalizePayrollProvider = FutureProvider.family<void,
    ({String periodId, List<PayrollCalculationResult> results, String paymentMode})>(
  (ref, params) async {
    final repository = ref.read(payrollRepositoryProvider);
    final companyId = await ref.read(userCompanyIdProvider.future);
    final currentUser = ref.read(currentUserProvider);

    await repository.finalizePayroll(
      companyId: companyId,
      periodId: params.periodId,
      finalizedBy: currentUser?.uid ?? 'unknown',
      results: params.results,
      paymentMode: params.paymentMode,
    );

    ref.invalidate(payrollPeriodsStreamProvider);
    ref.invalidate(payrollPeriodStreamProvider(params.periodId));
    ref.invalidate(payrollCalculationProvider(params.periodId));
    ref.invalidate(payrollSummaryStreamProvider(params.periodId));
    ref.invalidate(payrollRegistersStreamProvider(params.periodId));
  },
);

/// Creates a new payroll period with an arbitrary name and date range.
///
/// Type parameter: ({String name, DateTime startDate, DateTime endDate})
final createPayrollPeriodProvider = FutureProvider.family<PayrollPeriodModel,
    ({String name, DateTime startDate, DateTime endDate})>(
  (ref, params) async {
    final repository = ref.read(payrollRepositoryProvider);
    final companyId = await ref.read(userCompanyIdProvider.future);
    final currentUser = ref.read(currentUserProvider);

    final model = await repository.createPayrollPeriod(
      companyId: companyId,
      name: params.name,
      startDate: params.startDate,
      endDate: params.endDate,
      createdBy: currentUser?.uid ?? 'unknown',
    );

    ref.invalidate(payrollPeriodsStreamProvider);
    return model;
  },
);

final freezePayrollPeriodProvider =
    FutureProvider.family<void, String>((ref, periodId) async {
  final repository = ref.read(payrollRepositoryProvider);
  final companyId = await ref.read(userCompanyIdProvider.future);
  final currentUser = ref.read(currentUserProvider);

  await repository.freezePayrollPeriod(
    companyId: companyId,
    periodId: periodId,
    frozenBy: currentUser?.uid ?? 'unknown',
  );

  ref.invalidate(payrollPeriodsStreamProvider);
  ref.invalidate(payrollPeriodStreamProvider(periodId));
});

final reopenPayrollPeriodProvider =
    FutureProvider.family<void, String>((ref, periodId) async {
  final repository = ref.read(payrollRepositoryProvider);
  final companyId = await ref.read(userCompanyIdProvider.future);
  final currentUser = ref.read(currentUserProvider);

  await repository.reopenPayrollPeriod(
    companyId: companyId,
    periodId: periodId,
    reopenedBy: currentUser?.uid ?? 'unknown',
  );

  ref.invalidate(payrollPeriodsStreamProvider);
  ref.invalidate(payrollPeriodStreamProvider(periodId));
});
