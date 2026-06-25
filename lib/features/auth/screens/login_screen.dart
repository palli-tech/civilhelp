import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:civilhelp/app/theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/google_signin_button.dart';
import '../../../core/providers/tenant_provider.dart';
import '../../../core/enums/user_role.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithGoogle();

      if (mounted) {
        ref.invalidate(tenantContextProvider);
        ref.invalidate(userDataProvider);
        
        final tenantContext = await ref.read(tenantContextProvider.future);
        final userData = await ref.read(userDataProvider.future);
        final role = UserRole.fromString(userData?['role'] as String?);
        
        if (mounted) {
          if (role == UserRole.admin || tenantContext != null) {
            Navigator.of(context).pushReplacementNamed('/dashboard');
          } else {
            Navigator.of(context).pushReplacementNamed('/company-access-required');
          }
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Sign in failed: ${e.toString()}';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: context.colors.error,
            duration: const Duration(seconds: 3),
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
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'CivilHelp',
                  style: context.text.headlineLarge?.copyWith(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: context.colors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Construction Workforce Management',
                  style: context.text.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xxxl),
                GoogleSignInButton(
                  onPressed: _handleGoogleSignIn,
                  isLoading: _isLoading,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _errorMessage!,
                    style: context.text.bodySmall?.copyWith(
                      color: context.colors.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

