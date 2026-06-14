import 'package:flutter/material.dart';
import 'package:civilhelp/app/theme.dart';

class ModuleEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? ctaLabel;
  final VoidCallback? onCta;
  final Color? iconColor;

  const ModuleEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.ctaLabel,
    this.onCta,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final themeColor = iconColor ?? context.colors.primary;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Glassmorphic circular icon container
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? Colors.white.withValues(alpha: 0.03) : themeColor.withValues(alpha: 0.05),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : themeColor.withValues(alpha: 0.15),
                  width: 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: themeColor.withValues(alpha: isDark ? 0.1 : 0.03),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 44,
                  color: themeColor,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              title,
              style: context.text.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: isDark ? Colors.white : context.colors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                description,
                style: context.text.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (ctaLabel != null && onCta != null) ...[
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: onCta,
                icon: const Icon(Icons.add_rounded),
                label: Text(
                  ctaLabel!,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
