import 'package:flutter/material.dart';
import 'package:civilhelp/app/theme.dart';

class PremiumModuleCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final Color? backgroundColor;
  final Color? glowColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  const PremiumModuleCard({
    super.key,
    required this.child,
    this.onTap,
    this.gradient,
    this.backgroundColor,
    this.glowColor,
    this.borderRadius = 24.0,
    this.padding = const EdgeInsets.all(20.0),
  });

  @override
  State<PremiumModuleCard> createState() => _PremiumModuleCardState();
}

class _PremiumModuleCardState extends State<PremiumModuleCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    // Eedu dark purple gradient for cards
    final defaultDarkGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF1F1633),
        const Color(0xFF2A1F44),
      ],
    );

    // Glow color (defaults to purple theme accent)
    final glow = widget.glowColor ?? const Color(0xFF7B4DFF);

    // Soft tinted gradient in Light Mode (white to soft glow color tint)
    final defaultLightGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white,
        glow.withValues(alpha: 0.05),
      ],
    );

    final finalGradient = widget.gradient ?? 
        (isDark ? defaultDarkGradient : defaultLightGradient);

    final finalBgColor = widget.backgroundColor;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.015 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            color: finalBgColor,
            gradient: finalBgColor == null ? finalGradient : null,
            border: Border.all(
              color: isDark
                  ? (_isHovered ? glow.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.08))
                  : (_isHovered ? glow.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.08)),
              width: 1.0,
            ),
            boxShadow: [
              if (_isHovered)
                BoxShadow(
                  color: isDark ? glow.withValues(alpha: 0.2) : glow.withValues(alpha: 0.06),
                  blurRadius: 24,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                )
              else
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                child: Padding(
                  padding: widget.padding,
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
