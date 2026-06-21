import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/enums/invitation_status.dart';
import '../../../core/providers/company_provider.dart';
import '../../../data/models/invitation_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/invitation_repository.dart';
import '../../../data/repositories/team_management_repository.dart';

/// Tenant-aware stream provider for all company team members.
final teamMembersProvider = StreamProvider<List<UserModel>>((ref) {
  final companyId = ref.watch(companyIdProvider);
  if (companyId.isEmpty) {
    return Stream.value(<UserModel>[]);
  }
  return ref.watch(teamManagementRepositoryProvider).getTeamMembers(companyId);
});

/// Tenant-aware stream provider for company supervisors.
final supervisorsProvider = StreamProvider<List<UserModel>>((ref) {
  final companyId = ref.watch(companyIdProvider);
  if (companyId.isEmpty) {
    return Stream.value(<UserModel>[]);
  }
  return ref.watch(teamManagementRepositoryProvider).getSupervisors(companyId);
});

/// Tenant-aware stream provider for all invitations.
final invitationsProvider = StreamProvider<List<InvitationModel>>((ref) {
  final companyId = ref.watch(companyIdProvider);
  if (companyId.isEmpty) {
    return Stream.value(<InvitationModel>[]);
  }
  return ref.watch(invitationRepositoryProvider).getCompanyInvitations(companyId);
});

/// Filtered provider for active/pending invitations.
final pendingInvitationsProvider = StreamProvider<List<InvitationModel>>((ref) {
  return ref.watch(invitationsProvider).when(
        data: (list) => Stream.value(
          list.where((invite) => invite.status == InvitationStatus.pending).toList(),
        ),
        loading: () => const Stream.empty(),
        error: (err, stack) => Stream.error(err, stack),
      );
});
