import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:civilhelp/core/providers/company_provider.dart';
import '../models/payment_model.dart';
import '../repositories/payment_repository.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository();
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

final calculatePaymentProvider = FutureProvider.family<PaymentSummary, (
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
  double advancesTotal,
  double netAmount,
  String status,
)>((ref, params) async {
  final repository = ref.watch(paymentRepositoryProvider);
  final companyId = await ref.watch(userCompanyIdProvider.future);

  final payment = await repository.createPayment(
    labourId: params.$1,
    labourName: params.$2,
    siteId: params.$3,
    siteName: params.$4,
    periodStart: params.$5,
    periodEnd: params.$6,
    grossAmount: params.$7,
    advancesTotal: params.$8,
    netAmount: params.$9,
    status: params.$10,
    companyId: companyId,
    createdBy: 'system',
  );

  ref.invalidate(paymentsStreamProvider);
  ref.invalidate(pendingPaymentsCountProvider);

  return payment;
});

final updatePaymentProvider =
    FutureProvider.family<void, PaymentModel>((ref, payment) async {
  await ref.read(paymentRepositoryProvider).updatePayment(payment);
});

final deletePaymentProvider =
    FutureProvider.family<void, String>((ref, paymentId) async {
  await ref.read(paymentRepositoryProvider).deletePayment(paymentId);

  ref.invalidate(paymentsStreamProvider);
  ref.invalidate(pendingPaymentsCountProvider);
});