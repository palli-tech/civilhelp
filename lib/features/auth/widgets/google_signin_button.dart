import 'package:flutter/material.dart';
import 'package:civilhelp/app/theme.dart';

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  context.colors.primary,
                ),
              ),
            )
          : const Icon(Icons.login),
      label: Text(isLoading ? 'Signing in...' : 'Sign in with Google'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm * 1.5,
          horizontal: AppSpacing.xl,
        ),
        backgroundColor: context.colors.surface,
        foregroundColor: context.colors.onSurface,
        side: BorderSide(color: context.colors.outline.withValues(alpha: 0.3)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

