import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:civilhelp/app/theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/enums/account_status.dart';

class CompanyRequestScreen extends ConsumerStatefulWidget {
  const CompanyRequestScreen({super.key});

  @override
  ConsumerState<CompanyRequestScreen> createState() => _CompanyRequestScreenState();
}

class _CompanyRequestScreenState extends ConsumerState<CompanyRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late final TextEditingController _ownerNameController;
  late final TextEditingController _ownerEmailController;
  final _companyNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pinCodeController = TextEditingController();
  final _estimatedSupervisorController = TextEditingController();
  final _gstController = TextEditingController();
  final _websiteController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedBusinessType = 'Construction Contractor';
  String _selectedLabourCount = '1-25';

  final List<String> _businessTypeOptions = [
    'Construction Contractor',
    'Builder',
    'Infrastructure',
    'Road Projects',
    'Industrial Projects',
    'Government Contractor',
    'Civil Works',
    'Other',
  ];

  final List<String> _labourCountOptions = [
    '1-25',
    '26-100',
    '101-500',
    '500+',
  ];

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    final userData = ref.read(userDataProvider).value;
    final userName = userData?['name'] as String? ?? user?.displayName ?? '';
    _ownerNameController = TextEditingController(text: userName);
    _ownerEmailController = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _ownerNameController.dispose();
    _ownerEmailController.dispose();
    _companyNameController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pinCodeController.dispose();
    _estimatedSupervisorController.dispose();
    _gstController.dispose();
    _websiteController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        throw Exception('User is not authenticated');
      }

      // Check if an active request already exists (pending or approved)
      final existingRequests = await FirebaseFirestore.instance
          .collection('company_requests')
          .where('ownerUid', isEqualTo: user.uid)
          .where('status', whereIn: ['pending', 'approved'])
          .get();

      if (existingRequests.docs.isNotEmpty) {
        throw Exception('You already have an active request pending or approved.');
      }

      // Create request doc
      final requestDocRef = FirebaseFirestore.instance.collection('company_requests').doc(user.uid);
      await requestDocRef.set({
        'ownerUid': user.uid,
        'ownerName': _ownerNameController.text.trim(),
        'ownerEmail': _ownerEmailController.text.trim(),
        'companyName': _companyNameController.text.trim(),
        'mobileNumber': _mobileController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'pinCode': _pinCodeController.text.trim(),
        'businessType': _selectedBusinessType,
        'estimatedLabourCount': _selectedLabourCount,
        'estimatedSupervisorCount': _estimatedSupervisorController.text.trim(),
        'gstNumber': _gstController.text.trim(),
        'website': _websiteController.text.trim(),
        'notes': _notesController.text.trim(),
        'status': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
        'reviewedAt': null,
        'reviewedBy': null,
        'rejectionReason': null,
      });

      // Update user status
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'accountStatus': AccountStatus.pending.name,
      });

      ref.invalidate(userDataProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Access request submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString();
        if (msg.contains('hospitalityIn')) {
          msg = 'You already have an active request pending or approved.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit: $msg'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Company Access'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              context.colors.primaryContainer.withValues(alpha: 0.15),
              context.colors.surface,
            ],
          ),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Applicant Information',
                        style: context.text.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.colors.primary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _ownerNameController,
                        decoration: const InputDecoration(
                          labelText: 'Owner Name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'Name is required' : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _ownerEmailController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Owner Email (Read-only)',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Company Pre-Approval Details',
                        style: context.text.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.colors.primary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _companyNameController,
                        decoration: const InputDecoration(
                          labelText: 'Company Name',
                          prefixIcon: Icon(Icons.business_outlined),
                          hintText: 'e.g. ABC Constructions',
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'Company Name is required' : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _mobileController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Mobile Number',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'Mobile number is required' : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Address',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'Address is required' : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _cityController,
                              decoration: const InputDecoration(
                                labelText: 'City',
                              ),
                              validator: (value) =>
                                  value == null || value.trim().isEmpty ? 'City required' : null,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: TextFormField(
                              controller: _stateController,
                              decoration: const InputDecoration(
                                labelText: 'State',
                              ),
                              validator: (value) =>
                                  value == null || value.trim().isEmpty ? 'State required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _pinCodeController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'PIN Code',
                              ),
                              validator: (value) =>
                                  value == null || value.trim().isEmpty ? 'PIN required' : null,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedBusinessType,
                              decoration: const InputDecoration(
                                labelText: 'Business Type',
                              ),
                              items: _businessTypeOptions
                                  .map((type) => DropdownMenuItem(
                                        value: type,
                                        child: Text(type),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedBusinessType = value;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedLabourCount,
                              decoration: const InputDecoration(
                                labelText: 'Est. Labour Count',
                              ),
                              items: _labourCountOptions
                                  .map((count) => DropdownMenuItem(
                                        value: count,
                                        child: Text(count),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedLabourCount = value;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: TextFormField(
                              controller: _estimatedSupervisorController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Est. Supervisors',
                              ),
                              validator: (value) =>
                                  value == null || value.trim().isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Optional Fields',
                        style: context.text.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.colors.outline,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _gstController,
                        decoration: const InputDecoration(
                          labelText: 'GST Number',
                          prefixIcon: Icon(Icons.receipt_long_outlined),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _websiteController,
                        keyboardType: TextInputType.url,
                        decoration: const InputDecoration(
                          labelText: 'Website',
                          prefixIcon: Icon(Icons.web_outlined),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Additional Notes',
                          prefixIcon: Icon(Icons.note_alt_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitRequest,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    backgroundColor: context.colors.primary,
                    foregroundColor: context.colors.onPrimary,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: context.colors.onPrimary,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Submit Company Request',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.send_rounded),
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
}
