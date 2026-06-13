import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/enums/user_role.dart';

class UserModel {
  final String uid;
  final String tenantId;
  final String name;
  final String email;
  final String photoUrl;
  final String companyId;
  final UserRole role;
  final List<String> assignedSiteIds;
  final bool active;
  final bool onboarded;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.uid,
    required this.tenantId,
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.companyId,
    required this.role,
    required this.assignedSiteIds,
    required this.active,
    required this.onboarded,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel(
      uid: doc.id,
      tenantId: data['tenantId'] ?? data['companyId'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      companyId: data['companyId'] ?? '',
      role: parseRole(data['role']),
      assignedSiteIds: (data['assignedSiteIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      active: data['active'] ?? true,
      onboarded: data['onboarded'] as bool? ?? (data['companyId'] as String? ?? '').isNotEmpty,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'tenantId': tenantId,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'companyId': companyId,
      'role': role.name,
      'assignedSiteIds': assignedSiteIds,
      'active': active,
      'onboarded': onboarded,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }

  UserModel copyWith({
    String? uid,
    String? tenantId,
    String? name,
    String? email,
    String? photoUrl,
    String? companyId,
    UserRole? role,
    List<String>? assignedSiteIds,
    bool? active,
    bool? onboarded,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      tenantId: tenantId ?? this.tenantId,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      companyId: companyId ?? this.companyId,
      role: role ?? this.role,
      assignedSiteIds: assignedSiteIds ?? this.assignedSiteIds,
      active: active ?? this.active,
      onboarded: onboarded ?? this.onboarded,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
