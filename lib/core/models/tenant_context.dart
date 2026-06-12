import 'package:cloud_firestore/cloud_firestore.dart';

class TenantContext {
  final String companyId;
  final String companyName;
  final String logoUrl;
  final String tenantStatus;
  final DateTime? createdAt;

  TenantContext({
    required this.companyId,
    required this.companyName,
    required this.logoUrl,
    required this.tenantStatus,
    this.createdAt,
  });

  factory TenantContext.fromMap(Map<String, dynamic> data) {
    return TenantContext(
      companyId: data['companyId'] ?? '',
      companyName: data['companyName'] ?? '',
      logoUrl: data['logoUrl'] ?? '',
      tenantStatus: data['tenantStatus'] ?? 'active',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'companyId': companyId,
      'companyName': companyName,
      'logoUrl': logoUrl,
      'tenantStatus': tenantStatus,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }
}
