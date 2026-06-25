import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:civilhelp/app/theme.dart';
import '../providers/auth_provider.dart';
import '../../../core/providers/tenant_provider.dart';
import '../../../core/enums/user_role.dart';
import '../../../core/enums/user_type.dart';
import '../../../core/enums/account_status.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  bool _isLoading = false;
  int _currentStep = 1;
  UserType _selectedUserType = UserType.owner;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _nameController = TextEditingController(text: user?.displayName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 1) {
      if (!_formKey.currentState!.validate()) return;
      setState(() {
        _currentStep = 2;
      });
    }
  }

  void _previousStep() {
    if (_currentStep == 2) {
      setState(() {
        _currentStep = 1;
      });
    }
  }

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        throw Exception('User is not authenticated.');
      }

      final enteredName = _nameController.text.trim();

      final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final userDocSnap = await userDocRef.get();

      if (!userDocSnap.exists) {
        await userDocRef.set({
          'tenantId': '',
          'name': enteredName,
          'email': user.email ?? '',
          'photoUrl': user.photoURL ?? '',
          'companyId': '',
          'role': UserRole.pending.name,
          'assignedSiteIds': [],
          'active': true,
          'onboarded': true,
          'userType': _selectedUserType.name,
          'accountStatus': AccountStatus.pending.name,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await userDocRef.update({
          'name': enteredName,
          'userType': _selectedUserType.name,
          'accountStatus': AccountStatus.pending.name,
          'onboarded': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Force refresh userDataProvider and tenantContextProvider
      ref.invalidate(userDataProvider);
      ref.invalidate(tenantContextProvider);

      // Re-fetch to ensure it is resolved before routing
      await ref.read(tenantContextProvider.future);

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: ${e.toString()}'),
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
    final user = ref.watch(currentUserProvider);
    final isDark = context.isDarkMode;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              context.colors.primaryContainer.withValues(alpha: 0.35),
              context.colors.secondaryContainer.withValues(alpha: 0.15),
              context.colors.surface,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Card(
                elevation: 10,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding,
                    vertical: AppSpacing.sectionGap,
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _currentStep == 1
                        ? _buildNameStep(user, isDark)
                        : _buildRoleStep(isDark),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNameStep(User? user, bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey('nameStep'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: context.colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.person_outline,
                  size: 32,
                  color: context.colors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profile Setup',
                      style: context.text.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Step 1 of 2: Basic Info',
                      style: context.text.bodyMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (user?.email != null) ...[
            Text(
              'Email: ${user!.email}',
              style: TextStyle(
                fontSize: 14,
                color: context.colors.outline,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Your Name',
              prefixIcon: Icon(Icons.badge_outlined),
              hintText: 'Enter your full name',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your name';
              }
              if (value.trim().length < 2) {
                return 'Name must be at least 2 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                backgroundColor: context.colors.primary,
                foregroundColor: context.colors.onPrimary,
                elevation: 2,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleStep(bool isDark) {
    Widget buildRoleCard(UserType type, String title, String subtitle, IconData icon) {
      final isSelected = _selectedUserType == type;
      return GestureDetector(
        onTap: () {
          setState(() {
            _selectedUserType = type;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isSelected
                ? context.colors.primary.withValues(alpha: isDark ? 0.15 : 0.08)
                : Colors.transparent,
            border: Border.all(
              color: isSelected
                  ? context.colors.primary
                  : (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08)),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: isSelected
                      ? context.colors.primary.withValues(alpha: 0.15)
                      : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isSelected ? context.colors.primary : context.colors.outline,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.text.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? context.colors.primary : context.colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: context.text.bodyMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      key: const ValueKey('roleStep'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _previousStep,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How will you use CivilHelp?',
                    style: context.text.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.colors.onSurface,
                    ),
                  ),
                  Text(
                    'Step 2 of 2: Select Intended Role',
                    style: context.text.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        buildRoleCard(
          UserType.owner,
          'Company / MSME Owner',
          'I own or manage a company.',
          Icons.business_center_outlined,
        ),
        const SizedBox(height: AppSpacing.md),
        buildRoleCard(
          UserType.employee,
          'Employee / Supervisor',
          'I will join an existing company using an invitation.',
          Icons.badge_outlined,
        ),
        const SizedBox(height: AppSpacing.xl),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: context.colors.primary,
              foregroundColor: context.colors.onPrimary,
              elevation: 2,
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
                        'Save & Get Started',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.check),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
