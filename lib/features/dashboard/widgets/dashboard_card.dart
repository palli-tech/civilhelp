import 'package:flutter/material.dart';
import 'package:civilhelp/core/theme/context_extensions.dart';

class DashboardCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? backgroundColor;
  final Gradient? gradient;
  final IconData? overlayIcon;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final Color? glowColor;
  final VoidCallback? onTap;

  const DashboardCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.backgroundColor,
    this.gradient,
    this.overlayIcon,
    this.iconColor,
    this.iconBackgroundColor,
    this.glowColor,
    this.onTap,
  });

  @override
  State<DashboardCard> createState() => _DashboardCardState();
}

class _DashboardCardState extends State<DashboardCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    final defaultDarkGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF12182F),
        const Color(0xFF1B2142),
      ],
    );

    final finalGradient = widget.gradient ?? (isDark ? defaultDarkGradient : null);
    final finalBgColor = widget.gradient != null
        ? null
        : (widget.backgroundColor ?? (isDark ? null : Theme.of(context).colorScheme.surfaceVariant.withValues(alpha: 0.5)));

    final glow = widget.glowColor ?? const Color(0xFF7B4DFF);

    // Dynamic text colors for contrast in Light Theme
    final textPrimary = isDark
        ? Colors.white
        : (widget.iconColor ?? Theme.of(context).colorScheme.onSurface);
    
    final textSecondary = isDark
        ? const Color(0xFFB4B8D0)
        : (widget.iconColor?.withValues(alpha: 0.7) ?? Theme.of(context).colorScheme.onSurfaceVariant);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isMobile ? 16 : 24),
            color: finalBgColor,
            gradient: finalGradient,
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
            borderRadius: BorderRadius.circular(isMobile ? 16 : 24),
            child: Stack(
              children: [
                // Decorative bottom-right large icon overlay
                if (widget.overlayIcon != null)
                  Positioned(
                    right: -15,
                    bottom: -15,
                    child: Opacity(
                      opacity: isDark ? 0.07 : 0.04,
                      child: Icon(
                        widget.overlayIcon,
                        size: isMobile ? 70.0 : 110.0,
                        color: widget.glowColor ?? widget.iconColor ?? Colors.white,
                      ),
                    ),
                  ),

                // InkWell layout
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onTap,
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? 14.0 : 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: EdgeInsets.all(isMobile ? 8.0 : 12.0),
                                decoration: BoxDecoration(
                                  color: widget.iconBackgroundColor ??
                                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(isMobile ? 12.0 : 16.0),
                                ),
                                child: Icon(
                                  widget.icon,
                                  color: widget.iconColor ?? Theme.of(context).colorScheme.primary,
                                  size: isMobile ? 18.0 : 24.0,
                                ),
                              ),
                              if (isDark && _isHovered)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: glow,
                                    boxShadow: [
                                      BoxShadow(
                                        color: glow,
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: isMobile ? 10.0 : 16.0),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.value,
                                style: TextStyle(
                                  fontFamily: 'NotoSans',
                                  fontSize: isMobile ? 24.0 : 36.0,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                  height: 1.0,
                                ),
                              ),
                              SizedBox(height: isMobile ? 4.0 : 6.0),
                              Text(
                                widget.title,
                                style: TextStyle(
                                  fontFamily: 'NotoSans',
                                  fontSize: isMobile ? 12.0 : 14.0,
                                  fontWeight: FontWeight.w500,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
