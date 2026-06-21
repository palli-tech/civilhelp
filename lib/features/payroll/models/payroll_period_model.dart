import 'package:cloud_firestore/cloud_firestore.dart';

class PayrollPeriodModel {
  final String id;
  final String companyId;
  final String name; // user-supplied or auto-generated label
  final DateTime startDate;
  final DateTime endDate;
  final String status; // 'open', 'frozen', 'paid'
  final DateTime createdAt;
  final String createdBy;
  final DateTime? frozenAt;
  final String? frozenBy;
  final DateTime? paidAt;
  final String? paidBy;
  final String settlementJobStatus; // 'pending', 'processing', 'completed', 'failed'
  final DateTime? settlementStartedAt;
  final DateTime? settlementCompletedAt;

  const PayrollPeriodModel({
    required this.id,
    required this.companyId,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.createdAt,
    required this.createdBy,
    this.frozenAt,
    this.frozenBy,
    this.paidAt,
    this.paidBy,
    this.settlementJobStatus = 'pending',
    this.settlementStartedAt,
    this.settlementCompletedAt,
  });

  factory PayrollPeriodModel.fromMap(Map<String, dynamic> map, String documentId) {
    // Legacy fallback: reconstruct a human-readable name from old composite IDs
    // Old format: {companyId}_{year}_{month}_{cycle}
    final storedName = map['name'] as String?;
    final resolvedName = storedName != null && storedName.isNotEmpty
        ? storedName
        : _legacyNameFromId(documentId);

    return PayrollPeriodModel(
      id: documentId,
      companyId: map['companyId'] ?? '',
      name: resolvedName,
      startDate: (map['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (map['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] ?? 'open',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: map['createdBy'] ?? '',
      frozenAt: (map['frozenAt'] as Timestamp?)?.toDate(),
      frozenBy: map['frozenBy'] as String?,
      paidAt: (map['paidAt'] as Timestamp?)?.toDate(),
      paidBy: map['paidBy'] as String?,
      settlementJobStatus: map['settlementJobStatus'] ?? 'pending',
      settlementStartedAt: (map['settlementStartedAt'] as Timestamp?)?.toDate(),
      settlementCompletedAt: (map['settlementCompletedAt'] as Timestamp?)?.toDate(),
    );
  }

  factory PayrollPeriodModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Payroll period document does not exist');
    }
    return PayrollPeriodModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'companyId': companyId,
      'name': name,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'frozenAt': frozenAt != null ? Timestamp.fromDate(frozenAt!) : null,
      'frozenBy': frozenBy,
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
      'paidBy': paidBy,
      'settlementJobStatus': settlementJobStatus,
      'settlementStartedAt': settlementStartedAt != null ? Timestamp.fromDate(settlementStartedAt!) : null,
      'settlementCompletedAt': settlementCompletedAt != null ? Timestamp.fromDate(settlementCompletedAt!) : null,
    };
  }

  PayrollPeriodModel copyWith({
    String? id,
    String? companyId,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    DateTime? createdAt,
    String? createdBy,
    DateTime? frozenAt,
    String? frozenBy,
    DateTime? paidAt,
    String? paidBy,
    String? settlementJobStatus,
    DateTime? settlementStartedAt,
    DateTime? settlementCompletedAt,
  }) {
    return PayrollPeriodModel(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      frozenAt: frozenAt ?? this.frozenAt,
      frozenBy: frozenBy ?? this.frozenBy,
      paidAt: paidAt ?? this.paidAt,
      paidBy: paidBy ?? this.paidBy,
      settlementJobStatus: settlementJobStatus ?? this.settlementJobStatus,
      settlementStartedAt: settlementStartedAt ?? this.settlementStartedAt,
      settlementCompletedAt: settlementCompletedAt ?? this.settlementCompletedAt,
    );
  }

  // ---------------------------------------------------------------------------
  // Legacy helpers
  // ---------------------------------------------------------------------------

  /// Reconstructs a display-friendly name from the old composite document ID.
  /// Old format: {companyId}_{year}_{month}_{cycle}
  static String _legacyNameFromId(String docId) {
    final parts = docId.split('_');
    if (parts.length >= 4) {
      final year = parts[parts.length - 3];
      final monthNum = int.tryParse(parts[parts.length - 2]) ?? 0;
      if (monthNum >= 1 && monthNum <= 12) {
        const monthNames = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
        ];
        return '${monthNames[monthNum - 1]} $year';
      }
    }
    return 'Payroll Period';
  }
}
