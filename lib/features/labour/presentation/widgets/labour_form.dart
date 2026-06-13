import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:civilhelp/core/enums/labour_status.dart';

class LabourForm extends StatefulWidget {
  final String? fullName;
  final String? phoneNumber;
  final String? aadhaarNumber;
  final double? dailyWage;
  final String? assignedSiteId;
  final String? assignedSiteName;
  final DateTime? joinedDate;
  final LabourStatus? status;
  final List<Map<String, String>>? sites;
  final Future<void> Function()? onSubmit;
  final bool isLoading;
  final bool showStatusSelector;

  const LabourForm({
    super.key,
    this.fullName,
    this.phoneNumber,
    this.aadhaarNumber,
    this.dailyWage,
    this.assignedSiteId,
    this.assignedSiteName,
    this.joinedDate,
    this.status,
    this.sites,
    required this.onSubmit,
    this.isLoading = false,
    this.showStatusSelector = true,
  });

  @override
  State<LabourForm> createState() => LabourFormState();
}

class LabourFormState extends State<LabourForm> {
  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _aadhaarController;
  late final TextEditingController _dailyWageController;
  late DateTime _selectedJoinedDate;
  late LabourStatus _selectedStatus;
  late String _selectedSiteId;
  late String _selectedSiteName;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.fullName ?? '');
    _phoneController = TextEditingController(text: widget.phoneNumber ?? '');
    _aadhaarController = TextEditingController(text: widget.aadhaarNumber ?? '');
    _dailyWageController =
        TextEditingController(text: widget.dailyWage?.toString() ?? '');
    _selectedJoinedDate = widget.joinedDate ?? DateTime.now();
    _selectedStatus = widget.status ?? LabourStatus.active;
    _selectedSiteId = widget.assignedSiteId ?? '';
    _selectedSiteName = widget.assignedSiteName ?? '';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _aadhaarController.dispose();
    _dailyWageController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedJoinedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedJoinedDate) {
      setState(() {
        _selectedJoinedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _fullNameController,
            decoration: InputDecoration(
              labelText: 'Full Name',
              hintText: 'Enter labour full name',
              prefixIcon: const Icon(Icons.person),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Full name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            decoration: InputDecoration(
              labelText: 'Phone Number',
              hintText: 'Enter phone number',
              prefixIcon: const Icon(Icons.phone),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Phone number is required';
              }
              if (value!.length < 10) {
                return 'Phone number should be at least 10 digits';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _aadhaarController,
            decoration: InputDecoration(
              labelText: 'Aadhaar Number',
              hintText: 'Enter Aadhaar number',
              prefixIcon: const Icon(Icons.credit_card),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Aadhaar number is required';
              }
              if (value!.length != 12) {
                return 'Aadhaar number should be 12 digits';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _dailyWageController,
            decoration: InputDecoration(
              labelText: 'Daily Wage (₹)',
              hintText: 'Enter daily wage',
              prefixIcon: const Icon(Icons.currency_rupee),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Daily wage is required';
              }
              if (double.tryParse(value!) == null) {
                return 'Enter a valid amount';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          if (widget.sites != null && widget.sites!.isNotEmpty)
            DropdownButtonFormField<String>(
              initialValue: _selectedSiteId.isEmpty ? null : _selectedSiteId,
              decoration: InputDecoration(
                labelText: 'Assigned Site',
                prefixIcon: const Icon(Icons.location_on),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: widget.sites!.map((site) {
                return DropdownMenuItem<String>(
                  value: site['id']!,
                  child: Text(site['name']!),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedSiteId = value;
                    final site = widget.sites!.firstWhere(
                      (s) => s['id'] == value,
                      orElse: () => {'id': '', 'name': ''},
                    );
                    _selectedSiteName = site['name'] ?? '';
                  });
                }
              },
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Site assignment is required';
                }
                return null;
              },
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.assignedSiteName ?? 'No site assigned',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _selectDate,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Joined Date',
                prefixIcon: const Icon(Icons.calendar_today),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(dateFormat.format(_selectedJoinedDate)),
            ),
          ),
          if (widget.showStatusSelector) ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<LabourStatus>(
              initialValue: _selectedStatus,
              decoration: InputDecoration(
                labelText: 'Status',
                prefixIcon: const Icon(Icons.info),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: LabourStatus.values.map((status) {
                final rawName = status.toString().split('.').last;
                final name = rawName[0].toUpperCase() + rawName.substring(1);
                return DropdownMenuItem(value: status, child: Text(name));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedStatus = value;
                  });
                }
              },
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.isLoading
                  ? null
                  : () async {
                      final isValid = _formKey.currentState?.validate() ?? false;

                      if (!isValid) return;

                      await widget.onSubmit?.call();
                    },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: widget.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Save Labour',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool validate() => _formKey.currentState?.validate() ?? false;

  String get fullName => _fullNameController.text;
  String get phoneNumber => _phoneController.text;
  String get aadhaarNumber => _aadhaarController.text;
  double get dailyWage => double.parse(_dailyWageController.text);
  String get assignedSiteId => _selectedSiteId;
  String get assignedSiteName => _selectedSiteName;
  DateTime get joinedDate => _selectedJoinedDate;
  LabourStatus get status => _selectedStatus;
}
