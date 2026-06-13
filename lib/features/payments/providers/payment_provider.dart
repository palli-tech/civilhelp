import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:civilhelp/core/providers/company_provider.dart';
import 'package:civilhelp/features/advances/repositories/advance_repository.dart';
import 'package:civilhelp/features/advances/providers/advance_provider.dart';
import '../models/payment_model.dart';
import '../repositories/payment_repository.dart';

final advanceRepositoryProvider = Provider<AdvanceRepository>((ref) {
  return AdvanceRepository();
});

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(advanceRepository: ref.watch(advanceRepositoryProvider));
});

final paymentsStreamProvider = StreamProvider<List<PaymentModel>>((ref) {
  final repository = ref.watch(paymentRepositoryProvider);
  final companyId = ref.watch(userCompanyIdProvider);

  return companyId.when(
    data: (id) => repository.getPaymentsByCompanyStream(id),
    loading: () => Stream.value([]),
    error: (error, _) => Stream.error(error),
  );
});

final pendingPaymentsCountProvider = StreamProvider<int>((ref) {
  final repository = ref.watch(paymentRepositoryProvider);
  final companyId = ref.watch(userCompanyIdProvider);

  return companyId.when(
    data: (id) => repository
        .getPaymentsByStatusStream(id, 'pending')
        .map((payments) => payments.length),
    loading: () => Stream.value(0),
    error: (error, _) => Stream.error(error),
  );
});

final calculatePaymentProvider = FutureProvider.autoDispose.family<PaymentSummary, (
  String labourId,
  double dailyWage,
  DateTime periodStart,
  DateTime periodEnd,
)>((ref, params) async {
  final repository = ref.watch(paymentRepositoryProvider);
  final companyId = await ref.watch(userCompanyIdProvider.future);

  return repository.calculatePaymentSummaryForPeriod(
    companyId: companyId,
    labourId: params.$1,
    dailyWage: params.$2,
    periodStart: params.$3,
    periodEnd: params.$4,
  );
});

final createPaymentProvider = FutureProvider.family<PaymentModel, (
  String labourId,
  String labourName,
  String siteId,
  String siteName,
  DateTime periodStart,
  DateTime periodEnd,
  double grossAmount,
)>((ref, params) async {
  final repository = ref.watch(paymentRepositoryProvider);
  final companyId = await ref.watch(userCompanyIdProvider.future);

  final payment = await repository.createPaymentWithAdvancesApplied(
    labourId: params.$1,
    labourName: params.$2,
    siteId: params.$3,
    siteName: params.$4,
    periodStart: params.$5,
    periodEnd: params.$6,
    grossAmount: params.$7,
    companyId: companyId,
    createdBy: 'system',
  );

  ref.invalidate(paymentsStreamProvider);
  ref.invalidate(pendingPaymentsCountProvider);

  return payment;
});

final markPaymentPaidProvider = FutureProvider.family<void, String>((ref, paymentId) async {
  final companyId = await ref.watch(userCompanyIdProvider.future);

  await ref.read(paymentRepositoryProvider).markPaymentAsPaid(
    paymentId: paymentId,
    companyId: companyId,
  );

  ref.invalidate(paymentsStreamProvider);
  ref.invalidate(pendingPaymentsCountProvider);
});


final updatePaymentStatusProvider = FutureProvider.family<void, (String paymentId, String status)>((ref, params) async {
  final repository = ref.read(paymentRepositoryProvider);

  final companyId = await ref.watch(userCompanyIdProvider.future);

  await repository.updatePaymentStatus(
    paymentId: params.$1,
    status: params.$2,
    companyId: companyId,
  );




  ref.invalidate(paymentsStreamProvider);
  ref.invalidate(pendingPaymentsCountProvider);
});




final updatePaymentProvider =
    FutureProvider.family<void, PaymentModel>((ref, payment) async {
  await ref.read(paymentRepositoryProvider).updatePayment(payment);
  ref.invalidate(paymentsStreamProvider);
  ref.invalidate(pendingPaymentsCountProvider);
});

final deletePaymentProvider =
    FutureProvider.family<void, String>((ref, paymentId) async {
  final companyId = await ref.read(userCompanyIdProvider.future);
  await ref.read(paymentRepositoryProvider).deletePayment(
    paymentId: paymentId,
    companyId: companyId,
  );


  ref.invalidate(paymentsStreamProvider);
  ref.invalidate(pendingPaymentsCountProvider);
  ref.invalidate(advancesStreamProvider);
  ref.invalidate(outstandingAdvancesStreamProvider);
  ref.invalidate(outstandingAdvanceTotalProvider);
});

final hasOverlappingPaymentProvider = FutureProvider.family<bool, (
  String labourId,
  DateTime periodStart,
  DateTime periodEnd,
)>((ref, params) async {
  final repository = ref.watch(paymentRepositoryProvider);
  final companyId = await ref.watch(userCompanyIdProvider.future);

  return repository.hasOverlappingPayment(
    companyId: companyId,
    labourId: params.$1,
    periodStart: params.$2,
    periodEnd: params.$3,
  );
});

