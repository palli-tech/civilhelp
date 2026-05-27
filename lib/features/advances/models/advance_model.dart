import 'package:cloud_firestore/cloud_firestore.dart';

class AdvanceModel {
  final String id;
  final String labourId;
  final String labourName;
  final String siteId;
  final String siteName;
  final double amount;
  final String reason;
  final DateTime date;
  final bool paidBack;
  final String companyId;
  final DateTime createdAt;
  final String createdBy;

  const AdvanceModel({
    required this.id,
    required this.labourId,
    required this.labourName,
    required this.siteId,
    required this.siteName,
    required this.amount,
    required this.reason,
    required this.date,
    required this.paidBack,
    required this.companyId,
    required this.createdAt,
    required this.createdBy,
  });

  factory AdvanceModel.fromMap(Map<String, dynamic> map, String documentId) {
    return AdvanceModel(
      id: documentId,
      labourId: map['labourId'] ?? '',
      labourName: map['labourName'] ?? '',
      siteId: map['siteId'] ?? '',
      siteName: map['siteName'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      reason: map['reason'] ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      paidBack: map['paidBack'] as bool? ?? false,
      companyId: map['companyId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: map['createdBy'] ?? '',
    );
  }

  factory AdvanceModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Advance document does not exist');
    }
    return AdvanceModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'labourId': labourId,
      'labourName': labourName,
      'siteId': siteId,
      'siteName': siteName,
      'amount': amount,
      'reason': reason,
      'date': Timestamp.fromDate(date),
      'paidBack': paidBack,
      'companyId': companyId,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
    };
  }

  AdvanceModel copyWith({
    String? id,
    String? labourId,
    String? labourName,
    String? siteId,
    String? siteName,
    double? amount,
    String? reason,
    DateTime? date,
    bool? paidBack,
    String? companyId,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return AdvanceModel(
      id: id ?? this.id,
      labourId: labourId ?? this.labourId,
      labourName: labourName ?? this.labourName,
      siteId: siteId ?? this.siteId,
      siteName: siteName ?? this.siteName,
      amount: amount ?? this.amount,
      reason: reason ?? this.reason,
      date: date ?? this.date,
      paidBack: paidBack ?? this.paidBack,
      companyId: companyId ?? this.companyId,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
