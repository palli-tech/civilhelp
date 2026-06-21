import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:civilhelp/core/theme/context_extensions.dart';

class PremiumBackground extends StatelessWidget {
  final Widget child;

  const PremiumBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!context.isDarkMode) {
      return Container(
        color: Theme.of(context).colorScheme.background,
        child: child,
      );
    }

    return Stack(
      children: [
        // Layered Gradient App Background
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF090B1A),
                  Color(0xFF111633),
                  Color(0xFF0B1028),
                ],
              ),
            ),
          ),
        ),
        // Subtle Purple Glow
        Positioned(
          top: -150,
          right: -100,
          child: Container(
            width: 500,
            height: 500,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF7B4DFF).withOpacity(0.06),
                  const Color(0xFF7B4DFF).withOpacity(0.0),
                ],
              ),
            ),
          ),
        ),
        // Subtle Indigo Glow
        Positioned(
          bottom: -150,
          left: -100,
          child: Container(
            width: 600,
            height: 600,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF3D8BFF).withOpacity(0.04),
                  const Color(0xFF3D8BFF).withOpacity(0.0),
                ],
              ),
            ),
          ),
        ),
        // Actual layout / contents
        Positioned.fill(child: child),
      ],
    );
  }
}
