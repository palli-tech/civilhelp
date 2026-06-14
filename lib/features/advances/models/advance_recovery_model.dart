import 'package:cloud_firestore/cloud_firestore.dart';

class AdvanceRecoveryModel {
  final String id;
  final String companyId;
  final String advanceId;
  final String paymentId;
  final String labourId;
  final double recoveredAmount;
  final DateTime createdAt;
  final String createdBy;

  const AdvanceRecoveryModel({
    required this.id,
    required this.companyId,
    required this.advanceId,
    required this.paymentId,
    required this.labourId,
    required this.recoveredAmount,
    required this.createdAt,
    required this.createdBy,
  });

  factory AdvanceRecoveryModel.fromMap(Map<String, dynamic> map, String documentId) {
    return AdvanceRecoveryModel(
      id: documentId,
      companyId: map['companyId'] ?? '',
      advanceId: map['advanceId'] ?? '',
      paymentId: map['paymentId'] ?? '',
      labourId: map['labourId'] ?? '',
      recoveredAmount: (map['recoveredAmount'] as num?)?.toDouble() ?? 0.0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: map['createdBy'] ?? '',
    );
  }

  factory AdvanceRecoveryModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Advance recovery document does not exist');
    }
    return AdvanceRecoveryModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'companyId': companyId,
      'advanceId': advanceId,
      'paymentId': paymentId,
      'labourId': labourId,
      'recoveredAmount': recoveredAmount,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
    };
  }

  AdvanceRecoveryModel copyWith({
    String? id,
    String? companyId,
    String? advanceId,
    String? paymentId,
    String? labourId,
    double? recoveredAmount,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return AdvanceRecoveryModel(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      advanceId: advanceId ?? this.advanceId,
      paymentId: paymentId ?? this.paymentId,
      labourId: labourId ?? this.labourId,
      recoveredAmount: recoveredAmount ?? this.recoveredAmount,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
