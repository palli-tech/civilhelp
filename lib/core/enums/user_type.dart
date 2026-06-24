enum UserType {
  owner('owner'),
  employee('employee');

  final String value;
  const UserType(this.value);

  String get displayName {
    switch (this) {
      case UserType.owner:
        return 'Company / MSME Owner';
      case UserType.employee:
        return 'Employee / Supervisor';
    }
  }

  static UserType fromString(String? typeStr) {
    if (typeStr == null) return UserType.employee;
    final val = typeStr.trim().toLowerCase();
    if (val == 'owner') return UserType.owner;
    return UserType.employee;
  }
}
