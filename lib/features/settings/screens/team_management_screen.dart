import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;

import '../../../core/enums/user_role.dart';
import '../../../core/enums/invitation_status.dart';
import '../../../core/utils/email_helper.dart';
import '../../../core/providers/user_company_id_provider.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/invitation_model.dart';
import '../../../data/repositories/team_management_repository.dart';
import '../../../data/repositories/invitation_repository.dart';
import '../../../features/sites/providers/site_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/layouts/app_scaffold.dart';

class TeamManagementScreen extends ConsumerWidget {
  const TeamManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companyIdAsync = ref.watch(userCompanyIdProvider);

    return companyIdAsync.when(
      data: (companyId) {
        if (companyId.isEmpty) {
          return const AppScaffold(
            appBar: null,
            child: Center(child: Text('No active company associated.')),
          );
        }

        final teamMembersAsync = ref.watch(teamMembersStreamProvider(companyId));
        final invitationsAsync = ref.watch(companyInvitationsStreamProvider(companyId));
        final sitesAsync = ref.watch(sitesStreamProvider);

        return DefaultTabController(
          length: 2,
          child: AppScaffold(
            appBar: AppBar(
              title: const Text('Team Management'),
              bottom: const TabBar(
                tabs: [
                  Tab(icon: Icon(Icons.people), text: 'Members'),
                  Tab(icon: Icon(Icons.mail_outline), text: 'Invitations'),
                ],
              ),
            ),
            fab: FloatingActionButton.extended(
              onPressed: () => _showInviteDialog(
                context,
                ref,
                companyId,
                sitesAsync,
                teamMembersAsync.value,
                invitationsAsync.value,
              ),
              icon: const Icon(Icons.person_add),
              label: const Text('Invite Member'),
            ),
            child: TabBarView(
              children: [
                _buildMembersTab(context, ref, teamMembersAsync, sitesAsync),
                _buildInvitationsTab(context, ref, companyId, invitationsAsync, sitesAsync),
              ],
            ),
          ),
        );
      },
      loading: () => const AppScaffold(
        appBar: null,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => AppScaffold(
        appBar: null,
        child: Center(child: Text('Error loading company context: $err')),
      ),
    );
  }

  Widget _buildMembersTab(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<UserModel>> teamMembersAsync,
    AsyncValue<List<dynamic>> sitesAsync,
  ) {
    return teamMembersAsync.when(
      data: (members) {
        if (members.isEmpty) {
          return const Center(child: Text('No team members found.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: members.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final member = members[index];
            return Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                          child: Text(
                            member.name.isNotEmpty ? member.name[0].toUpperCase() : 'U',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                member.name.isNotEmpty ? member.name : 'No Name',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                member.email,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.outline,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: member.active
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            member.active ? 'Active' : 'Disabled',
                            style: TextStyle(
                              color: member.active ? Colors.green : Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Role: ${member.role.displayName}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () => _showRoleDialog(context, ref, member),
                          child: const Text('Change Role'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    sitesAsync.when(
                      data: (sites) {
                        final assignedSites = sites
                            .where((s) => member.assignedSiteIds.contains(s.id))
                            .map((s) => s.name)
                            .toList();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Assigned Sites: ${assignedSites.isNotEmpty ? assignedSites.join(', ') : 'None'}',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                if (member.role == UserRole.supervisor)
                                  TextButton(
                                    onPressed: () => _showSitesDialog(
                                      context,
                                      ref,
                                      member,
                                      sites,
                                    ),
                                    child: const Text('Assign Sites'),
                                  ),
                              ],
                            ),
                          ],
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (context, error) => const Text('Error loading sites info'),
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () async {
                            final repo = ref.read(teamManagementRepositoryProvider);
                            if (member.active) {
                              await repo.disableUser(userId: member.uid);
                            } else {
                              await repo.enableUser(userId: member.uid);
                            }
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'User status updated for ${member.name}',
                                  ),
                                ),
                              );
                            }
                          },
                          icon: Icon(
                            member.active ? Icons.block : Icons.check_circle_outline,
                            size: 16,
                          ),
                          label: Text(member.active ? 'Disable' : 'Enable'),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error loading team: $err')),
    );
  }

  Widget _buildInvitationsTab(
    BuildContext context,
    WidgetRef ref,
    String companyId,
    AsyncValue<List<InvitationModel>> invitationsAsync,
    AsyncValue<List<dynamic>> sitesAsync,
  ) {
    final dateFormatter = intl.DateFormat('dd MMM yyyy, hh:mm a');

    return invitationsAsync.when(
      data: (invitations) {
        if (invitations.isEmpty) {
          return const Center(child: Text('No invitations found.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: invitations.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final invite = invitations[index];

            Color badgeColor;
            Color textColor;
            switch (invite.status) {
              case InvitationStatus.pending:
                badgeColor = Colors.orange.withValues(alpha: 0.1);
                textColor = Colors.orange;
                break;
              case InvitationStatus.accepted:
                badgeColor = Colors.green.withValues(alpha: 0.1);
                textColor = Colors.green;
                break;
              case InvitationStatus.revoked:
                badgeColor = Colors.red.withValues(alpha: 0.1);
                textColor = Colors.red;
                break;
              case InvitationStatus.expired:
                badgeColor = Colors.grey.withValues(alpha: 0.1);
                textColor = Colors.grey;
                break;
            }

            return Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                          foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                          child: const Icon(Icons.mail_outline),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                invite.email,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Role: ${invite.role.displayName}',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.outline,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            invite.status.displayName,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    sitesAsync.when(
                      data: (sites) {
                        final assigned = sites
                            .where((s) => invite.assignedSiteIds.contains(s.id))
                            .map((s) => s.name)
                            .toList();
                        return Text(
                          'Assigned Sites: ${assigned.isNotEmpty ? assigned.join(', ') : 'None'}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (context, error) => const Text('Error loading sites info'),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Created: ${dateFormatter.format(invite.createdAt)}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.outline,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'Expires: ${dateFormatter.format(invite.expiresAt)}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.outline,
                        fontSize: 12,
                      ),
                    ),
                    if (invite.status == InvitationStatus.pending || invite.status == InvitationStatus.expired) ...[
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (invite.status == InvitationStatus.pending) ...[
                            OutlinedButton.icon(
                              onPressed: () async {
                                final repo = ref.read(invitationRepositoryProvider);
                                final currentUser = ref.read(currentUserProvider);
                                await repo.revokeInvitation(
                                  companyId: companyId,
                                  invitationId: invite.id,
                                  revokedBy: currentUser?.uid ?? 'unknown',
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Invitation revoked')),
                                  );
                                }
                              },
                              icon: const Icon(Icons.cancel_outlined, size: 16),
                              label: const Text('Revoke'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          ElevatedButton.icon(
                            onPressed: () async {
                              final repo = ref.read(invitationRepositoryProvider);
                              await repo.resendInvitation(
                                companyId: companyId,
                                invitationId: invite.id,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Invitation resent (expiration updated)')),
                                );
                              }
                            },
                            icon: const Icon(Icons.send, size: 16),
                            label: const Text('Resend'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error loading invitations: $err')),
    );
  }

  void _showInviteDialog(
    BuildContext context,
    WidgetRef ref,
    String companyId,
    AsyncValue<List<dynamic>> sitesAsync,
    List<UserModel>? currentMembers,
    List<InvitationModel>? currentInvitations,
  ) {
    final emailController = TextEditingController();
    UserRole selectedRole = UserRole.supervisor;
    final List<String> selectedSiteIds = [];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Invite Team Member'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        hintText: 'user@example.com',
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<UserRole>(
                      initialValue: selectedRole,
                      decoration: const InputDecoration(labelText: 'Role'),
                      items: [
                        UserRole.supervisor,
                        UserRole.admin,
                        UserRole.partner,
                      ].map((role) {
                        return DropdownMenuItem<UserRole>(
                          value: role,
                          child: Text(role.displayName),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            selectedRole = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Assign Sites',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    sitesAsync.when(
                      data: (sites) {
                        if (sites.isEmpty) {
                          return const Text('No sites available to assign.');
                        }
                        return Column(
                          children: sites.map((site) {
                            return CheckboxListTile(
                              title: Text(site.name),
                              value: selectedSiteIds.contains(site.id),
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    selectedSiteIds.add(site.id);
                                  } else {
                                    selectedSiteIds.remove(site.id);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        );
                      },
                      loading: () => const CircularProgressIndicator(),
                      error: (context, error) => const Text('Error loading sites'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final rawEmail = emailController.text.trim();
                    if (rawEmail.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter an email address')),
                      );
                      return;
                    }
                    final normalized = normalizeEmail(rawEmail);

                    // Client-side Duplicate Protection checks
                    if (currentMembers != null) {
                      final hasMember = currentMembers.any((m) => normalizeEmail(m.email) == normalized);
                      if (hasMember) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$rawEmail is already a member of this company')),
                        );
                        return;
                      }
                    }

                    if (currentInvitations != null) {
                      final hasActiveInvite = currentInvitations.any((invite) =>
                          normalizeEmail(invite.email) == normalized &&
                          (invite.status == InvitationStatus.pending ||
                           invite.status == InvitationStatus.accepted));
                      if (hasActiveInvite) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('An active or accepted invitation already exists for $rawEmail')),
                        );
                        return;
                      }
                    }

                    try {
                      final repo = ref.read(teamManagementRepositoryProvider);
                      final currentUser = ref.read(currentUserProvider);

                      await repo.inviteSupervisor(
                        tenantId: companyId, // Current data boundary context
                        companyId: companyId,
                        email: normalized,
                        role: selectedRole,
                        assignedSiteIds: selectedSiteIds,
                        invitedBy: currentUser?.uid ?? 'unknown',
                      );

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Invitation sent successfully')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                        );
                      }
                    }
                  },
                  child: const Text('Invite'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showRoleDialog(BuildContext context, WidgetRef ref, UserModel member) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Change Role for ${member.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: UserRole.values.map((role) {
              return ListTile(
                title: Text(role.displayName),
                trailing: member.role == role ? const Icon(Icons.check, color: Colors.blue) : null,
                onTap: () async {
                  final repo = ref.read(teamManagementRepositoryProvider);
                  await repo.updateRole(userId: member.uid, role: role);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Updated role to ${role.displayName}')),
                    );
                  }
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showSitesDialog(
    BuildContext context,
    WidgetRef ref,
    UserModel member,
    List<dynamic> allSites,
  ) {
    final List<String> tempSiteIds = List.from(member.assignedSiteIds);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Assign Sites to ${member.name}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: allSites.map((site) {
                    final isAssigned = tempSiteIds.contains(site.id);
                    return CheckboxListTile(
                      title: Text(site.name),
                      value: isAssigned,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            tempSiteIds.add(site.id);
                          } else {
                            tempSiteIds.remove(site.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final repo = ref.read(teamManagementRepositoryProvider);
                    await repo.assignSites(userId: member.uid, siteIds: tempSiteIds);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Site assignments updated')),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
