import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  final String id;
  final String labourId;
  final String labourName;
  final String siteId;
  final String siteName;
  final DateTime periodStart;
  final DateTime periodEnd;
  final double grossAmount;
  final double advancesTotal;
  final double netAmount;
  final String status;
  final String companyId;
  final DateTime createdAt;
  final String createdBy;
  final List<String> appliedAdvanceIds;

  const PaymentModel({
    required this.id,
    required this.labourId,
    required this.labourName,
    required this.siteId,
    required this.siteName,
    required this.periodStart,
    required this.periodEnd,
    required this.grossAmount,
    required this.advancesTotal,
    required this.netAmount,
    required this.status,
    required this.companyId,
    required this.createdAt,
    required this.createdBy,
    this.appliedAdvanceIds = const [],
  });

  factory PaymentModel.fromMap(Map<String, dynamic> map, String documentId) {
    return PaymentModel(
      id: documentId,
      labourId: map['labourId'] ?? '',
      labourName: map['labourName'] ?? '',
      siteId: map['siteId'] ?? '',
      siteName: map['siteName'] ?? '',
      periodStart: (map['periodStart'] as Timestamp?)?.toDate() ?? DateTime.now(),
      periodEnd: (map['periodEnd'] as Timestamp?)?.toDate() ?? DateTime.now(),
      grossAmount: (map['grossAmount'] as num?)?.toDouble() ?? 0.0,
      advancesTotal: (map['advancesTotal'] as num?)?.toDouble() ?? 0.0,
      netAmount: (map['netAmount'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'pending',
      companyId: map['companyId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: map['createdBy'] ?? '',
      appliedAdvanceIds: (map['appliedAdvanceIds'] as List<dynamic>?)
              ?.map((e) => e?.toString() ?? '')
              .where((s) => s.isNotEmpty)
              .toList() ??
          <String>[],
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
      'labourId': labourId,
      'labourName': labourName,
      'siteId': siteId,
      'siteName': siteName,
      'periodStart': Timestamp.fromDate(periodStart),
      'periodEnd': Timestamp.fromDate(periodEnd),
      'grossAmount': grossAmount,
      'advancesTotal': advancesTotal,
      'netAmount': netAmount,
      'status': status,
      'companyId': companyId,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'appliedAdvanceIds': appliedAdvanceIds,
    };
  }

  PaymentModel copyWith({
    String? id,
    String? labourId,
    String? labourName,
    String? siteId,
    String? siteName,
    DateTime? periodStart,
    DateTime? periodEnd,
    double? grossAmount,
    double? advancesTotal,
    double? netAmount,
    String? status,
    String? companyId,
    DateTime? createdAt,
    String? createdBy,
    List<String>? appliedAdvanceIds,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      labourId: labourId ?? this.labourId,
      labourName: labourName ?? this.labourName,
      siteId: siteId ?? this.siteId,
      siteName: siteName ?? this.siteName,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      grossAmount: grossAmount ?? this.grossAmount,
      advancesTotal: advancesTotal ?? this.advancesTotal,
      netAmount: netAmount ?? this.netAmount,
      status: status ?? this.status,
      companyId: companyId ?? this.companyId,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      appliedAdvanceIds: appliedAdvanceIds ?? this.appliedAdvanceIds,
    );
  }
}
