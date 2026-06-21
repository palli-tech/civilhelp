import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:civilhelp/app/theme.dart';
import '../../../shared/layouts/app_scaffold.dart';
import '../../../shared/widgets/module_header.dart';
import '../../sites/providers/site_provider.dart';
import '../models/expense_model.dart';
import '../providers/expense_provider.dart';
import '../widgets/expense_form.dart';

class AddEditExpenseScreen extends ConsumerStatefulWidget {
  final ExpenseModel? expense;

  const AddEditExpenseScreen({
    super.key,
    this.expense,
  });

  @override
  ConsumerState<AddEditExpenseScreen> createState() => _AddEditExpenseScreenState();
}

class _AddEditExpenseScreenState extends ConsumerState<AddEditExpenseScreen> {
  final _formKey = GlobalKey<ExpenseFormState>();
  bool _isLoading = false;

  Future<void> _handleSubmit() async {
    final formState = _formKey.currentState;
    if (formState == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.expense == null) {
        // Create Mode
        await ref.read(
          createExpenseProvider((
            formState.amount,
            formState.category,
            formState.date,
            formState.description,
            formState.siteId,
            formState.receiptUrl,
          )).future,
        );
      } else {
        // Edit Mode
        final updatedModel = widget.expense!.copyWith(
          amount: formState.amount,
          category: formState.category,
          date: formState.date,
          description: formState.description,
          siteId: formState.siteId,
          receiptUrl: formState.receiptUrl,
        );
        await ref.read(updateExpenseProvider(updatedModel).future);
      }

      if (mounted) {
        final actionText = widget.expense == null ? 'created' : 'updated';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Expense $actionText successfully')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        final actionText = widget.expense == null ? 'creating' : 'updating';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error $actionText expense: ${e.toString()}'),
            backgroundColor: context.colors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sitesAsync = ref.watch(sitesStreamProvider);
    final isEdit = widget.expense != null;

    return AppScaffold(
      child: Column(
        children: [
          ModuleHeader(
            title: isEdit ? 'Edit Expense' : 'Add Expense',
            subtitle: isEdit ? 'Modify details of recorded cost' : 'Log a new project/overhead cost',
            showBackButton: true,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: sitesAsync.when(
                data: (sites) {
                  return Column(
                    children: [
                      ExpenseForm(
                        key: _formKey,
                        expense: widget.expense,
                        sites: sites,
                        onSubmit: _handleSubmit,
                        isLoading: _isLoading,
                      ),
                      if (_isLoading)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.screenPadding),
                          child: SizedBox(
                            height: 48,
                            child: Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  context.colors.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40.0),
                    child: Text(
                      'Error loading sites: $err',
                      style: TextStyle(color: context.colors.error),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
