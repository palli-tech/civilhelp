enum AccountStatus {
  pending('pending'),
  approved('approved'),
  active('active'),
  rejected('rejected');

  final String value;
  const AccountStatus(this.value);

  String get displayName {
    switch (this) {
      case AccountStatus.pending:
        return 'Pending Approval';
      case AccountStatus.approved:
        return 'Approved';
      case AccountStatus.active:
        return 'Active';
      case AccountStatus.rejected:
        return 'Rejected';
    }
  }

  static AccountStatus fromString(String? statusStr) {
    if (statusStr == null) return AccountStatus.pending;
    final val = statusStr.trim().toLowerCase();
    for (final status in AccountStatus.values) {
      if (status.name == val || status.value == val) {
        return status;
      }
    }
    return AccountStatus.pending;
  }
}
