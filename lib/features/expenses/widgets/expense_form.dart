import 'package:flutter/material.dart';
import 'package:civilhelp/app/theme.dart';
import '../../sites/models/site_model.dart';
import '../models/expense_category.dart';
import '../models/expense_model.dart';

class ExpenseForm extends StatefulWidget {
  final ExpenseModel? expense;
  final List<SiteModel> sites;
  final Future<void> Function() onSubmit;
  final bool isLoading;

  const ExpenseForm({
    super.key,
    this.expense,
    required this.sites,
    required this.onSubmit,
    this.isLoading = false,
  });

  @override
  State<ExpenseForm> createState() => ExpenseFormState();
}

class ExpenseFormState extends State<ExpenseForm> {
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _receiptUrlController;
  late DateTime _selectedDate;
  late ExpenseCategory _selectedCategory;
  String? _selectedSiteId;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.expense != null ? widget.expense!.amount.toString() : '',
    );
    _descriptionController = TextEditingController(
      text: widget.expense?.description ?? '',
    );
    _receiptUrlController = TextEditingController(
      text: widget.expense?.receiptUrl ?? '',
    );
    _selectedDate = widget.expense?.date ?? DateTime.now();
    _selectedCategory = widget.expense?.category ?? ExpenseCategory.materials;
    _selectedSiteId = widget.expense?.siteId;

    // Check if the prefilled siteId is still in the active sites list
    if (_selectedSiteId != null && !widget.sites.any((s) => s.id == _selectedSiteId)) {
      _selectedSiteId = null;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _receiptUrlController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2050),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _amountController,
            decoration: InputDecoration(
              labelText: 'Amount (₹)',
              hintText: 'Enter expense amount',
              prefixIcon: const Icon(Icons.currency_rupee),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Amount is required';
              }
              final amount = double.tryParse(value);
              if (amount == null) {
                return 'Enter a valid number';
              }
              if (amount <= 0) {
                return 'Amount must be greater than zero';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.screenPadding),
          DropdownButtonFormField<ExpenseCategory>(
            initialValue: _selectedCategory,
            decoration: InputDecoration(
              labelText: 'Category',
              prefixIcon: const Icon(Icons.category_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: ExpenseCategory.values.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(category.displayName),
              );
            }).toList(),
            onChanged: widget.isLoading
                ? null
                : (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    }
                  },
          ),
          const SizedBox(height: AppSpacing.screenPadding),
          DropdownButtonFormField<String?>(
            initialValue: _selectedSiteId,
            decoration: InputDecoration(
              labelText: 'Site (Optional)',
              prefixIcon: const Icon(Icons.location_on_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('All Sites / Global'),
              ),
              ...widget.sites.map((site) {
                return DropdownMenuItem<String?>(
                  value: site.id,
                  child: Text(site.name),
                );
              }),
            ],
            onChanged: widget.isLoading
                ? null
                : (value) {
                    setState(() {
                      _selectedSiteId = value;
                    });
                  },
          ),
          const SizedBox(height: AppSpacing.screenPadding),
          InkWell(
            onTap: widget.isLoading ? null : _selectDate,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Expense Date',
                prefixIcon: const Icon(Icons.calendar_today_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.screenPadding),
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'Description',
              hintText: 'Enter expense details',
              prefixIcon: const Icon(Icons.description_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            maxLines: 3,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Description is required';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.screenPadding),
          TextFormField(
            controller: _receiptUrlController,
            decoration: InputDecoration(
              labelText: 'Receipt Image URL (Optional)',
              hintText: 'Enter image URL link',
              prefixIcon: const Icon(Icons.link_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          ElevatedButton(
            onPressed: widget.isLoading
                ? null
                : () async {
                    final isValid = _formKey.currentState?.validate() ?? false;
                    if (!isValid) return;
                    await widget.onSubmit();
                  },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                widget.expense != null ? 'Save Changes' : 'Create Expense',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double get amount => double.tryParse(_amountController.text) ?? 0.0;
  ExpenseCategory get category => _selectedCategory;
  DateTime get date => _selectedDate;
  String get description => _descriptionController.text.trim();
  String? get siteId => _selectedSiteId;
  String? get receiptUrl =>
      _receiptUrlController.text.trim().isEmpty ? null : _receiptUrlController.text.trim();
}
