import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/enums/user_role.dart';
import '../../core/enums/invitation_status.dart';
import '../../core/utils/email_helper.dart';

class InvitationModel {
  final String id;
  final String tenantId;
  final String companyId;
  final String email;
  final UserRole role;
  final List<String> assignedSiteIds;
  final InvitationStatus status;
  final String invitedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime expiresAt;
  final DateTime? acceptedAt;
  final String? acceptedByUid;
  final DateTime? revokedAt;
  final String? revokedBy;
  final DateTime? lastSentAt;
  final int resendCount;

  InvitationModel({
    required this.id,
    required this.tenantId,
    required this.companyId,
    required this.email,
    required this.role,
    required this.assignedSiteIds,
    required this.status,
    required this.invitedBy,
    required this.createdAt,
    required this.updatedAt,
    required this.expiresAt,
    this.acceptedAt,
    this.acceptedByUid,
    this.revokedAt,
    this.revokedBy,
    this.lastSentAt,
    this.resendCount = 0,
  });

  factory InvitationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    final statusStr = data['status'] as String? ?? '';
    final InvitationStatus status = InvitationStatus.values.firstWhere(
      (e) => e.name == statusStr,
      orElse: () => InvitationStatus.pending,
    );

    return InvitationModel(
      id: doc.id,
      tenantId: data['tenantId'] ?? '',
      companyId: data['companyId'] ?? '',
      email: normalizeEmail(data['email'] ?? ''),
      role: parseRole(data['role']),
      assignedSiteIds: (data['assignedSiteIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      status: status,
      invitedBy: data['invitedBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      acceptedAt: (data['acceptedAt'] as Timestamp?)?.toDate(),
      acceptedByUid: data['acceptedByUid'],
      revokedAt: (data['revokedAt'] as Timestamp?)?.toDate(),
      revokedBy: data['revokedBy'],
      lastSentAt: (data['lastSentAt'] as Timestamp?)?.toDate(),
      resendCount: data['resendCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'tenantId': tenantId,
      'companyId': companyId,
      'email': normalizeEmail(email),
      'role': role.name,
      'assignedSiteIds': assignedSiteIds,
      'status': status.name,
      'invitedBy': invitedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'acceptedByUid': acceptedByUid,
      'revokedAt': revokedAt != null ? Timestamp.fromDate(revokedAt!) : null,
      'revokedBy': revokedBy,
      'lastSentAt': lastSentAt != null ? Timestamp.fromDate(lastSentAt!) : null,
      'resendCount': resendCount,
    };
  }

  InvitationModel copyWith({
    String? id,
    String? tenantId,
    String? companyId,
    String? email,
    UserRole? role,
    List<String>? assignedSiteIds,
    InvitationStatus? status,
    String? invitedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? expiresAt,
    DateTime? acceptedAt,
    String? acceptedByUid,
    DateTime? revokedAt,
    String? revokedBy,
    DateTime? lastSentAt,
    int? resendCount,
  }) {
    return InvitationModel(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      companyId: companyId ?? this.companyId,
      email: email ?? this.email,
      role: role ?? this.role,
      assignedSiteIds: assignedSiteIds ?? this.assignedSiteIds,
      status: status ?? this.status,
      invitedBy: invitedBy ?? this.invitedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      acceptedByUid: acceptedByUid ?? this.acceptedByUid,
      revokedAt: revokedAt ?? this.revokedAt,
      revokedBy: revokedBy ?? this.revokedBy,
      lastSentAt: lastSentAt ?? this.lastSentAt,
      resendCount: resendCount ?? this.resendCount,
    );
  }
}
