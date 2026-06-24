import 'package:cloud_firestore/cloud_firestore.dart';

class Company {
  final String id;
  final String name; // maps to Display Name
  final String address; // maps to Registered Address
  final String phone; // maps to Primary Contact
  final String email; // maps to Support Email
  final String gstNumber;
  final String logoUrl;
  final String ownerUid;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  // New SaaS specific fields
  final String legalName;
  final String panNumber;
  final String registrationNumber;
  final String alternateContact;
  final String operationalAddress;
  final String primaryColor;
  final String secondaryColor;
  final String currency;
  final double workingHours;
  final int attendanceBackdateLimitDays;

  Company({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.email,
    required this.gstNumber,
    required this.logoUrl,
    this.ownerUid = '',
    this.createdAt,
    this.updatedAt,
    required this.isActive,
    this.legalName = '',
    this.panNumber = '',
    this.registrationNumber = '',
    this.alternateContact = '',
    this.operationalAddress = '',
    this.primaryColor = '#7B4DFF',
    this.secondaryColor = '#5F2EEA',
    this.currency = 'INR',
    this.workingHours = 8.0,
    this.attendanceBackdateLimitDays = 3,
  });

  factory Company.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Company(
      id: doc.id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      gstNumber: data['gstNumber'] ?? '',
      logoUrl: data['logoUrl'] ?? '',
      ownerUid: data['ownerUid'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] ?? true,
      legalName: data['legalName'] ?? '',
      panNumber: data['panNumber'] ?? '',
      registrationNumber: data['registrationNumber'] ?? '',
      alternateContact: data['alternateContact'] ?? '',
      operationalAddress: data['operationalAddress'] ?? '',
      primaryColor: data['primaryColor'] ?? '#7B4DFF',
      secondaryColor: data['secondaryColor'] ?? '#5F2EEA',
      currency: data['currency'] ?? 'INR',
      workingHours: (data['workingHours'] as num?)?.toDouble() ?? 8.0,
      attendanceBackdateLimitDays: data['attendanceBackdateLimitDays'] ?? 3,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'gstNumber': gstNumber,
      'logoUrl': logoUrl,
      'ownerUid': ownerUid,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
      'isActive': isActive,
      'legalName': legalName,
      'panNumber': panNumber,
      'registrationNumber': registrationNumber,
      'alternateContact': alternateContact,
      'operationalAddress': operationalAddress,
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
      'currency': currency,
      'workingHours': workingHours,
      'attendanceBackdateLimitDays': attendanceBackdateLimitDays,
    };
  }

  Company copyWith({
    String? id,
    String? name,
    String? address,
    String? phone,
    String? email,
    String? gstNumber,
    String? logoUrl,
    String? ownerUid,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? legalName,
    String? panNumber,
    String? registrationNumber,
    String? alternateContact,
    String? operationalAddress,
    String? primaryColor,
    String? secondaryColor,
    String? currency,
    double? workingHours,
    int? attendanceBackdateLimitDays,
  }) {
    return Company(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      gstNumber: gstNumber ?? this.gstNumber,
      logoUrl: logoUrl ?? this.logoUrl,
      ownerUid: ownerUid ?? this.ownerUid,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      legalName: legalName ?? this.legalName,
      panNumber: panNumber ?? this.panNumber,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      alternateContact: alternateContact ?? this.alternateContact,
      operationalAddress: operationalAddress ?? this.operationalAddress,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      currency: currency ?? this.currency,
      workingHours: workingHours ?? this.workingHours,
      attendanceBackdateLimitDays: attendanceBackdateLimitDays ?? this.attendanceBackdateLimitDays,
    );
  }
}
