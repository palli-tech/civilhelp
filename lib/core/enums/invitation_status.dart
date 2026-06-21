enum InvitationStatus {
  pending,
  accepted,
  revoked,
  expired;

  String get displayName {
    switch (this) {
      case InvitationStatus.pending:
        return 'Pending';
      case InvitationStatus.accepted:
        return 'Accepted';
      case InvitationStatus.revoked:
        return 'Revoked';
      case InvitationStatus.expired:
        return 'Expired';
    }
  }
}
