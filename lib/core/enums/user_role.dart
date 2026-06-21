enum UserRole {
  pending('pending'),
  owner('owner'),
  supervisor('supervisor'),
  admin('admin'),
  partner('partner');

  final String value;
  const UserRole(this.value);

  /// Safely parses a role from Firestore, supporting legacy values, different cases, and null.
  static UserRole fromString(String? roleStr) {
    return parseRole(roleStr);
  }

  /// Standardized display name
  String get displayName {
    switch (this) {
      case UserRole.owner:
        return 'Owner';
      case UserRole.supervisor:
        return 'Supervisor';
      case UserRole.admin:
        return 'Admin';
      case UserRole.partner:
        return 'Partner';
      case UserRole.pending:
        return 'Pending Setup';
    }
  }
}

/// Migration-safe helper to parse a UserRole from any dynamic value.
/// Supports legacy values (like 'businessOwner'), standard values, and case-insensitivity.
UserRole parseRole(dynamic value) {
  if (value == null) {
    return UserRole.pending;
  }
  
  final roleStr = value.toString().trim().toLowerCase();
  if (roleStr.isEmpty) {
    return UserRole.pending;
  }
  
  if (roleStr == 'businessowner' || roleStr == 'owner') {
    return UserRole.owner;
  }
  
  for (final role in UserRole.values) {
    if (role.name.toLowerCase() == roleStr || role.value.toLowerCase() == roleStr) {
      return role;
    }
  }
  
  return UserRole.pending;
}
