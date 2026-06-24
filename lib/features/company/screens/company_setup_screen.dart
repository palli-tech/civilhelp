import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:civilhelp/app/theme.dart';
import 'package:civilhelp/core/enums/user_role.dart';
import 'package:civilhelp/core/enums/account_status.dart';
import 'package:civilhelp/core/enums/user_type.dart';
import 'package:civilhelp/shared/widgets/app_design_system.dart';
import '../../../data/models/company.dart';
import '../../../core/providers/tenant_provider.dart';
import '../../auth/providers/auth_provider.dart';

class CompanySetupScreen extends ConsumerStatefulWidget {
  const CompanySetupScreen({super.key});

  @override
  ConsumerState<CompanySetupScreen> createState() => _CompanySetupScreenState();
}

class _CompanySetupScreenState extends ConsumerState<CompanySetupScreen> {
  final _formKey = GlobalKey<FormState>();

  // Page controllers for multi-section view
  int _activeSection = 0;

  // Controllers
  final _legalNameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _gstController = TextEditingController();
  final _panController = TextEditingController();
  final _registrationController = TextEditingController();

  final _primaryContactController = TextEditingController();
  final _alternateContactController = TextEditingController();
  final _supportEmailController = TextEditingController();

  final _registeredAddressController = TextEditingController();
  final _operationalAddressController = TextEditingController();

  final _logoController = TextEditingController();
  final _primaryColorController = TextEditingController(text: '#7B4DFF');
  final _secondaryColorController = TextEditingController(text: '#5F2EEA');

  final _currencyController = TextEditingController(text: 'INR');
  final _workingHoursController = TextEditingController(text: '8.0');
  final _backdateLimitController = TextEditingController(text: '3');

  bool _isLoading = false;

  @override
  void dispose() {
    _legalNameController.dispose();
    _displayNameController.dispose();
    _gstController.dispose();
    _panController.dispose();
    _registrationController.dispose();
    _primaryContactController.dispose();
    _alternateContactController.dispose();
    _supportEmailController.dispose();
    _registeredAddressController.dispose();
    _operationalAddressController.dispose();
    _logoController.dispose();
    _primaryColorController.dispose();
    _secondaryColorController.dispose();
    _currencyController.dispose();
    _workingHoursController.dispose();
    _backdateLimitController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        throw Exception('User is not authenticated.');
      }

      final companyId = FirebaseFirestore.instance.collection('companies').doc().id;

      final company = Company(
        id: companyId,
        name: _displayNameController.text.trim(),
        address: _registeredAddressController.text.trim(),
        phone: _primaryContactController.text.trim(),
        email: _supportEmailController.text.trim(),
        gstNumber: _gstController.text.trim(),
        logoUrl: _logoController.text.trim(),
        ownerUid: user.uid,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        legalName: _legalNameController.text.trim(),
        panNumber: _panController.text.trim(),
        registrationNumber: _registrationController.text.trim(),
        alternateContact: _alternateContactController.text.trim(),
        operationalAddress: _operationalAddressController.text.trim(),
        primaryColor: _primaryColorController.text.trim(),
        secondaryColor: _secondaryColorController.text.trim(),
        currency: _currencyController.text.trim(),
        workingHours: double.tryParse(_workingHoursController.text.trim()) ?? 8.0,
        attendanceBackdateLimitDays: int.tryParse(_backdateLimitController.text.trim()) ?? 3,
      );

      final companyRepo = ref.read(companyRepositoryProvider);
      await companyRepo.createCompany(company);

      // Update owner user record
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'companyId': companyId,
        'tenantId': companyId,
        'role': UserRole.owner.name,
        'accountStatus': AccountStatus.active.name,
      });

      // Update the approved pre-approval request to completed
      final requestQuery = await FirebaseFirestore.instance
          .collection('company_requests')
          .where('ownerUid', isEqualTo: user.uid)
          .where('status', isEqualTo: 'approved')
          .limit(1)
          .get();

      if (requestQuery.docs.isNotEmpty) {
        await requestQuery.docs.first.reference.update({
          'status': 'completed',
          'completedAt': FieldValue.serverTimestamp(),
        });
      }

      ref.invalidate(userDataProvider);
      ref.invalidate(tenantContextProvider);
      await ref.read(tenantContextProvider.future);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Company workspace setup completed successfully!'),
            backgroundColor: AppDesignSystem.successColor,
          ),
        );
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Company setup failed: ${e.toString()}'),
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
    final userDataAsync = ref.watch(userDataProvider);

    return userDataAsync.when(
      data: (userData) {
        if (userData == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final userTypeStr = userData['userType'] as String?;
        final userType = UserType.fromString(userTypeStr);
        final accountStatusStr = userData['accountStatus'] as String?;
        final accountStatus = AccountStatus.fromString(accountStatusStr);
        final companyId = userData['companyId'] as String? ?? '';
        final role = userData['role'] as String? ?? '';

        debugPrint('CompanySetupScreen Build: userTypeStr=$userTypeStr, userType=$userType, accountStatusStr=$accountStatusStr, accountStatus=$accountStatus, companyId=$companyId, role=$role');

        final isAllowed = (userType == UserType.owner &&
                accountStatus == AccountStatus.approved &&
                companyId.isEmpty) ||
            (role == 'admin');

        if (!isAllowed) {
          return const Scaffold(
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'Access Denied. You do not have permission to create a company profile or your request is not approved yet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Complete Company Setup'),
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
              child: Column(
                children: [
                  _buildStepIndicator(),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(AppSpacing.screenPadding),
                      children: [
                        if (_activeSection == 0) _buildCompanyDetailsSection(),
                        if (_activeSection == 1) _buildContactAddressSection(),
                        if (_activeSection == 2) _buildBrandingSettingsSection(),
                        const SizedBox(height: AppSpacing.lg),
                        _buildNavigationButtons(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        body: Center(child: Text('Error: ${error.toString()}')),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      color: context.colors.surface.withValues(alpha: 0.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStepCircle(0, 'Details'),
          _buildStepLine(0),
          _buildStepCircle(1, 'Contact'),
          _buildStepLine(1),
          _buildStepCircle(2, 'Settings'),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int index, String label) {
    final isActive = _activeSection == index;
    final isDone = _activeSection > index;
    return Column(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: isDone
              ? Colors.green
              : (isActive ? context.colors.primary : context.colors.outline.withOpacity(0.2)),
          child: isDone
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: isActive || isDone ? Colors.white : context.colors.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? context.colors.primary : context.colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int index) {
    final isDone = _activeSection > index;
    return Container(
      width: 50,
      height: 2,
      margin: const EdgeInsets.only(bottom: 18),
      color: isDone ? Colors.green : context.colors.outline.withOpacity(0.2),
    );
  }

  Widget _buildCompanyDetailsSection() {
    return Column(
      children: [
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Company Details',
                  style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _legalNameController,
                  decoration: const InputDecoration(
                    labelText: 'Legal Company Name *',
                    prefixIcon: Icon(Icons.gavel_outlined),
                    hintText: 'e.g. ABC Constructions Private Limited',
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Legal Company Name is required' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _displayNameController,
                  decoration: const InputDecoration(
                    labelText: 'Display Name *',
                    prefixIcon: Icon(Icons.business_outlined),
                    hintText: 'e.g. ABC Constructions',
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Display Name is required' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _gstController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'GST Number',
                    prefixIcon: Icon(Icons.receipt_long_outlined),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _panController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'PAN Number',
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: TextFormField(
                        controller: _registrationController,
                        decoration: const InputDecoration(
                          labelText: 'Registration Number',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactAddressSection() {
    return Column(
      children: [
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contact Information',
                  style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _primaryContactController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Primary Contact *',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Primary Contact is required' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _alternateContactController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Alternate Contact',
                    prefixIcon: Icon(Icons.phone_iphone_outlined),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _supportEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Support Email *',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Support Email is required' : null,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Addresses',
                  style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _registeredAddressController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Registered Address *',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Registered Address is required' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _operationalAddressController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Operational Address',
                    prefixIcon: Icon(Icons.location_city_outlined),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBrandingSettingsSection() {
    return Column(
      children: [
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Branding & Logo',
                  style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _logoController,
                  decoration: const InputDecoration(
                    labelText: 'Logo URL',
                    prefixIcon: Icon(Icons.image_outlined),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _primaryColorController,
                        decoration: const InputDecoration(
                          labelText: 'Primary Color Hex',
                          prefixIcon: Icon(Icons.color_lens_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: TextFormField(
                        controller: _secondaryColorController,
                        decoration: const InputDecoration(
                          labelText: 'Secondary Color Hex',
                        ),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Workforce Settings',
                  style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _currencyController,
                        decoration: const InputDecoration(
                          labelText: 'Currency',
                          hintText: 'e.g. INR',
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: TextFormField(
                        controller: _workingHoursController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Working Hours',
                          hintText: 'e.g. 8.0',
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _backdateLimitController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Attendance Backdate Limit (Days)',
                    prefixIcon: Icon(Icons.lock_clock_outlined),
                    hintText: 'e.g. 3',
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Required' : null,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_activeSection > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  _activeSection--;
                });
              },
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Back'),
            ),
          )
        else
          const Spacer(),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading
                ? null
                : () {
                    if (_activeSection < 2) {
                      setState(() {
                        _activeSection++;
                      });
                    } else {
                      _submit();
                    }
                  },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: _activeSection == 2 ? Colors.green : context.colors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(_activeSection == 2 ? 'Submit' : 'Next'),
          ),
        ),
      ],
    );
  }
}
