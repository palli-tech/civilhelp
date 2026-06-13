enum UserRole {
  pending('pending'),
  owner('owner'),
  supervisor('supervisor'),
  admin('admin'),
  partner('partner');

  final String value;
  const UserRole(this.value);

  /// Safely parses a string from Firestore.
  /// Standardizes 'businessOwner' -> 'owner' for backward compatibility.
  /// Defaults to 'pending' on null, empty, or unknown values.
  static UserRole fromString(String? roleStr) {
    if (roleStr == null || roleStr.trim().isEmpty) {
      return UserRole.pending;
    }
    
    final normalized = roleStr.trim().toLowerCase();
    if (normalized == 'businessowner') {
      return UserRole.owner;
    }
    
    for (final role in UserRole.values) {
      if (role.value == normalized) {
        return role;
      }
    }
    
    return UserRole.pending;
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
