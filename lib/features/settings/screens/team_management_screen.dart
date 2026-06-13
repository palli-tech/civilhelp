import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;

import '../../../core/enums/user_role.dart';
import '../../../core/enums/invitation_status.dart';
import '../../../core/utils/email_helper.dart';
import '../../../core/providers/company_provider.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/invitation_model.dart';
import '../../../data/repositories/team_management_repository.dart';
import '../../../data/repositories/invitation_repository.dart';
import '../../../features/sites/providers/site_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/layouts/app_scaffold.dart';
import '../providers/team_management_providers.dart';

class TeamManagementScreen extends ConsumerStatefulWidget {
  const TeamManagementScreen({super.key});

  @override
  ConsumerState<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends ConsumerState<TeamManagementScreen> {
  String _memberSearchQuery = '';
  String _inviteSearchQuery = '';
  InvitationStatus? _selectedInviteStatus; // null means "All"
  late final TextEditingController _memberSearchController;
  late final TextEditingController _inviteSearchController;

  @override
  void initState() {
    super.initState();
    _memberSearchController = TextEditingController();
    _inviteSearchController = TextEditingController();
  }

  @override
  void dispose() {
    _memberSearchController.dispose();
    _inviteSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final companyId = ref.watch(companyIdProvider);
    final theme = Theme.of(context);

    if (companyId.isEmpty) {
      return const AppScaffold(
        appBar: null,
        child: Center(child: Text('No active company associated.')),
      );
    }

    final teamMembersAsync = ref.watch(teamMembersProvider);
    final invitationsAsync = ref.watch(invitationsProvider);
    final sitesAsync = ref.watch(sitesStreamProvider);

    return DefaultTabController(
      length: 2,
      child: AppScaffold(
        appBar: AppBar(
          title: const Text('Team Management'),
          bottom: TabBar(
            indicatorColor: theme.colorScheme.primary,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            tabs: const [
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
            _buildMembersTab(context, teamMembersAsync, sitesAsync),
            _buildInvitationsTab(context, companyId, invitationsAsync, sitesAsync),
          ],
        ),
      ),
    );
  }

  // --- Members Tab ---
  Widget _buildMembersTab(
    BuildContext context,
    AsyncValue<List<UserModel>> teamMembersAsync,
    AsyncValue<List<dynamic>> sitesAsync,
  ) {
    final theme = Theme.of(context);
    final dateFormatter = intl.DateFormat('dd MMM yyyy, hh:mm a');

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(teamMembersProvider);
      },
      child: teamMembersAsync.when(
        data: (members) {
          // Client-side filtering/search
          final filteredMembers = members.where((m) {
            final query = _memberSearchQuery.toLowerCase();
            return m.name.toLowerCase().contains(query) ||
                m.email.toLowerCase().contains(query) ||
                m.role.displayName.toLowerCase().contains(query);
          }).toList();

          // Grouping members by role
          final Map<UserRole, List<UserModel>> groupedMembers = {};
          for (final role in UserRole.values) {
            final roleMembers = filteredMembers.where((m) => m.role == role).toList();
            if (roleMembers.isNotEmpty) {
              groupedMembers[role] = roleMembers;
            }
          }

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              // Search Field
              TextField(
                controller: _memberSearchController,
                decoration: InputDecoration(
                  labelText: 'Search Members',
                  hintText: 'Search by name, email, or role...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _memberSearchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _memberSearchController.clear();
                              _memberSearchQuery = '';
                            });
                          },
                        )
                      : null,
                ),
                onChanged: (val) {
                  setState(() {
                    _memberSearchQuery = val;
                  });
                },
              ),
              const SizedBox(height: 20),

              if (filteredMembers.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40.0),
                    child: Column(
                      children: [
                        Icon(Icons.people_outline, size: 64, color: theme.colorScheme.outline),
                        const SizedBox(height: 16),
                        Text(
                          'No team members found',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...groupedMembers.entries.map((entry) {
                  final role = entry.key;
                  final roleMembers = entry.value;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 12.0, left: 4.0),
                        child: Text(
                          '${role.displayName.toUpperCase()}S (${roleMembers.length})',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      ...roleMembers.map((member) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 1.5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ExpansionTile(
                            leading: CircleAvatar(
                              backgroundColor: member.active
                                  ? theme.colorScheme.primaryContainer
                                  : theme.colorScheme.errorContainer,
                              foregroundColor: member.active
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onErrorContainer,
                              child: Text(
                                member.name.isNotEmpty ? member.name[0].toUpperCase() : 'U',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(
                              member.name.isNotEmpty ? member.name : 'Pending Setup',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(member.email),
                            trailing: Container(
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
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Divider(),
                                    const SizedBox(height: 8),
                                    _buildDetailRow('Email', member.email, theme),
                                    _buildDetailRow('Role', member.role.displayName, theme),
                                    _buildDetailRow('Onboarding Status', member.onboarded ? 'Completed' : 'Pending Name Setup', theme),
                                    
                                    // Sites mapping
                                    sitesAsync.when(
                                      data: (sites) {
                                        final assigned = sites
                                            .where((s) => member.assignedSiteIds.contains(s.id))
                                            .map((s) => s.name as String)
                                            .toList();
                                        return _buildDetailRow(
                                          'Assigned Sites',
                                          assigned.isNotEmpty ? assigned.join(', ') : 'None',
                                          theme,
                                        );
                                      },
                                      loading: () => const LinearProgressIndicator(),
                                      error: (err, _) => const Text('Error loading sites metadata'),
                                    ),

                                    // Audit Trail Fields
                                    if (member.createdAt != null)
                                      _buildDetailRow('Created At', dateFormatter.format(member.createdAt!), theme),
                                    if (member.updatedAt != null)
                                      _buildDetailRow('Last Updated', dateFormatter.format(member.updatedAt!), theme),
                                    if (member.copyWith().toFirestore()['updatedBy'] != null)
                                      _buildDetailRow('Updated By (UID)', member.copyWith().toFirestore()['updatedBy'] ?? 'N/A', theme),

                                    const SizedBox(height: 16),
                                    
                                    // Action buttons (restricted for Owner role on themselves)
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        if (member.role == UserRole.owner) ...[
                                          const Icon(Icons.security, size: 16, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          const Text(
                                            'Owner privileges are immutable',
                                            style: TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic),
                                          ),
                                        ] else ...[
                                          // Assign Sites (Supervisor only)
                                          if (member.role == UserRole.supervisor)
                                            TextButton.icon(
                                              onPressed: () => _showSitesDialog(context, ref, member, sitesAsync.value ?? []),
                                              icon: const Icon(Icons.add_location_alt_outlined, size: 16),
                                              label: const Text('Sites'),
                                            ),
                                          const SizedBox(width: 8),
                                          
                                          // Change Role
                                          TextButton.icon(
                                            onPressed: () => _showRoleDialog(context, ref, member),
                                            icon: const Icon(Icons.admin_panel_settings_outlined, size: 16),
                                            label: const Text('Change Role'),
                                          ),
                                          const SizedBox(width: 8),

                                          // Enable/Disable toggle
                                          OutlinedButton.icon(
                                            onPressed: () => _confirmToggleActive(context, ref, member),
                                            icon: Icon(
                                              member.active ? Icons.block : Icons.check_circle_outline,
                                              size: 16,
                                            ),
                                            label: Text(member.active ? 'Disable' : 'Enable'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: member.active ? Colors.red : Colors.green,
                                              side: BorderSide(color: member.active ? Colors.red : Colors.green),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  );
                }),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading team: $err')),
      ),
    );
  }

  // --- Invitations Tab ---
  Widget _buildInvitationsTab(
    BuildContext context,
    String companyId,
    AsyncValue<List<InvitationModel>> invitationsAsync,
    AsyncValue<List<dynamic>> sitesAsync,
  ) {
    final theme = Theme.of(context);
    final dateFormatter = intl.DateFormat('dd MMM yyyy, hh:mm a');

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(invitationsProvider);
      },
      child: invitationsAsync.when(
        data: (invitations) {
          // Client-side filtering by search query & status choice chip
          final filteredInvitations = invitations.where((invite) {
            final query = _inviteSearchQuery.toLowerCase();
            final matchesQuery = invite.email.toLowerCase().contains(query) ||
                invite.role.displayName.toLowerCase().contains(query);
            final matchesStatus = _selectedInviteStatus == null || invite.status == _selectedInviteStatus;
            return matchesQuery && matchesStatus;
          }).toList();

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              // Search Input
              TextField(
                controller: _inviteSearchController,
                decoration: InputDecoration(
                  labelText: 'Search Invitations',
                  hintText: 'Search by email or role...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _inviteSearchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _inviteSearchController.clear();
                              _inviteSearchQuery = '';
                            });
                          },
                        )
                      : null,
                ),
                onChanged: (val) {
                  setState(() {
                    _inviteSearchQuery = val;
                  });
                },
              ),
              const SizedBox(height: 12),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: _selectedInviteStatus == null,
                      onSelected: (val) {
                        setState(() {
                          _selectedInviteStatus = null;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    ...InvitationStatus.values.map((status) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(status.displayName),
                          selected: _selectedInviteStatus == status,
                          selectedColor: _getInvitationColor(status).withValues(alpha: 0.25),
                          checkmarkColor: _getInvitationColor(status),
                          onSelected: (val) {
                            setState(() {
                              _selectedInviteStatus = val ? status : null;
                            });
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (filteredInvitations.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40.0),
                    child: Column(
                      children: [
                        Icon(Icons.mail_outline, size: 64, color: theme.colorScheme.outline),
                        const SizedBox(height: 16),
                        Text(
                          'No invitations found',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...filteredInvitations.map((invite) {
                  final badgeColor = _getInvitationColor(invite.status).withValues(alpha: 0.1);
                  final textColor = _getInvitationColor(invite.status);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 1.5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.secondaryContainer,
                        foregroundColor: theme.colorScheme.onSecondaryContainer,
                        child: const Icon(Icons.mail_outline),
                      ),
                      title: Text(
                        invite.email,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('Role: ${invite.role.displayName}'),
                      trailing: Container(
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
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Divider(),
                              const SizedBox(height: 8),
                              _buildDetailRow('Email', invite.email, theme),
                              _buildDetailRow('Role', invite.role.displayName, theme),
                              
                              sitesAsync.when(
                                data: (sites) {
                                  final assigned = sites
                                      .where((s) => invite.assignedSiteIds.contains(s.id))
                                      .map((s) => s.name as String)
                                      .toList();
                                  return _buildDetailRow(
                                    'Assigned Sites',
                                    assigned.isNotEmpty ? assigned.join(', ') : 'None',
                                    theme,
                                  );
                                },
                                loading: () => const LinearProgressIndicator(),
                                error: (err, _) => const Text('Error loading sites'),
                              ),

                              _buildDetailRow('Created Date', dateFormatter.format(invite.createdAt), theme),
                              _buildDetailRow('Expiry Date', dateFormatter.format(invite.expiresAt), theme),
                              _buildDetailRow('Invited By (UID)', invite.invitedBy, theme),
                              _buildDetailRow('Resend Count', invite.resendCount.toString(), theme),
                              
                              if (invite.lastSentAt != null)
                                _buildDetailRow('Last Sent', dateFormatter.format(invite.lastSentAt!), theme),
                              if (invite.revokedBy != null)
                                _buildDetailRow('Revoked By (UID)', invite.revokedBy!, theme),
                              if (invite.revokedAt != null)
                                _buildDetailRow('Revoked At', dateFormatter.format(invite.revokedAt!), theme),

                              if (invite.status == InvitationStatus.pending || invite.status == InvitationStatus.expired) ...[
                                const Divider(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (invite.status == InvitationStatus.pending) ...[
                                      OutlinedButton.icon(
                                        onPressed: () => _confirmRevokeInvitation(context, ref, companyId, invite),
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
                                      onPressed: () => _confirmResendInvitation(context, ref, companyId, invite),
                                      icon: const Icon(Icons.send, size: 16),
                                      label: const Text('Resend'),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading invitations: $err')),
      ),
    );
  }

  // --- Helpers ---
  Color _getInvitationColor(InvitationStatus status) {
    switch (status) {
      case InvitationStatus.pending:
        return Colors.orange;
      case InvitationStatus.accepted:
        return Colors.green;
      case InvitationStatus.revoked:
        return Colors.red;
      case InvitationStatus.expired:
        return Colors.grey;
    }
  }

  Widget _buildDetailRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.outline,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // --- Action Dialogs ---
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
    final inviteFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Invite Team Member'),
              content: Form(
                key: inviteFormKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                          hintText: 'user@example.com',
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email is required';
                          }
                          final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                          if (!emailRegex.hasMatch(value.trim())) {
                            return 'Enter a valid email address';
                          }
                          final normalized = normalizeEmail(value.trim());
                          if (currentMembers != null && currentMembers.any((m) => normalizeEmail(m.email) == normalized)) {
                            return 'User is already a member of this company';
                          }
                          if (currentInvitations != null && currentInvitations.any((invite) =>
                              normalizeEmail(invite.email) == normalized &&
                              (invite.status == InvitationStatus.pending ||
                               invite.status == InvitationStatus.accepted))) {
                            return 'Active/accepted invitation already exists';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<UserRole>(
                        initialValue: selectedRole,
                        decoration: const InputDecoration(labelText: 'Role'),
                        items: const [
                          DropdownMenuItem(value: UserRole.supervisor, child: Text('Supervisor')),
                          DropdownMenuItem(value: UserRole.admin, child: Text('Admin')),
                          DropdownMenuItem(value: UserRole.partner, child: Text('Partner')),
                        ],
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
                            children: [
                              ...sites.map((site) {
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
                              }),
                              // Custom FormField validation for Supervisor role requiring at least one site
                              if (selectedRole == UserRole.supervisor && selectedSiteIds.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.only(top: 8.0),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'At least one site must be assigned to a supervisor.',
                                      style: TextStyle(color: Colors.red, fontSize: 12),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                        loading: () => const CircularProgressIndicator(),
                        error: (err, _) => const Text('Error loading sites'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!inviteFormKey.currentState!.validate()) return;
                    if (selectedRole == UserRole.supervisor && selectedSiteIds.isEmpty) return;

                    try {
                      final repo = ref.read(teamManagementRepositoryProvider);
                      final currentUser = ref.read(currentUserProvider);

                      await repo.inviteSupervisor(
                        tenantId: companyId,
                        companyId: companyId,
                        email: normalizeEmail(emailController.text.trim()),
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
            children: [
              UserRole.supervisor,
              UserRole.admin,
              UserRole.partner,
            ].map((role) {
              return ListTile(
                title: Text(role.displayName),
                trailing: member.role == role ? const Icon(Icons.check, color: Colors.blue) : null,
                onTap: () async {
                  // Confirm dialog within onTap
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Confirm Role Change'),
                      content: Text('Are you sure you want to change role of ${member.name} to ${role.displayName}?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                        ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
                      ],
                    ),
                  );

                  if (confirmed == true && context.mounted) {
                    final repo = ref.read(teamManagementRepositoryProvider);
                    final currentUser = ref.read(currentUserProvider);

                    await repo.updateRole(
                      userId: member.uid,
                      role: role,
                      updatedBy: currentUser?.uid ?? 'unknown',
                    );

                    if (context.mounted) {
                      Navigator.pop(context); // close role dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Updated role to ${role.displayName}')),
                      );
                    }
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
                  children: [
                    ...allSites.map((site) {
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
                    }),
                    if (tempSiteIds.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Note: Site supervisors should be assigned to at least one site.',
                          style: TextStyle(color: Colors.orange, fontSize: 12),
                        ),
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
                    // Confirm change
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Save Assignments'),
                        content: const Text('Do you want to update site assignments?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
                        ],
                      ),
                    );

                    if (confirmed == true && context.mounted) {
                      final repo = ref.read(teamManagementRepositoryProvider);
                      final currentUser = ref.read(currentUserProvider);

                      await repo.assignSites(
                        userId: member.uid,
                        siteIds: tempSiteIds,
                        updatedBy: currentUser?.uid ?? 'unknown',
                      );

                      if (context.mounted) {
                        Navigator.pop(context); // close sites dialog
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Site assignments updated')),
                        );
                      }
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

  Future<void> _confirmToggleActive(BuildContext context, WidgetRef ref, UserModel member) async {
    final currentUser = ref.read(currentUserProvider);
    if (member.uid == currentUser?.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot deactivate your own account.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(member.active ? 'Disable User' : 'Enable User'),
        content: Text('Are you sure you want to ${member.active ? 'disable' : 'enable'} ${member.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: member.active ? Colors.red : Colors.green),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final repo = ref.read(teamManagementRepositoryProvider);
      if (member.active) {
        await repo.disableUser(userId: member.uid, updatedBy: currentUser?.uid ?? 'unknown');
      } else {
        await repo.enableUser(userId: member.uid, updatedBy: currentUser?.uid ?? 'unknown');
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User status updated for ${member.name}')),
        );
      }
    }
  }

  Future<void> _confirmRevokeInvitation(
    BuildContext context,
    WidgetRef ref,
    String companyId,
    InvitationModel invite,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke Invitation'),
        content: Text('Are you sure you want to revoke the invitation sent to ${invite.email}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
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
    }
  }

  Future<void> _confirmResendInvitation(
    BuildContext context,
    WidgetRef ref,
    String companyId,
    InvitationModel invite,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resend Invitation'),
        content: Text('Do you want to resend the invitation to ${invite.email}? This will extend the expiry date by 14 days.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Resend'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final repo = ref.read(invitationRepositoryProvider);
      final currentUser = ref.read(currentUserProvider);

      await repo.resendInvitation(
        companyId: companyId,
        invitationId: invite.id,
        resentBy: currentUser?.uid ?? 'unknown',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation resent (expiration updated)')),
        );
      }
    }
  }
}
