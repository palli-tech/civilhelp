import 'package:flutter/material.dart';

class CompanyHeader extends StatelessWidget {
  final String? companyName;
  final String? logoUrl;
  final double size;
  final bool isVertical;
  final Color? textColor;

  const CompanyHeader({
    super.key,
    required this.companyName,
    required this.logoUrl,
    this.size = 50.0,
    this.isVertical = false,
    this.textColor,
  });

  String _getInitials(String name) {
    if (name.isEmpty) return 'C';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final name = companyName ?? 'Unknown Company';
    final hasLogo = logoUrl != null && logoUrl!.isNotEmpty;

    final logoWidget = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: hasLogo ? Colors.transparent : Theme.of(context).colorScheme.primaryContainer,
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).dividerColor.withAlpha(26),
          width: 1.5,
        ),
      ),
      child: ClipOval(
        child: hasLogo
            ? Image.network(
                logoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildFallbackWidget(context, name),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                },
              )
            : _buildFallbackWidget(context, name),
      ),
    );

    if (isVertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          logoWidget,
          const SizedBox(height: 12),
          Text(
            name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor ?? Theme.of(context).colorScheme.onSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        logoWidget,
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor ?? Theme.of(context).colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackWidget(BuildContext context, String name) {
    return Center(
      child: Text(
        _getInitials(name),
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.4,
        ),
      ),
    );
  }
}
