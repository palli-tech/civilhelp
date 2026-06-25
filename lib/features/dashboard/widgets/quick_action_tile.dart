import 'package:flutter/material.dart';
import 'package:civilhelp/app/theme.dart';

class QuickActionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;
  final Widget? trailing;

  const QuickActionTile({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.iconColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                color: iconColor ?? context.colors.primary,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: context.text.bodyLarge,
                ),
              ),
              if (trailing != null) ...[
                trailing!,
                const SizedBox(width: 8),
              ],
              Icon(
                Icons.chevron_right,
                color: context.colors.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
