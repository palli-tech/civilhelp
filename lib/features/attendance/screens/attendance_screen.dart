import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:civilhelp/app/theme.dart';
import 'package:civilhelp/core/enums/user_role.dart';
import 'package:civilhelp/core/enums/labour_status.dart';
import 'package:civilhelp/core/providers/user_role_provider.dart';
import 'package:civilhelp/shared/layouts/app_scaffold.dart';
import 'package:civilhelp/shared/widgets/module_header.dart';
import 'package:civilhelp/shared/widgets/module_empty_state.dart';
import 'package:civilhelp/shared/widgets/premium_module_card.dart';

import '../../sites/providers/site_provider.dart';
import '../../labour/data/models/labour_model.dart';
import '../models/attendance_model.dart';
import '../providers/attendance_register_provider.dart';
import '../services/attendance_export_service.dart';

List<DateTime> _getDaysInWeek(DateTime date) {
  final monday = date.subtract(Duration(days: date.weekday - 1));
  return List.generate(7, (index) => monday.add(Duration(days: index)));
}

String _getLabourTrade(LabourModel worker) {
  if (worker.dailyWage >= 800) {
    return 'Skilled Mason';
  } else if (worker.dailyWage >= 600) {
    return 'Tile Layer';
  } else {
    return 'Helper';
  }
}

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(userRoleProvider);
    final isOwnerOrAdmin = role == UserRole.owner || role == UserRole.admin;

    // Listen to all sites & register state
    final allSitesAsync = ref.watch(sitesStreamProvider);
    final registerState = ref.watch(attendanceRegisterStateProvider);
    final matrix = ref.watch(attendanceRegisterMatrixProvider);
    final companySettings = ref.watch(companySettingsProvider).value ?? {};
    final limitDays = companySettings['attendanceBackdateLimitDays'] as int? ?? 7;

    // Filter sites based on supervisor assignment
    final assignedSiteIds = ref.watch(assignedSiteIdsProvider);
    final sitesAsync = role == UserRole.supervisor
        ? allSitesAsync.whenData((sites) =>
            sites.where((s) => assignedSiteIds.contains(s.id)).toList())
        : allSitesAsync;

    final dates = matrix.dates;
    final workers = matrix.workers;

    // Daily view marked counts
    final focusedDateStr = formatDateKey(registerState.selectedDate);
    final totalActive = workers.length;
    int markedCount = 0;
    for (final worker in workers) {
      if (matrix.grid[worker.id]?.containsKey(focusedDateStr) ?? false) {
        markedCount++;
      }
    }

    final today = DateTime.now();
    final isFutureDate = DateTime(registerState.selectedDate.year, registerState.selectedDate.month, registerState.selectedDate.day)
        .isAfter(DateTime(today.year, today.month, today.day));

    final completion = matrix.completions[focusedDateStr];
    final isCompleted = (completion?['status'] as String? ?? 'draft') == 'completed';

    final useCompactRow = workers.length > 15;
    final isDaily = registerState.viewMode == RegisterViewMode.daily;

    return AppScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: sitesAsync.when(
              data: (sites) {
                if (sites.isEmpty) {
                  return const ModuleEmptyState(
                    icon: Icons.store_mall_directory_outlined,
                    title: 'No Sites Assigned',
                    description: 'Please assign sites to this account or create a site to manage attendance.',
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCompactHeader(context, ref, sites, registerState, matrix, markedCount, totalActive),
                    const SizedBox(height: 4),

                    if (registerState.selectedSiteId != null) ...[
                      // If no workers found
                      if (workers.isEmpty)
                        Expanded(
                          child: ModuleEmptyState(
                            icon: Icons.people_outline,
                            title: 'No active workers found for this site.',
                            description: 'Add workers to start tracking attendance.',
                            ctaLabel: 'Add Worker',
                            onCta: () {
                              Navigator.of(context).pushNamed('/add-labour');
                            },
                          ),
                        )
                      else ...[
                        // View mode content selector
                        Expanded(
                          child: Column(
                            children: [
                              Expanded(
                                child: registerState.viewMode == RegisterViewMode.daily
                                    ? _buildDailyViewBody(
                                        context,
                                        ref,
                                        registerState,
                                        matrix,
                                        isOwnerOrAdmin,
                                        isCompleted,
                                        isFutureDate,
                                        markedCount,
                                        totalActive,
                                        useCompactRow,
                                        limitDays,
                                        role,
                                      )
                                    : _buildMusterGrid(
                                        context,
                                        ref,
                                        registerState,
                                        matrix,
                                        limitDays,
                                        role,
                                      ),
                              ),
                              if (registerState.viewMode == RegisterViewMode.daily)
                                _buildStickyCommandCenter(
                                  context,
                                  ref,
                                  registerState,
                                  matrix,
                                  isOwnerOrAdmin,
                                  isCompleted,
                                  isFutureDate,
                                  markedCount,
                                  totalActive,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ] else
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Please select a site to view the register.',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                      ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Text('Error loading sites: $err', style: const TextStyle(color: Colors.red)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewModeDropdown(
    BuildContext context,
    WidgetRef ref,
    AttendanceRegisterState state,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.outlineVariant, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<RegisterViewMode>(
          value: state.viewMode,
          isDense: true,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: context.colors.onSurface,
          ),
          icon: Icon(Icons.keyboard_arrow_down, size: 18, color: context.colors.onSurfaceVariant),
          items: [
            DropdownMenuItem(
              value: RegisterViewMode.daily,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.today, size: 14, color: context.colors.primary),
                  const SizedBox(width: 6),
                  const Text('Daily'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: RegisterViewMode.weekly,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.view_week, size: 14, color: context.colors.primary),
                  const SizedBox(width: 6),
                  const Text('Weekly'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: RegisterViewMode.monthly,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_month, size: 14, color: context.colors.primary),
                  const SizedBox(width: 6),
                  const Text('Monthly'),
                ],
              ),
            ),
          ],
          onChanged: (val) {
            if (val != null) {
              ref.read(attendanceRegisterStateProvider.notifier).setViewMode(val);
            }
          },
        ),
      ),
    );
  }

  Widget _buildCompactHeader(
    BuildContext context,
    WidgetRef ref,
    List<dynamic> sites,
    AttendanceRegisterState state,
    RegisterMatrixData matrix,
    int markedCount,
    int totalActive,
  ) {
    final activeSiteId = state.selectedSiteId;
    final activeSite = sites.where((s) => s.id == activeSiteId).firstOrNull;
    final activeSiteName = activeSite?.name ?? 'Select Site';

    final today = DateTime.now();
    final isToday = DateUtils.isSameDay(state.selectedDate, today);

    // Filter status counts
    int presentCount = 0;
    int halfDayCount = 0;
    int absentCount = 0;

    final focusedDateStr = formatDateKey(state.selectedDate);
    for (final worker in matrix.workers) {
      final log = matrix.grid[worker.id]?[focusedDateStr];
      if (log != null) {
        final statusLower = log.status.toLowerCase();
        if (statusLower == 'present') {
          presentCount++;
        } else if (statusLower == 'half day' || statusLower.contains('half')) {
          halfDayCount++;
        } else if (statusLower == 'absent') {
          absentCount++;
        }
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLowest,
        border: Border(bottom: BorderSide(color: context.colors.outlineVariant, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Site Dropdown/Text Selector
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (MediaQuery.of(context).size.width < 600) ...[
                      IconButton(
                        icon: Icon(
                          Icons.menu,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          Scaffold.of(context).openDrawer();
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: _buildSiteSelectorButton(context, ref, sites, state, activeSiteName, markedCount),
                    ),
                  ],
                ),
              ),
              // Search & Export buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.search,
                      size: 20,
                      color: state.searchKeyword.isNotEmpty ? context.colors.primary : null,
                    ),
                    tooltip: 'Search Workers',
                    onPressed: () => _showSearchDialog(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf, size: 20),
                    tooltip: 'Export PDF',
                    onPressed: activeSiteId == null ? null : () => _handlePdfExport(context, ref, matrix),
                  ),
                  IconButton(
                    icon: const Icon(Icons.table_view_outlined, size: 20),
                    tooltip: 'Export XLSX',
                    onPressed: activeSiteId == null ? null : () => _handleXlsxExport(context, ref, matrix),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Date picker switch
              _buildCompactDatePicker(context, ref, state, isToday),
              // View mode selector dropdown
              _buildViewModeDropdown(context, ref, state),
            ],
          ),
          if (activeSiteId != null && matrix.workers.isNotEmpty) ...[
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.only(left: 4.0),
              child: Text(
                '🟢 $markedCount/${matrix.workers.length} Marked (P:$presentCount HD:$halfDayCount A:$absentCount)',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSiteSelectorButton(
    BuildContext context,
    WidgetRef ref,
    List<dynamic> sites,
    AttendanceRegisterState state,
    String activeSiteName,
    int markedCount,
  ) {
    return InkWell(
      onTap: () {
        if (markedCount > 0) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Change Site?'),
              content: const Text(
                'You have marked attendance records for this site. Changing sites will switch your view context. Do you want to proceed?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showSiteSelectionList(context, ref, sites, state);
                  },
                  child: const Text('Proceed'),
                ),
              ],
            ),
          );
        } else {
          _showSiteSelectionList(context, ref, sites, state);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                activeSiteName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 20),
          ],
        ),
      ),
    );
  }

  void _showSiteSelectionList(
    BuildContext context,
    WidgetRef ref,
    List<dynamic> sites,
    AttendanceRegisterState state,
  ) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select Site'),
        children: sites.map((site) {
          final isSelected = site.id == state.selectedSiteId;
          return SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              ref.read(attendanceRegisterStateProvider.notifier).selectSite(site.id);
            },
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    site.name,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? context.colors.primary : null,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check, size: 16, color: context.colors.primary),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCompactDatePicker(
    BuildContext context,
    WidgetRef ref,
    AttendanceRegisterState state,
    bool isToday,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () {
            final notifier = ref.read(attendanceRegisterStateProvider.notifier);
            final nextDate = state.viewMode == RegisterViewMode.daily
                ? state.selectedDate.subtract(const Duration(days: 1))
                : (state.viewMode == RegisterViewMode.weekly
                    ? state.selectedDate.subtract(const Duration(days: 7))
                    : DateTime(state.selectedDate.year, state.selectedDate.month - 1, 1));
            notifier.selectDate(nextDate);
          },
        ),
        const SizedBox(width: 4),
        InkWell(
          onTap: () async {
            final selected = await showDatePicker(
              context: context,
              initialDate: state.selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (selected != null) {
              ref.read(attendanceRegisterStateProvider.notifier).selectDate(selected);
            }
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isToday && state.viewMode == RegisterViewMode.daily)
                Text(
                  'Today, ',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: context.colors.primary,
                  ),
                ),
              Text(
                state.viewMode == RegisterViewMode.daily
                    ? DateFormat('dd MMM yyyy').format(state.selectedDate)
                    : (state.viewMode == RegisterViewMode.weekly
                        ? 'Week of ${DateFormat('dd MMM').format(_getDaysInWeek(state.selectedDate).first)}'
                        : DateFormat('MMMM yyyy').format(state.selectedDate)),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(Icons.chevron_right, size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () {
            final notifier = ref.read(attendanceRegisterStateProvider.notifier);
            final nextDate = state.viewMode == RegisterViewMode.daily
                ? state.selectedDate.add(const Duration(days: 1))
                : (state.viewMode == RegisterViewMode.weekly
                    ? state.selectedDate.add(const Duration(days: 7))
                    : DateTime(state.selectedDate.year, state.selectedDate.month + 1, 1));
            if (nextDate.isBefore(DateTime.now().add(const Duration(days: 365)))) {
              notifier.selectDate(nextDate);
            }
          },
        ),
      ],
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final state = ref.watch(attendanceRegisterStateProvider);
        _searchController.text = state.searchKeyword;
        return AlertDialog(
          title: const Text('Search Worker', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          content: TextField(
            controller: _searchController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Enter name...',
              prefixIcon: Icon(Icons.search),
              isDense: true,
            ),
            onChanged: (val) {
              ref.read(attendanceRegisterStateProvider.notifier).setSearchKeyword(val);
            },
          ),
          actions: [
            if (state.searchKeyword.isNotEmpty)
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  ref.read(attendanceRegisterStateProvider.notifier).setSearchKeyword('');
                  Navigator.pop(context);
                },
                child: const Text('Clear'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Dismiss'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStickyCommandCenter(
    BuildContext context,
    WidgetRef ref,
    AttendanceRegisterState state,
    RegisterMatrixData matrix,
    bool isOwnerOrAdmin,
    bool isCompleted,
    bool isFutureDate,
    int markedCount,
    int totalActive,
  ) {
    final completion = matrix.completions[formatDateKey(state.selectedDate)];
    final completedBy = completion?['completedBy'] as String? ?? 'Supervisor';
    final completedAt = completion?['completedAt'] != null
        ? (completion?['completedAt'] as Timestamp).toDate()
        : null;

    final completerName = completedBy.length > 15 ? '${completedBy.substring(0, 15)}...' : completedBy;
    final timestampStr = completedAt != null
        ? DateFormat('dd MMM yyyy • hh:mm a').format(completedAt)
        : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer,
        border: Border(
          top: BorderSide(color: context.colors.outlineVariant, width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isFutureDate)
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_clock_outlined, color: Colors.red, size: 18),
                SizedBox(width: 8),
                Text(
                  'Attendance cannot be marked for future dates.',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            )
          else if (isCompleted)
            Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Color(0xFF16A34A), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '✓ Attendance Completed',
                        style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      Text(
                        'Completed by $completerName • $timestampStr',
                        style: const TextStyle(color: Colors.grey, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                if (isOwnerOrAdmin)
                  TextButton.icon(
                    onPressed: () => _confirmReopenDay(context, ref, state.selectedDate),
                    icon: const Icon(Icons.lock_open, size: 14, color: Colors.red),
                    label: const Text('Reopen Day', style: TextStyle(color: Colors.red, fontSize: 10)),
                  ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$markedCount / $totalActive Marked',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.done_all, size: 12),
                  label: const Text('Mark All Present', style: TextStyle(fontSize: 10)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF16A34A),
                    side: const BorderSide(color: Color(0xFF16A34A)),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  onPressed: () => _confirmMarkAllPresent(context, ref, state.selectedDate),
                ),
                const SizedBox(width: 6),
                ElevatedButton.icon(
                  icon: const Icon(Icons.lock_outline, size: 12),
                  label: const Text('Complete Day', style: TextStyle(fontSize: 10)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  onPressed: () => _confirmCompleteDay(context, ref, state.selectedDate),
                ),
              ],
            ),
        ],
      ),
    );
  }



  Widget _buildDailyViewBody(
    BuildContext context,
    WidgetRef ref,
    AttendanceRegisterState state,
    RegisterMatrixData matrix,
    bool isOwnerOrAdmin,
    bool isCompleted,
    bool isFutureDate,
    int markedCount,
    int totalActive,
    bool useCompactRow,
    int limitDays,
    UserRole role,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: matrix.workers.length,
              itemBuilder: (context, index) {
                final worker = matrix.workers[index];
                final log = matrix.grid[worker.id]?[formatDateKey(state.selectedDate)];
                final isCellUnlocked = matrix.unlockedCells[log?.id ?? ''] ?? false;
                final date = state.selectedDate;

                // Check frozen limit
                final limitDate = DateTime.now().subtract(Duration(days: limitDays));
                final isFrozen = date.isBefore(limitDate);

                if (useCompactRow) {
                  return CompactWorkerRow(
                    worker: worker,
                    date: date,
                    log: log,
                    isCompleted: isCompleted,
                    isFutureDate: isFutureDate,
                    isFrozen: isFrozen,
                    isUnlocked: isCellUnlocked,
                    role: role,
                    onStatusChanged: (status, hours, muster) async {
                      await ref.read(attendanceRegisterStateProvider.notifier).updateAttendanceCell(
                            labour: worker,
                            date: date,
                            status: status,
                            hoursWorked: hours,
                            musterQuantity: muster,
                            existingRecord: log,
                          );
                    },
                  );
                } else {
                  return DailyWorkerCard(
                    worker: worker,
                    date: date,
                    log: log,
                    isCompleted: isCompleted,
                    isFutureDate: isFutureDate,
                    isFrozen: isFrozen,
                    isUnlocked: isCellUnlocked,
                    role: role,
                    onStatusChanged: (status, hours, muster) async {
                      await ref.read(attendanceRegisterStateProvider.notifier).updateAttendanceCell(
                            labour: worker,
                            date: date,
                            status: status,
                            hoursWorked: hours,
                            musterQuantity: muster,
                            existingRecord: log,
                          );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMusterGrid(
    BuildContext context,
    WidgetRef ref,
    AttendanceRegisterState state,
    RegisterMatrixData matrix,
    int limitDays,
    UserRole role,
  ) {
    const double colWidth = 60.0;
    const double rowHeight = 52.0;
    const double footerHeight = 64.0;
    const double stickyNameWidth = 140.0;

    final dates = matrix.dates;
    final workers = matrix.workers;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: context.colors.outlineVariant),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sticky Left Sidebar (Corner + Worker Names + Label Footer)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Corner Cell
                          Container(
                            width: stickyNameWidth,
                            height: rowHeight,
                            color: context.colors.surfaceContainerHighest,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'Labourers',
                              style: context.text.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Divider(height: 1, color: context.colors.outlineVariant),
                          // Worker names
                          ...List.generate(workers.length, (index) {
                            final w = workers[index];
                            final isInactive = w.status == LabourStatus.inactive;
                            return Container(
                              width: stickyNameWidth,
                              height: rowHeight,
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: index.isEven
                                    ? context.colors.surface
                                    : context.colors.surfaceContainerLowest,
                                border: Border(
                                  bottom: BorderSide(color: context.colors.outlineVariant, width: 0.5),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    w.fullName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: isInactive ? Colors.grey : context.colors.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (isInactive)
                                    const Text(
                                      'Exited/Inactive',
                                      style: TextStyle(fontSize: 9, color: Colors.red, fontWeight: FontWeight.bold),
                                    ),
                                ],
                              ),
                            );
                          }),
                          // Daily Presence Footer label
                          Container(
                            width: stickyNameWidth,
                            height: footerHeight,
                            color: context.colors.surfaceContainerHighest,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'Daily Totals',
                              style: context.text.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      // Divider line
                      Container(width: 1, height: (workers.length + 1) * rowHeight + footerHeight, color: context.colors.outlineVariant),
                      // Horizontal Scrolling Matrix Grid
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Date Headers Row
                              Row(
                                children: [
                                  ...dates.map((d) {
                                    final dateKey = formatDateKey(d);
                                    final isFocused = DateUtils.isSameDay(state.selectedDate, d);
                                    final comp = matrix.completions[dateKey];
                                    final isDayComp = (comp?['status'] as String? ?? 'draft') == 'completed';

                                    return InkWell(
                                      onTap: () {
                                        ref.read(attendanceRegisterStateProvider.notifier).selectDate(d);
                                      },
                                      child: Container(
                                        width: colWidth,
                                        height: rowHeight,
                                        decoration: BoxDecoration(
                                          color: isFocused
                                              ? context.colors.primaryContainer
                                              : context.colors.surfaceContainerHighest,
                                          border: Border(
                                            right: BorderSide(color: context.colors.outlineVariant, width: 0.5),
                                            bottom: BorderSide(
                                              color: isFocused ? context.colors.primary : Colors.transparent,
                                              width: isFocused ? 2.0 : 0.0,
                                            ),
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              DateFormat('E').format(d),
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: isFocused ? context.colors.primary : context.colors.onSurfaceVariant,
                                              ),
                                            ),
                                            Text(
                                              '${d.day}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: isFocused ? context.colors.primary : context.colors.onSurface,
                                              ),
                                            ),
                                            if (isDayComp)
                                              const Icon(Icons.lock, size: 8, color: Colors.green),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                  // Totals Headers columns
                                  _buildTotalHeaderCell(colWidth, rowHeight, context, 'P'),
                                  _buildTotalHeaderCell(colWidth, rowHeight, context, 'HD'),
                                  _buildTotalHeaderCell(colWidth, rowHeight, context, 'A'),
                                  _buildTotalHeaderCell(colWidth, rowHeight, context, 'OT'),
                                  _buildTotalHeaderCell(colWidth + 15, rowHeight, context, 'Earned'),
                                ],
                              ),
                              Divider(height: 1, color: context.colors.outlineVariant),
                              // Grid Cells Rows
                              ...List.generate(workers.length, (rowIndex) {
                                final worker = workers[rowIndex];
                                final totals = matrix.workerTotals[worker.id];

                                return Row(
                                  children: [
                                    ...dates.map((d) {
                                      final dateKey = formatDateKey(d);
                                      final log = matrix.grid[worker.id]?[dateKey];
                                      final isFocused = DateUtils.isSameDay(state.selectedDate, d);
                                      final unlocked = matrix.unlockedCells[log?.id ?? ''] ?? false;

                                      return Container(
                                        width: colWidth,
                                        height: rowHeight,
                                        decoration: BoxDecoration(
                                          color: isFocused
                                              ? context.colors.primaryContainer.withOpacity(0.05)
                                              : (rowIndex.isEven ? context.colors.surface : context.colors.surfaceContainerLowest),
                                          border: Border(
                                            right: BorderSide(color: context.colors.outlineVariant, width: 0.5),
                                            bottom: BorderSide(color: context.colors.outlineVariant, width: 0.5),
                                          ),
                                        ),
                                        child: _buildGridCell(
                                          context,
                                          ref,
                                          worker,
                                          d,
                                          log,
                                          state,
                                          limitDays,
                                          unlocked,
                                          role,
                                          matrix,
                                        ),
                                      );
                                    }),
                                    // Worker totals columns
                                    _buildTotalCell(colWidth, rowHeight, rowIndex, context, '${totals?.presentCount ?? 0}'),
                                    _buildTotalCell(colWidth, rowHeight, rowIndex, context, '${totals?.halfDayCount ?? 0}'),
                                    _buildTotalCell(colWidth, rowHeight, rowIndex, context, '${totals?.absentCount ?? 0}'),
                                    _buildTotalCell(colWidth, rowHeight, rowIndex, context, totals != null ? totals.overtimeHours.toStringAsFixed(1) : '0.0'),
                                    _buildTotalCell(colWidth + 15, rowHeight, rowIndex, context, totals != null ? 'Rs.${totals.totalEarned.toStringAsFixed(0)}' : '0', isEarned: true),
                                  ],
                                );
                              }),
                              // Summary footer Row
                              Row(
                                children: [
                                  ...dates.map((d) {
                                    final dateKey = formatDateKey(d);
                                    final p = matrix.dailyPresentCount[dateKey] ?? 0;
                                    final hd = matrix.dailyHalfDayCount[dateKey] ?? 0;
                                    final a = matrix.dailyAbsentCount[dateKey] ?? 0;
                                    final ot = matrix.dailyOvertimeHours[dateKey] ?? 0.0;

                                    return Container(
                                      width: colWidth,
                                      height: footerHeight,
                                      decoration: BoxDecoration(
                                        color: context.colors.surfaceContainerHighest,
                                        border: Border(
                                          right: BorderSide(color: context.colors.outlineVariant, width: 0.5),
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text('P:$p', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.green)),
                                              const SizedBox(width: 4),
                                              Text('HD:$hd', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.orange)),
                                            ],
                                          ),
                                          Text('A:$a', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.red)),
                                          if (ot > 0)
                                            Text('+${ot.toStringAsFixed(0)}h OT', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.indigo)),
                                        ],
                                      ),
                                    );
                                  }),
                                  // empty blocks under row totals
                                  ...List.generate(5, (i) => Container(
                                    width: i == 4 ? colWidth + 15 : colWidth,
                                    height: footerHeight,
                                    decoration: BoxDecoration(
                                      color: context.colors.surfaceContainerHighest,
                                      border: Border(right: BorderSide(color: context.colors.outlineVariant, width: 0.5)),
                                    ),
                                  )),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalHeaderCell(double w, double h, BuildContext context, String label) {
    return Container(
      width: w,
      height: h,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest,
        border: Border(right: BorderSide(color: context.colors.outlineVariant, width: 0.5)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey),
      ),
    );
  }

  Widget _buildTotalCell(double w, double h, int rowIndex, BuildContext context, String val, {bool isEarned = false}) {
    return Container(
      width: w,
      height: h,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: rowIndex.isEven ? context.colors.surface : context.colors.surfaceContainerLowest,
        border: Border(
          right: BorderSide(color: context.colors.outlineVariant, width: 0.5),
          bottom: BorderSide(color: context.colors.outlineVariant, width: 0.5),
        ),
      ),
      child: Text(
        val,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isEarned ? FontWeight.bold : FontWeight.normal,
          color: isEarned ? context.colors.primary : context.colors.onSurface,
        ),
      ),
    );
  }

  Widget _buildGridCell(
    BuildContext context,
    WidgetRef ref,
    LabourModel worker,
    DateTime date,
    AttendanceModel? log,
    AttendanceRegisterState state,
    int limitDays,
    bool unlocked,
    UserRole role,
    RegisterMatrixData matrix,
  ) {
    // Check frozen limit
    final limitDate = DateTime.now().subtract(Duration(days: limitDays));
    final isFrozen = date.isBefore(limitDate);

    // Site completion lock check
    final dateStr = formatDateKey(date);
    final comp = matrix.completions[dateStr];
    final isCompleted = (comp?['status'] as String? ?? 'draft') == 'completed';

    Widget displayWidget = _getCellDisplay(context, log);

    // If day is completed: show check and locks
    if (isCompleted) {
      return Center(
        child: Tooltip(
          message: 'Attendance completed and locked',
          child: Stack(
            alignment: Alignment.center,
            children: [
              Opacity(opacity: 0.5, child: displayWidget),
              const Icon(Icons.lock_outline, size: 12, color: Colors.green),
            ],
          ),
        ),
      );
    }

    if (isFrozen && !unlocked) {
      final isOwnerOrAdmin = role == UserRole.owner || role == UserRole.admin;
      return Center(
        child: Tooltip(
          message: isOwnerOrAdmin ? 'Frozen. Click to unlock (Owner/Admin)' : 'Frozen & locked',
          child: InkWell(
            onTap: isOwnerOrAdmin
                ? () => _showManualUnlockPopup(context, ref, worker, date)
                : null,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Opacity(opacity: 0.4, child: displayWidget),
                Icon(Icons.ac_unit, size: 12, color: context.colors.primary),
              ],
            ),
          ),
        ),
      );
    }

    // Weekly/Monthly grid cells are interactive tap editors
    return InkWell(
      onTapDown: (details) => _showCellEditorPopup(
        context,
        ref,
        details.globalPosition,
        worker,
        date,
        log,
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: context.colors.primary.withOpacity(0.3), width: 0.5),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(child: displayWidget),
      ),
    );
  }

  Widget _getCellDisplay(BuildContext context, AttendanceModel? log) {
    if (log == null) {
      return const Text('-', style: TextStyle(color: Colors.grey));
    }
    final statusLower = log.status.toLowerCase();
    if (statusLower == 'present') {
      final otStr = log.hoursWorked > 8.0 ? ' (+${(log.hoursWorked - 8).toStringAsFixed(0)}h)' : '';
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('✓', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
          if (otStr.isNotEmpty)
            Text(otStr, style: const TextStyle(color: Colors.indigo, fontSize: 8, fontWeight: FontWeight.bold)),
        ],
      );
    } else if (statusLower == 'half day' || statusLower == 'half-day') {
      final otStr = log.hoursWorked > 4.0 ? ' (+${(log.hoursWorked - 4).toStringAsFixed(0)}h)' : '';
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('◑', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 14)),
          if (otStr.isNotEmpty)
            Text(otStr, style: const TextStyle(color: Colors.indigo, fontSize: 8, fontWeight: FontWeight.bold)),
        ],
      );
    } else if (statusLower == 'absent') {
      return const Text('✕', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14));
    }
    return const Text('-', style: TextStyle(color: Colors.grey));
  }

  // Confirm Scoped Mark All Present
  void _confirmMarkAllPresent(BuildContext context, WidgetRef ref, DateTime date) {
    final formattedDate = DateFormat('dd/MM/yyyy').format(date);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark All Present'),
        content: Text('Are you sure you want to mark all active labourers as Present on $formattedDate? This skips already logged labourers.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(attendanceRegisterStateProvider.notifier).markAllPresentForDate(date);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All active workers marked Present.')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Mark Present'),
          ),
        ],
      ),
    );
  }

  // Confirm Complete Day Register
  void _confirmCompleteDay(BuildContext context, WidgetRef ref, DateTime date) {
    final formattedDate = DateFormat('dd/MM/yyyy').format(date);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Day'),
        content: Text('Lock attendance register for $formattedDate? Supervisors will not be able to edit cells after locking.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(attendanceRegisterStateProvider.notifier).completeSiteAttendance(date);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Attendance locked for this day.')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error locking day: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Lock & Complete'),
          ),
        ],
      ),
    );
  }

  // Confirm Reopen Day Register
  void _confirmReopenDay(BuildContext context, WidgetRef ref, DateTime date) {
    final formattedDate = DateFormat('dd/MM/yyyy').format(date);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reopen Day'),
        content: Text('Reopen attendance logs for $formattedDate? This restores write access for supervisors.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(attendanceRegisterStateProvider.notifier).reopenSiteAttendance(date);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Attendance reopened.')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error reopening day: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Reopen Register'),
          ),
        ],
      ),
    );
  }

  // Cell overlay editor popup
  void _showCellEditorPopup(
    BuildContext context,
    WidgetRef ref,
    Offset position,
    LabourModel worker,
    DateTime date,
    AttendanceModel? log,
  ) {
    String currentStatus = log?.status ?? 'Present';
    double currentHours = log?.hoursWorked ?? 8.0;
    
    double normalHours(String stat) {
      final s = stat.toLowerCase();
      if (s == 'present') return 8.0;
      if (s == 'half day' || s == 'half-day') return 4.0;
      return 0.0;
    }

    final double startNormal = normalHours(currentStatus);
    double otHours = currentHours > startNormal ? currentHours - startNormal : 0.0;

    showMenu<Map<String, dynamic>>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx + 40, position.dy + 40),
      items: [
        PopupMenuItem<Map<String, dynamic>>(
          enabled: false,
          child: StatefulBuilder(
            builder: (context, setPopupState) {
              final normH = normalHours(currentStatus);
              final totalH = normH + otHours;

              Widget statusButton(String status, Color color) {
                final isSel = currentStatus == status;
                return ChoiceChip(
                  label: Text(status.split(' ').first, style: const TextStyle(fontSize: 10)),
                  selected: isSel,
                  selectedColor: color.withOpacity(0.2),
                  onSelected: (_) {
                    setPopupState(() {
                      currentStatus = status;
                      if (status == 'Absent') {
                        otHours = 0.0;
                      }
                    });
                  },
                );
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Log for ${worker.fullName}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  Text(
                    'Date: ${DateFormat('dd MMM').format(date)}',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      statusButton('Present', Colors.green),
                      statusButton('Half Day', Colors.orange),
                      statusButton('Absent', Colors.red),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (currentStatus.toLowerCase() != 'absent') ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('OT Hours:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, size: 20),
                              onPressed: otHours > 0
                                  ? () => setPopupState(() => otHours = (otHours - 0.5).clamp(0.0, 16.0))
                                  : null,
                            ),
                            Text('${otHours.toStringAsFixed(1)}h', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, size: 20),
                              onPressed: () => setPopupState(() => otHours = (otHours + 0.5).clamp(0.0, 16.0)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Text(
                      'Total Hours: ${totalH.toStringAsFixed(1)}h',
                      style: const TextStyle(fontSize: 10, color: Colors.blueGrey, fontStyle: FontStyle.italic),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (log != null) ...[
                    OutlinedButton.icon(
                      icon: const Icon(Icons.delete_outline, size: 14, color: Colors.red),
                      label: const Text('Delete Log', style: TextStyle(fontSize: 11, color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: () {
                        Navigator.pop(context, {'status': 'deleted'});
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        child: const Text('Cancel', style: TextStyle(fontSize: 11)),
                        onPressed: () => Navigator.pop(context),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        ),
                        child: const Text('Save', style: TextStyle(fontSize: 11)),
                        onPressed: () {
                          Navigator.pop(context, {
                            'status': currentStatus,
                            'hoursWorked': totalH,
                            'musterQuantity': currentStatus.toLowerCase() == 'present'
                                ? 1.0
                                : (currentStatus.toLowerCase().contains('half') ? 0.5 : 0.0),
                          });
                        },
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ],
    ).then((result) async {
      if (result != null) {
        final status = result['status'] as String;
        try {
          if (status == 'deleted') {
            await ref.read(attendanceRegisterStateProvider.notifier).updateAttendanceCell(
                  labour: worker,
                  date: date,
                  status: 'deleted',
                  hoursWorked: 0,
                  musterQuantity: 0,
                  existingRecord: log,
                );
          } else {
            await ref.read(attendanceRegisterStateProvider.notifier).updateAttendanceCell(
                  labour: worker,
                  date: date,
                  status: status,
                  hoursWorked: result['hoursWorked'] as double,
                  musterQuantity: result['musterQuantity'] as double,
                  existingRecord: log,
                );
          }
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Attendance cell updated successfully.')),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Update failed: $e'), backgroundColor: Colors.red),
            );
          }
        }
      }
    });
  }

  void _showManualUnlockPopup(
    BuildContext context,
    WidgetRef ref,
    LabourModel worker,
    DateTime date,
  ) {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unlock Attendance Log'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Enter a reason to temporarily unlock this older frozen log for ${worker.fullName} on ${DateFormat('dd/MM/yyyy').format(date)}:'),
              const SizedBox(height: 12),
              TextFormField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Unlock Reason',
                  hintText: 'e.g., Backdated payroll adjustments',
                  isDense: true,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Reason is required';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(context);
              try {
                await ref.read(attendanceRegisterStateProvider.notifier).unlockFrozenCell(
                      labour: worker,
                      date: date,
                      reason: reasonController.text.trim(),
                    );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cell unlocked. Try editing the cell again.')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Unlock failed: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Unlock Log'),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePdfExport(BuildContext context, WidgetRef ref, RegisterMatrixData matrix) async {
    final state = ref.read(attendanceRegisterStateProvider);
    final sites = ref.read(sitesStreamProvider).value ?? [];
    final siteName = sites.where((s) => s.id == state.selectedSiteId).firstOrNull?.name ?? '';

    try {
      await ref.read(attendanceExportServiceProvider).exportAttendancePdf(
            siteName: siteName,
            dates: matrix.dates,
            workers: matrix.workers,
            grid: matrix.grid,
            dailyPresentCount: matrix.dailyPresentCount,
            dailyHalfDayCount: matrix.dailyHalfDayCount,
            dailyAbsentCount: matrix.dailyAbsentCount,
            dailyOvertimeHours: matrix.dailyOvertimeHours,
            workerTotals: matrix.workerTotals,
          );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF Export failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleXlsxExport(BuildContext context, WidgetRef ref, RegisterMatrixData matrix) async {
    final state = ref.read(attendanceRegisterStateProvider);
    final sites = ref.read(sitesStreamProvider).value ?? [];
    final siteName = sites.where((s) => s.id == state.selectedSiteId).firstOrNull?.name ?? '';

    try {
      await ref.read(attendanceExportServiceProvider).exportAttendanceXlsx(
            siteName: siteName,
            dates: matrix.dates,
            workers: matrix.workers,
            grid: matrix.grid,
            dailyPresentCount: matrix.dailyPresentCount,
            dailyHalfDayCount: matrix.dailyHalfDayCount,
            dailyAbsentCount: matrix.dailyAbsentCount,
            dailyOvertimeHours: matrix.dailyOvertimeHours,
            workerTotals: matrix.workerTotals,
          );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('XLSX Export failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

// Daily worker card (Regular mode)
class DailyWorkerCard extends StatefulWidget {
  final LabourModel worker;
  final DateTime date;
  final AttendanceModel? log;
  final bool isCompleted;
  final bool isFutureDate;
  final bool isFrozen;
  final bool isUnlocked;
  final UserRole role;
  final Function(String status, double hoursWorked, double musterQuantity) onStatusChanged;

  const DailyWorkerCard({
    super.key,
    required this.worker,
    required this.date,
    required this.log,
    required this.isCompleted,
    required this.isFutureDate,
    required this.isFrozen,
    required this.isUnlocked,
    required this.role,
    required this.onStatusChanged,
  });

  @override
  State<DailyWorkerCard> createState() => _DailyWorkerCardState();
}

class _DailyWorkerCardState extends State<DailyWorkerCard> {
  bool _showSaved = false;
  Timer? _savedTimer;

  @override
  void dispose() {
    _savedTimer?.cancel();
    super.dispose();
  }

  void _triggerSaved() {
    _savedTimer?.cancel();
    setState(() {
      _showSaved = true;
    });
    _savedTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _showSaved = false;
        });
      }
    });
  }

  void _showOtPopup(BuildContext context, double currentOt) {
    double tempOt = currentOt;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setPopupState) {
            return AlertDialog(
              title: const Text('Overtime Hours', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, size: 24),
                        onPressed: tempOt > 0
                            ? () {
                                setPopupState(() {
                                  tempOt = (tempOt - 0.5).clamp(0.0, 16.0);
                                });
                              }
                            : null,
                      ),
                      Text(
                        tempOt.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, size: 24),
                        onPressed: tempOt < 16.0
                            ? () {
                                setPopupState(() {
                                  tempOt = (tempOt + 0.5).clamp(0.0, 16.0);
                                });
                              }
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [1.0, 2.0, 4.0].map((preset) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                          ),
                          onPressed: () {
                            setPopupState(() {
                              tempOt = preset;
                            });
                          },
                          child: Text('+${preset.toStringAsFixed(0)}'),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onStatusChanged('Present', 8.0 + tempOt, 1.0);
                    _triggerSaved();
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

  Widget _buildOtChip(BuildContext context, double otHours, bool isEditable) {
    final otText = otHours > 0 ? '+${otHours.toStringAsFixed(1)}' : '+0';
    final hasOt = otHours > 0;
    return InkWell(
      onTap: isEditable ? () => _showOtPopup(context, otHours) : null,
      child: Opacity(
        opacity: isEditable ? 1.0 : 0.5,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: hasOt ? Colors.indigo.withOpacity(0.12) : const Color(0xFF9CA3AF).withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: hasOt ? Colors.indigo : const Color(0xFF9CA3AF),
              width: 1.0,
            ),
          ),
          child: Text(
            'OT $otText',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: hasOt ? Colors.indigo : const Color(0xFF9CA3AF),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentStatus = widget.log?.status ?? '';
    final currentHours = widget.log?.hoursWorked ?? 8.0;

    double normalHours(String stat) {
      final s = stat.toLowerCase();
      if (s == 'present') return 8.0;
      if (s == 'half day' || s == 'half-day') return 4.0;
      return 0.0;
    }

    final double startNormal = normalHours(currentStatus);
    double otHours = currentHours > startNormal ? currentHours - startNormal : 0.0;

    final isPresent = currentStatus.toLowerCase() == 'present';
    final isHalfDay = currentStatus.toLowerCase() == 'half day' || currentStatus.toLowerCase() == 'half-day';
    final isAbsent = currentStatus.toLowerCase() == 'absent';

    final isEditable = !widget.isCompleted && !widget.isFutureDate && (!widget.isFrozen || widget.isUnlocked);

    Widget compactStatusButton({
      required IconData icon,
      required Color activeColor,
      required bool isSelected,
      required VoidCallback onTap,
      required String tooltip,
    }) {
      return Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: isEditable ? onTap : null,
          child: Opacity(
            opacity: isEditable ? 1.0 : 0.5,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? activeColor.withOpacity(0.15) : Colors.transparent,
                border: Border.all(
                  color: isSelected ? activeColor : const Color(0xFF9CA3AF).withOpacity(0.3),
                  width: isSelected ? 1.5 : 1.0,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 16,
                color: isSelected ? activeColor : const Color(0xFF9CA3AF),
              ),
            ),
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: context.colors.outlineVariant, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: context.colors.primaryContainer,
              child: Text(
                widget.worker.fullName.substring(0, widget.worker.fullName.length > 1 ? 2 : 1).toUpperCase(),
                style: TextStyle(color: context.colors.onPrimaryContainer, fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.worker.fullName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getLabourTrade(widget.worker),
                    style: TextStyle(fontSize: 10, color: context.colors.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isPresent || isHalfDay) ...[
              _buildOtChip(context, otHours, isEditable),
              const SizedBox(width: 8),
            ],
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                compactStatusButton(
                  icon: Icons.check,
                  activeColor: const Color(0xFF16A34A),
                  isSelected: isPresent,
                  tooltip: 'Present',
                  onTap: () {
                    widget.onStatusChanged('Present', 8.0, 1.0);
                    _triggerSaved();
                  },
                ),
                const SizedBox(width: 4),
                compactStatusButton(
                  icon: Icons.pie_chart_outline,
                  activeColor: const Color(0xFFF59E0B),
                  isSelected: isHalfDay,
                  tooltip: 'Half Day',
                  onTap: () {
                    widget.onStatusChanged('Half Day', 4.0, 0.5);
                    _triggerSaved();
                  },
                ),
                const SizedBox(width: 4),
                compactStatusButton(
                  icon: Icons.close,
                  activeColor: const Color(0xFFEF4444),
                  isSelected: isAbsent,
                  tooltip: 'Absent',
                  onTap: () {
                    widget.onStatusChanged('Absent', 0.0, 0.0);
                    _triggerSaved();
                  },
                ),
              ],
            ),
            if (_showSaved) ...[
              const SizedBox(width: 6),
              const Icon(Icons.check, color: Colors.green, size: 14),
            ],
          ],
        ),
      ),
    );
  }
}

// Daily worker card (Compact row mode)
class CompactWorkerRow extends StatefulWidget {
  final LabourModel worker;
  final DateTime date;
  final AttendanceModel? log;
  final bool isCompleted;
  final bool isFutureDate;
  final bool isFrozen;
  final bool isUnlocked;
  final UserRole role;
  final Function(String status, double hoursWorked, double musterQuantity) onStatusChanged;

  const CompactWorkerRow({
    super.key,
    required this.worker,
    required this.date,
    required this.log,
    required this.isCompleted,
    required this.isFutureDate,
    required this.isFrozen,
    required this.isUnlocked,
    required this.role,
    required this.onStatusChanged,
  });

  @override
  State<CompactWorkerRow> createState() => _CompactWorkerRowState();
}

class _CompactWorkerRowState extends State<CompactWorkerRow> {
  bool _showSaved = false;
  Timer? _savedTimer;

  @override
  void dispose() {
    _savedTimer?.cancel();
    super.dispose();
  }

  void _triggerSaved() {
    _savedTimer?.cancel();
    setState(() {
      _showSaved = true;
    });
    _savedTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _showSaved = false;
        });
      }
    });
  }

  void _showOtPopup(BuildContext context, double currentOt) {
    double tempOt = currentOt;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setPopupState) {
            return AlertDialog(
              title: const Text('Overtime Hours', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, size: 24),
                        onPressed: tempOt > 0
                            ? () {
                                setPopupState(() {
                                  tempOt = (tempOt - 0.5).clamp(0.0, 16.0);
                                });
                              }
                            : null,
                      ),
                      Text(
                        tempOt.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, size: 24),
                        onPressed: tempOt < 16.0
                            ? () {
                                setPopupState(() {
                                  tempOt = (tempOt + 0.5).clamp(0.0, 16.0);
                                });
                              }
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [1.0, 2.0, 4.0].map((preset) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                          ),
                          onPressed: () {
                            setPopupState(() {
                              tempOt = preset;
                            });
                          },
                          child: Text('+${preset.toStringAsFixed(0)}'),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onStatusChanged('Present', 8.0 + tempOt, 1.0);
                    _triggerSaved();
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

  Widget _buildOtChip(BuildContext context, double otHours, bool isEditable) {
    final otText = otHours > 0 ? '+${otHours.toStringAsFixed(1)}' : '+0';
    final hasOt = otHours > 0;
    return InkWell(
      onTap: isEditable ? () => _showOtPopup(context, otHours) : null,
      child: Opacity(
        opacity: isEditable ? 1.0 : 0.5,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: hasOt ? Colors.indigo.withOpacity(0.12) : const Color(0xFF9CA3AF).withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: hasOt ? Colors.indigo : const Color(0xFF9CA3AF),
              width: 1.0,
            ),
          ),
          child: Text(
            'OT $otText',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: hasOt ? Colors.indigo : const Color(0xFF9CA3AF),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentStatus = widget.log?.status ?? '';
    final currentHours = widget.log?.hoursWorked ?? 8.0;

    double normalHours(String stat) {
      final s = stat.toLowerCase();
      if (s == 'present') return 8.0;
      if (s == 'half day' || s == 'half-day') return 4.0;
      return 0.0;
    }

    final double startNormal = normalHours(currentStatus);
    double otHours = currentHours > startNormal ? currentHours - startNormal : 0.0;

    final isPresent = currentStatus.toLowerCase() == 'present';
    final isHalfDay = currentStatus.toLowerCase() == 'half day' || currentStatus.toLowerCase() == 'half-day';
    final isAbsent = currentStatus.toLowerCase() == 'absent';

    final isEditable = !widget.isCompleted && !widget.isFutureDate && (!widget.isFrozen || widget.isUnlocked);

    Widget compactStatusButton({
      required IconData icon,
      required Color activeColor,
      required bool isSelected,
      required VoidCallback onTap,
      required String tooltip,
    }) {
      return Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: isEditable ? onTap : null,
          child: Opacity(
            opacity: isEditable ? 1.0 : 0.5,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? activeColor.withOpacity(0.15) : Colors.transparent,
                border: Border.all(
                  color: isSelected ? activeColor : const Color(0xFF9CA3AF).withOpacity(0.3),
                  width: isSelected ? 1.5 : 1.0,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 16,
                color: isSelected ? activeColor : const Color(0xFF9CA3AF),
              ),
            ),
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: context.colors.outlineVariant, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: context.colors.primaryContainer,
              child: Text(
                widget.worker.fullName.substring(0, widget.worker.fullName.length > 1 ? 2 : 1).toUpperCase(),
                style: TextStyle(color: context.colors.onPrimaryContainer, fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.worker.fullName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getLabourTrade(widget.worker),
                    style: TextStyle(fontSize: 10, color: context.colors.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isPresent || isHalfDay) ...[
              _buildOtChip(context, otHours, isEditable),
              const SizedBox(width: 8),
            ],
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                compactStatusButton(
                  icon: Icons.check,
                  activeColor: const Color(0xFF16A34A),
                  isSelected: isPresent,
                  tooltip: 'Present',
                  onTap: () {
                    widget.onStatusChanged('Present', 8.0, 1.0);
                    _triggerSaved();
                  },
                ),
                const SizedBox(width: 4),
                compactStatusButton(
                  icon: Icons.pie_chart_outline,
                  activeColor: const Color(0xFFF59E0B),
                  isSelected: isHalfDay,
                  tooltip: 'Half Day',
                  onTap: () {
                    widget.onStatusChanged('Half Day', 4.0, 0.5);
                    _triggerSaved();
                  },
                ),
                const SizedBox(width: 4),
                compactStatusButton(
                  icon: Icons.close,
                  activeColor: const Color(0xFFEF4444),
                  isSelected: isAbsent,
                  tooltip: 'Absent',
                  onTap: () {
                    widget.onStatusChanged('Absent', 0.0, 0.0);
                    _triggerSaved();
                  },
                ),
              ],
            ),
            if (_showSaved) ...[
              const SizedBox(width: 6),
              const Icon(Icons.check, color: Colors.green, size: 14),
            ],
          ],
        ),
      ),
    );
  }
}
