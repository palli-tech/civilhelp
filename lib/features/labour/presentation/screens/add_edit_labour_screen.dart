import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:civilhelp/app/theme.dart';
import 'package:civilhelp/shared/layouts/app_scaffold.dart';
import 'package:civilhelp/features/sites/providers/site_provider.dart';
import 'package:civilhelp/features/labour/presentation/widgets/labour_form.dart';
import 'package:civilhelp/features/labour/presentation/providers/labour_provider.dart';

class AddEditLabourScreen extends ConsumerStatefulWidget {
  final String? labourId;

  const AddEditLabourScreen({
    super.key,
    this.labourId,
  });

  @override
  ConsumerState<AddEditLabourScreen> createState() => _AddEditLabourScreenState();
}

class _AddEditLabourScreenState extends ConsumerState<AddEditLabourScreen> {
  late final GlobalKey<LabourFormState> _formKey;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<LabourFormState>();
  }

  Future<void> _handleSubmit() async {
    try {
      setState(() => _isLoading = true);

      final formState = _formKey.currentState;
      if (formState == null || !formState.validate()) return;
      if (widget.labourId == null) {
        // Create mode
        await ref.read(
          createLabourProvider((
            formState.fullName,
            formState.phoneNumber,
            formState.aadhaarNumber,
            formState.dailyWage,
            formState.assignedSiteId,
            formState.assignedSiteName,
            formState.joinedDate,
            formState.status.toString().split('.').last,
          )).future,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Labour record created successfully')),
          );
          Navigator.of(context).pop();
        }
      } else {
        // Edit mode
        await ref.read(
          updateLabourProvider((
            widget.labourId!,
            formState.fullName,
            formState.phoneNumber,
            formState.aadhaarNumber,
            formState.dailyWage,
            formState.assignedSiteId,
            formState.assignedSiteName,
            formState.joinedDate,
            formState.status.toString().split('.').last,
          )).future,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Labour record updated successfully')),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final labourAsync = widget.labourId!= null
        ? ref.watch(labourByIdProvider(widget.labourId!))
        : null;

    final sitesAsync = ref.watch(sitesStreamProvider);

    final isEditMode = widget.labourId!= null;

    return AppScaffold(
      appBar: AppBar(
        title: Text(isEditMode? 'Edit Labour' : 'Add Labour'),
        elevation: 0,
      ),
      child: labourAsync == null
          ? sitesAsync.when(
              data: (sites) {
                final sitesList = sites
                    .map((site) => {'id': site.id, 'name': site.name})
                    .toList();

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.screenPadding),
                  child: LabourForm(
                    key: _formKey,
                    sites: sitesList,
                    onSubmit: _handleSubmit,
                    isLoading: _isLoading,
                    showStatusSelector: false,
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Error loading sites: $error'),
              ),
            )
          : labourAsync.when(
              data: (labour) {
                if (labour == null) {
                  return const Center(child: Text('Labour not found'));
                }

                return sitesAsync.when(
                  data: (sites) {
                    final sitesList = sites
                        .map((site) => {'id': site.id, 'name': site.name})
                        .toList();

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.screenPadding),
                      child: LabourForm(
                        key: _formKey,
                        fullName: labour.fullName,
                        phoneNumber: labour.phoneNumber,
                        aadhaarNumber: labour.aadhaarNumber,
                        dailyWage: labour.dailyWage,
                        assignedSiteId: labour.assignedSiteId,
                        assignedSiteName: labour.assignedSiteName,
                        joinedDate: labour.joinedDate,
                        status: labour.status,
                        sites: sitesList,
                        onSubmit: _handleSubmit,
                        isLoading: _isLoading,
                        showStatusSelector: true,
                      ),
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, stack) => Center(
                    child: Text('Error loading sites: $error'),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Error loading labour: $error'),
              ),
            ),
    );
  }
}

