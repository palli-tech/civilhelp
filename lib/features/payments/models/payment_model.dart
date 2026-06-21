import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  final String id;
  final String companyId;
  final String labourId;
  final String labourName;
  final String payrollPeriodId;
  // Stored period bounds — stamped at settlement time, no ID parsing required.
  final DateTime periodStart;
  final DateTime periodEnd;
  final double grossEarningsSnapshot;
  final double deductionsSnapshot;
  final double amount; // Net amount
  final String paymentMode; // 'cash', 'upi', 'bankTransfer'
  final String? referenceNumber;
  final DateTime paymentDate;
  final String? notes;
  final DateTime createdAt;
  final String createdBy;

  const PaymentModel({
    required this.id,
    required this.companyId,
    required this.labourId,
    required this.labourName,
    required this.payrollPeriodId,
    required this.periodStart,
    required this.periodEnd,
    required this.grossEarningsSnapshot,
    required this.deductionsSnapshot,
    required this.amount,
    required this.paymentMode,
    this.referenceNumber,
    required this.paymentDate,
    this.notes,
    required this.createdAt,
    required this.createdBy,
  });

  factory PaymentModel.fromMap(Map<String, dynamic> map, String documentId) {
    final periodId = map['payrollPeriodId'] as String? ?? '';

    // Stored fields take precedence; fall back to parsing the old composite ID
    // for records created before the Issue 2 migration.
    final storedStart = (map['periodStart'] as Timestamp?)?.toDate();
    final storedEnd = (map['periodEnd'] as Timestamp?)?.toDate();

    return PaymentModel(
      id: documentId,
      companyId: map['companyId'] ?? '',
      labourId: map['labourId'] ?? '',
      labourName: map['labourName'] ?? '',
      payrollPeriodId: periodId,
      periodStart: storedStart ?? _parsePeriodStartFromId(periodId),
      periodEnd: storedEnd ?? _parsePeriodEndFromId(periodId),
      grossEarningsSnapshot: (map['grossEarningsSnapshot'] as num?)?.toDouble() ??
                             (map['grossAmount'] as num?)?.toDouble() ?? 0.0,
      deductionsSnapshot: (map['deductionsSnapshot'] as num?)?.toDouble() ??
                          (map['advancesTotal'] as num?)?.toDouble() ?? 0.0,
      amount: (map['amount'] as num?)?.toDouble() ??
              (map['netAmount'] as num?)?.toDouble() ?? 0.0,
      paymentMode: map['paymentMode'] ?? 'cash',
      referenceNumber: map['referenceNumber'] as String?,
      paymentDate: (map['paymentDate'] as Timestamp?)?.toDate() ??
                   (map['paidDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notes: map['notes'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: map['createdBy'] ?? '',
    );
  }

  factory PaymentModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Payment document does not exist');
    }
    return PaymentModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'companyId': companyId,
      'labourId': labourId,
      'labourName': labourName,
      'payrollPeriodId': payrollPeriodId,
      'periodStart': Timestamp.fromDate(periodStart),
      'periodEnd': Timestamp.fromDate(periodEnd),
      'grossEarningsSnapshot': grossEarningsSnapshot,
      'deductionsSnapshot': deductionsSnapshot,
      'amount': amount,
      'paymentMode': paymentMode,
      'referenceNumber': referenceNumber,
      'paymentDate': Timestamp.fromDate(paymentDate),
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
    };
  }

  PaymentModel copyWith({
    String? id,
    String? companyId,
    String? labourId,
    String? labourName,
    String? payrollPeriodId,
    DateTime? periodStart,
    DateTime? periodEnd,
    double? grossEarningsSnapshot,
    double? deductionsSnapshot,
    double? amount,
    String? paymentMode,
    String? referenceNumber,
    DateTime? paymentDate,
    String? notes,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      labourId: labourId ?? this.labourId,
      labourName: labourName ?? this.labourName,
      payrollPeriodId: payrollPeriodId ?? this.payrollPeriodId,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      grossEarningsSnapshot: grossEarningsSnapshot ?? this.grossEarningsSnapshot,
      deductionsSnapshot: deductionsSnapshot ?? this.deductionsSnapshot,
      amount: amount ?? this.amount,
      paymentMode: paymentMode ?? this.paymentMode,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      paymentDate: paymentDate ?? this.paymentDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  // ---------------------------------------------------------------------------
  // Legacy fallbacks — parse period dates from old composite IDs
  // Only used for pre-migration records that have no stored periodStart/periodEnd.
  // Old ID format: {companyId}_{year}_{month}_{cycle}
  // ---------------------------------------------------------------------------

  static DateTime _parsePeriodStartFromId(String periodId) {
    try {
      final parts = periodId.split('_');
      if (parts.length >= 3) {
        final year = int.parse(parts[parts.length - 3]);
        final month = int.parse(parts[parts.length - 2]);
        return DateTime(year, month, 1);
      }
    } catch (_) {}
    return DateTime.now().subtract(const Duration(days: 15));
  }

  static DateTime _parsePeriodEndFromId(String periodId) {
    try {
      final parts = periodId.split('_');
      if (parts.length >= 3) {
        final year = int.parse(parts[parts.length - 3]);
        final month = int.parse(parts[parts.length - 2]);
        return DateTime(year, month + 1, 0); // last day of month
      }
    } catch (_) {}
    return DateTime.now();
  }

  // ---------------------------------------------------------------------------
  // Compatibility getters for UI and report layers
  // ---------------------------------------------------------------------------

  String get status => 'paid';
  String? get paymentNumber => referenceNumber ?? id;
  String get siteName => 'Payroll Settlement';
  double get grossAmount => grossEarningsSnapshot;
  double get advancesTotal => deductionsSnapshot;
  double get netAmount => amount;
  DateTime? get paidDate => paymentDate;
  String get siteId => '';
}

class PaymentSummary {
  final double grossAmount;
  final double advancesTotal;
  final double netAmount;

  const PaymentSummary({
    required this.grossAmount,
    required this.advancesTotal,
    required this.netAmount,
  });
}
