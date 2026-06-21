import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:civilhelp/app/theme.dart';
import '../../../core/providers/tenant_provider.dart';
import '../../../shared/widgets/module_header.dart';
import '../../../shared/widgets/company_header.dart';
import '../providers/company_profile_provider.dart';

class CompanyProfileScreen extends ConsumerStatefulWidget {
  const CompanyProfileScreen({super.key});

  @override
  ConsumerState<CompanyProfileScreen> createState() => _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends ConsumerState<CompanyProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _gstController = TextEditingController();
  
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _gstController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadLogo() async {
    final picker = ImagePicker();
    try {
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 85,
      );

      if (image != null) {
        final success = await ref
            .read(companyProfileNotifierProvider.notifier)
            .uploadCompanyLogo(image);

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Logo updated successfully.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking logo: $e')),
        );
      }
    }
  }

  Future<void> _deleteLogo() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Logo'),
        content: const Text('Are you sure you want to delete the company logo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ref
          .read(companyProfileNotifierProvider.notifier)
          .deleteCompanyLogo();

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logo deleted successfully.')),
        );
      }
    }
  }

  Future<void> _saveDetails() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref
          .read(companyProfileNotifierProvider.notifier)
          .updateCompanyDetails(
            name: _nameController.text.trim(),
            address: _addressController.text.trim(),
            phone: _phoneController.text.trim(),
            email: _emailController.text.trim(),
            gstNumber: _gstController.text.trim(),
          );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Company profile updated successfully.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final companyState = ref.watch(tenantCompanyStreamProvider);
    final state = ref.watch(companyProfileNotifierProvider);

    // Initial form values population
    companyState.whenData((company) {
      if (company != null && !_initialized) {
        _nameController.text = company.name;
        _addressController.text = company.address;
        _phoneController.text = company.phone;
        _emailController.text = company.email;
        _gstController.text = company.gstNumber;
        _initialized = true;
      }
    });

    // Error listening and feedback SnackBar
    ref.listen<CompanyProfileState>(companyProfileNotifierProvider, (prev, curr) {
      if (curr.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(curr.errorMessage!),
            backgroundColor: context.colors.error,
          ),
        );
      }
    });

    return Scaffold(
      body: Column(
        children: [
          ModuleHeader(
            title: 'Company Profile',
            subtitle: 'Manage company branding, office contact, and registration details',
            showBackButton: true,
            actions: [
              if (state.isSaving)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: _saveDetails,
                ),
            ],
          ),
          Expanded(
            child: companyState.when(
        data: (company) {
          if (company == null) {
            return const Center(child: Text('Company data not found.'));
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: Form(
                key: _formKey,
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo Section
                        Center(
                          child: Column(
                            children: [
                              CompanyHeader(
                                companyName: company.name,
                                logoUrl: company.logoUrl,
                                size: 100.0,
                                isVertical: true,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  TextButton.icon(
                                    onPressed: state.isSaving ? null : _pickAndUploadLogo,
                                    icon: const Icon(Icons.photo_library),
                                    label: const Text('Upload Logo'),
                                  ),
                                  if (company.logoUrl.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    TextButton.icon(
                                      style: TextButton.styleFrom(
                                        foregroundColor: context.colors.error,
                                      ),
                                      onPressed: state.isSaving ? null : _deleteLogo,
                                      icon: const Icon(Icons.delete),
                                      label: const Text('Delete'),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sectionGap),
                        const Divider(),
                        const SizedBox(height: AppSpacing.screenPadding),

                        // Form Fields
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Company Name *',
                            prefixIcon: Icon(Icons.business),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Company name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.screenPadding),

                        TextFormField(
                          controller: _addressController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Office Address',
                            prefixIcon: Icon(Icons.location_on),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.screenPadding),

                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Contact Phone',
                            prefixIcon: Icon(Icons.phone),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.screenPadding),

                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Contact Email',
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                              if (!emailRegex.hasMatch(value)) {
                                return 'Enter a valid email address';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.screenPadding),

                        TextFormField(
                          controller: _gstController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: 'GST Number',
                            prefixIcon: Icon(Icons.receipt_long),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sectionGap),
 
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.screenPadding),
                          ),
                          onPressed: state.isSaving ? null : _saveDetails,
                          icon: const Icon(Icons.save),
                          label: const Text('Save Profile Details'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading company: $err')),
        ),
      ),
    ],
  ),
);
}
}
