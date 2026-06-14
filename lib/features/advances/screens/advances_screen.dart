import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:civilhelp/app/theme.dart';
import 'package:civilhelp/shared/layouts/app_scaffold.dart';
import 'package:civilhelp/shared/widgets/civil_empty_state.dart';
import 'package:civilhelp/shared/widgets/metric_card.dart';
import 'package:civilhelp/shared/widgets/status_chip.dart';
import 'package:civilhelp/features/labour/presentation/providers/labour_provider.dart';
import '../models/advance_model.dart';
import '../providers/advances_providers.dart';
import '../../labour/data/models/labour_model.dart';

class AdvancesScreen extends ConsumerStatefulWidget {
  const AdvancesScreen({super.key});

  @override
  ConsumerState<AdvancesScreen> createState() => _AdvancesScreenState();
}

class _AdvancesScreenState extends ConsumerState<AdvancesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final advancesAsync = ref.watch(advancesListStreamProvider);
    final labourAsync = ref.watch(labourStreamProvider);

    return AppScaffold(
      appBar: AppBar(
        title: const Text(
          'Advances Ledger',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                context.customColors.advance,
                context.customColors.advance.withValues(alpha: 0.85),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Outstanding'),
            Tab(text: 'Recovered'),
            Tab(text: 'Worker Ledger'),
          ],
        ),
      ),
      fab: FloatingActionButton.extended(
        onPressed: () => _showNewAdvanceDialog(context, ref, labourAsync),
        label: const Text('Issue Advance', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add),
        backgroundColor: context.customColors.advance,
        foregroundColor: Colors.white,
      ),
      child: TabBarView(
        controller: _tabController,
        children: [
          _OutstandingTab(advancesAsync: advancesAsync, onIssue: () => _showNewAdvanceDialog(context, ref, labourAsync)),
          _RecoveredTab(advancesAsync: advancesAsync),
          _WorkerLedgerTab(advancesAsync: advancesAsync, labourAsync: labourAsync),
        ],
      ),
    );
  }

  // ─── Issue Advance Dialog ─────────────────────────────────────────────────

  void _showNewAdvanceDialog(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<LabourModel>> labourAsync,
  ) {
    final formKey = GlobalKey<FormState>();
    String? selectedLabourId;
    String? selectedLabourName;
    double amount = 0.0;
    String description = '';
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (dialogCtx, setState) {
            return AlertDialog(
              title: Text(
                'Issue New Advance',
                style: TextStyle(fontWeight: FontWeight.bold, color: context.customColors.advance),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        dropdownColor: context.colors.surface,
                        decoration: const InputDecoration(
                          labelText: 'Labour / Worker',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        items: labourAsync.when(
                          data: (list) => list
                              .where((l) => l.status.name == 'active')
                              .map((l) => DropdownMenuItem(
                                    value: l.id,
                                    child: Text(l.fullName),
                                  ))
                              .toList(),
                          loading: () => [],
                          error: (_, e) => [],
                        ),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              selectedLabourId = val;
                              selectedLabourName = labourAsync.value
                                  ?.firstWhere((l) => l.id == val)
                                  .fullName;
                            });
                          }
                        },
                        validator: (val) => val == null ? 'Select a worker' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Advance Amount (₹)',
                          prefixIcon: Icon(Icons.currency_rupee),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          final amt = double.tryParse(val ?? '');
                          if (amt == null || amt <= 0) return 'Enter a valid amount';
                          return null;
                        },
                        onSaved: (val) {
                          if (val != null) amount = double.parse(val);
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Description / Purpose',
                          prefixIcon: Icon(Icons.notes),
                        ),
                        validator: (val) =>
                            val == null || val.isEmpty ? 'Enter description' : null,
                        onSaved: (val) {
                          if (val != null) description = val;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.event, size: 18, color: context.colors.outline),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat('dd MMM yyyy').format(selectedDate),
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: dialogCtx,
                                initialDate: selectedDate,
                                firstDate: DateTime.now().subtract(const Duration(days: 90)),
                                lastDate: DateTime.now().add(const Duration(days: 30)),
                              );
                              if (picked != null) {
                                setState(() => selectedDate = picked);
                              }
                            },
                            child: const Text('Change Date'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: Text('Cancel', style: TextStyle(color: context.colors.outline)),
                ),
                FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    formKey.currentState!.save();
                    Navigator.pop(dialogCtx);

                    try {
                      await ref.read(createAdvanceProvider((
                        labourId: selectedLabourId!,
                        labourName: selectedLabourName ?? 'Unknown',
                        amount: amount,
                        description: description,
                        date: selectedDate,
                      )).future);

                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Advance issued successfully.')),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to issue advance: $e'),
                          backgroundColor: context.colors.error,
                        ),
                      );
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: context.customColors.advance,
                  ),
                  child: const Text('Issue Advance'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ─── Outstanding Tab ──────────────────────────────────────────────────────────

class _OutstandingTab extends StatelessWidget {
  final AsyncValue<List<AdvanceModel>> advancesAsync;
  final VoidCallback onIssue;

  const _OutstandingTab({required this.advancesAsync, required this.onIssue});

  @override
  Widget build(BuildContext context) {
    return advancesAsync.when(
      data: (advances) {
        final outstanding = advances.where((a) => a.status != 'recovered').toList();
        final currencyFmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

        final totalOutstanding = outstanding.fold<double>(
          0.0, (acc, a) => acc + a.remainingAmount);
        final workersWithAdvances = outstanding.map((a) => a.labourId).toSet().length;
        final pendingCount = outstanding.where((a) => a.status == 'pending').length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Summary Metric Bar ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.screenPadding,
                AppSpacing.screenPadding,
                0,
              ),
              child: Row(
                children: [
                  MetricCard(
                    label: 'Total Outstanding',
                    value: currencyFmt.format(totalOutstanding),
                    icon: Icons.account_balance_wallet_outlined,
                    color: context.customColors.warning,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  MetricCard(
                    label: 'Workers',
                    value: '$workersWithAdvances',
                    icon: Icons.people_outline,
                    color: context.customColors.info,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  MetricCard(
                    label: 'Pending',
                    value: '$pendingCount',
                    icon: Icons.pending_outlined,
                    color: context.colors.outline,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.listGap),
            // ── List ──────────────────────────────────────────────────────
            Expanded(
              child: outstanding.isEmpty
                  ? CivilEmptyState(
                      icon: Icons.check_circle_outline,
                      title: 'No Outstanding Advances',
                      description: 'All advances have been fully recovered. Great work!',
                      iconColor: context.customColors.success,
                      ctaLabel: 'Issue Advance',
                      onCta: onIssue,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screenPadding,
                        AppSpacing.xs,
                        AppSpacing.screenPadding,
                        100,
                      ),
                      itemCount: outstanding.length,
                      itemBuilder: (context, index) {
                        return _OutstandingCard(advance: outstanding[index]);
                      },
                    ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _OutstandingCard extends StatelessWidget {
  final AdvanceModel advance;
  const _OutstandingCard({required this.advance});

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final recoveryPct = advance.amount > 0
        ? (advance.recoveredAmount / advance.amount).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: context.surfaceGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.colors.outline.withValues(alpha: context.isDarkMode ? 0.15 : 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDarkMode ? 0.2 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name + Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    advance.labourName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                StatusChip(status: advance.status),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              advance.description,
              style: TextStyle(color: context.colors.onSurfaceVariant, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 14),
            // Outstanding amount — DOMINANT
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  currencyFmt.format(advance.remainingAmount),
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: context.customColors.warning,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'outstanding',
                  style: TextStyle(fontSize: 13, color: context.colors.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Recovery progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: recoveryPct,
                backgroundColor: context.colors.surfaceVariant,
                color: context.customColors.success,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 6),
            // Secondary info row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Issued: ${currencyFmt.format(advance.amount)}',
                  style: TextStyle(fontSize: 12, color: context.colors.onSurfaceVariant),
                ),
                Text(
                  'Recovered: ${currencyFmt.format(advance.recoveredAmount)} (${(recoveryPct * 100).toStringAsFixed(0)}%)',
                  style: TextStyle(fontSize: 12, color: context.customColors.success),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Issued on ${DateFormat('dd MMM yyyy').format(advance.date)}',
              style: TextStyle(fontSize: 11, color: context.colors.onSurfaceVariant.withValues(alpha: 0.6)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Recovered Tab ────────────────────────────────────────────────────────────

class _RecoveredTab extends StatelessWidget {
  final AsyncValue<List<AdvanceModel>> advancesAsync;
  const _RecoveredTab({required this.advancesAsync});

  @override
  Widget build(BuildContext context) {
    return advancesAsync.when(
      data: (advances) {
        final recovered = advances.where((a) => a.status == 'recovered').toList();
        final currencyFmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
        final totalRecovered = recovered.fold<double>(0.0, (acc, a) => acc + a.recoveredAmount);

        return Column(
          children: [
            if (recovered.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    MetricCard(
                      label: 'Total Recovered',
                      value: currencyFmt.format(totalRecovered),
                      icon: Icons.task_alt_outlined,
                      color: context.customColors.success,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    MetricCard(
                      label: 'Workers',
                      value: '${recovered.map((a) => a.labourId).toSet().length}',
                      icon: Icons.people_outline,
                      color: context.customColors.success,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Expanded(
              child: recovered.isEmpty
                  ? const CivilEmptyState(
                      icon: Icons.offline_pin_outlined,
                      title: 'No Recovered Advances',
                      description: 'Advances fully repaid during payroll settlement appear here.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: recovered.length,
                      itemBuilder: (context, index) {
                        return _RecoveredCard(advance: recovered[index]);
                      },
                    ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _RecoveredCard extends StatelessWidget {
  final AdvanceModel advance;
  const _RecoveredCard({required this.advance});

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        gradient: context.surfaceGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.colors.outline.withValues(alpha: context.isDarkMode ? 0.15 : 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDarkMode ? 0.2 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: context.customColors.successContainer,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(Icons.check_circle_outline,
                  color: context.customColors.success, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    advance.labourName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    advance.description,
                    style: TextStyle(color: context.colors.onSurfaceVariant, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Issued: ${DateFormat('dd MMM yyyy').format(advance.date)}',
                    style: TextStyle(fontSize: 11, color: context.colors.onSurfaceVariant.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currencyFmt.format(advance.amount),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: context.customColors.success,
                  ),
                ),
                const SizedBox(height: 4),
                const StatusChip(status: 'recovered', fontSize: 10),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Worker Ledger Tab ────────────────────────────────────────────────────────

class _WorkerLedgerTab extends StatelessWidget {
  final AsyncValue<List<AdvanceModel>> advancesAsync;
  final AsyncValue<List<LabourModel>> labourAsync;

  const _WorkerLedgerTab({required this.advancesAsync, required this.labourAsync});

  @override
  Widget build(BuildContext context) {
    return advancesAsync.when(
      data: (advances) => labourAsync.when(
        data: (labours) {
          final Map<String, List<AdvanceModel>> workerAdvances = {};
          for (final adv in advances) {
            workerAdvances.putIfAbsent(adv.labourId, () => []).add(adv);
          }

          final workers = labours
              .where((l) => workerAdvances.containsKey(l.id) || l.status.name == 'active')
              .toList();

          if (workers.isEmpty) {
            return const CivilEmptyState(
              icon: Icons.people_outline,
              title: 'No Worker Data',
              description: 'Active workers with advance history will appear here.',
            );
          }

          // Sort: workers with outstanding balance first
          workers.sort((a, b) {
            final aBalance = (workerAdvances[a.id] ?? [])
                .fold<double>(0.0, (acc, adv) => acc + adv.remainingAmount);
            final bBalance = (workerAdvances[b.id] ?? [])
                .fold<double>(0.0, (acc, adv) => acc + adv.remainingAmount);
            return bBalance.compareTo(aBalance);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            itemCount: workers.length,
            itemBuilder: (context, index) {
              final labour = workers[index];
              final list = workerAdvances[labour.id] ?? [];

              double totalIssued = list.fold(0.0, (acc, a) => acc + a.amount);
              double totalRecovered = list.fold(0.0, (acc, a) => acc + a.recoveredAmount);
              double outstanding = totalIssued - totalRecovered;

              return _WorkerLedgerCard(
                name: labour.fullName,
                outstanding: outstanding,
                totalIssued: totalIssued,
                totalRecovered: totalRecovered,
                advanceCount: list.length,
                onTap: () => _showWorkerLedgerDetails(context, labour.fullName, list),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  void _showWorkerLedgerDetails(
      BuildContext context, String workerName, List<AdvanceModel> list) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            '$workerName\'s Advance History',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: context.customColors.advance),
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: SizedBox(
            width: double.maxFinite,
            child: list.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No advance history.'),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final adv = list[index];
                      final currencyFmt =
                          NumberFormat.currency(symbol: '₹', decimalDigits: 0);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(adv.description,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14)),
                                  const SizedBox(height: 2),
                                  Text(
                                    DateFormat('dd MMM yyyy').format(adv.date),
                                    style: TextStyle(
                                        fontSize: 12, color: context.colors.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                  Text(
                                    currencyFmt.format(adv.remainingAmount),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: adv.status == 'recovered'
                                          ? context.customColors.success
                                          : context.customColors.warning,
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                StatusChip(status: adv.status, fontSize: 10),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close',
                  style: TextStyle(color: context.customColors.advance)),
            ),
          ],
        );
      },
    );
  }
}

class _WorkerLedgerCard extends StatelessWidget {
  final String name;
  final double outstanding;
  final double totalIssued;
  final double totalRecovered;
  final int advanceCount;
  final VoidCallback onTap;

  const _WorkerLedgerCard({
    required this.name,
    required this.outstanding,
    required this.totalIssued,
    required this.totalRecovered,
    required this.advanceCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final hasOutstanding = outstanding > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: context.surfaceGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasOutstanding
              ? context.customColors.warning.withValues(alpha: context.isDarkMode ? 0.35 : 0.2)
              : context.colors.outline.withValues(alpha: context.isDarkMode ? 0.15 : 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDarkMode ? 0.2 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: hasOutstanding
                      ? context.customColors.warningContainer
                      : context.customColors.successContainer,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: hasOutstanding
                          ? context.customColors.warning
                          : context.customColors.success,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Worker info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '$advanceCount advance${advanceCount != 1 ? 's' : ''}',
                            style:
                                TextStyle(fontSize: 12, color: context.colors.onSurfaceVariant),
                          ),
                          const SizedBox(width: 8),
                          Text('·', style: TextStyle(color: context.colors.onSurfaceVariant.withValues(alpha: 0.6))),
                          const SizedBox(width: 8),
                          Text(
                            'Issued: ${currencyFmt.format(totalIssued)}',
                            style:
                                TextStyle(fontSize: 12, color: context.colors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Outstanding balance — dominant
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currencyFmt.format(outstanding),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: hasOutstanding
                            ? context.customColors.warning
                            : context.customColors.success,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'outstanding',
                      style: TextStyle(fontSize: 11, color: context.colors.onSurfaceVariant.withValues(alpha: 0.6)),
                    ),
                    const SizedBox(height: 4),
                    Icon(Icons.chevron_right, color: context.colors.onSurfaceVariant.withValues(alpha: 0.6)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
