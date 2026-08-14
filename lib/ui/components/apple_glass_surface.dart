import 'dart:ui';

import 'package:flutter/material.dart';

class AppleGlassSurface extends StatelessWidget {
  const AppleGlassSurface({
    super.key,
    required this.child,
    this.borderRadius = 28,
    this.padding,
    this.blur = 24,
    this.fillOpacity = 0.72,
    this.shadowOpacity = 0.09,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double blur;
  final double fillOpacity;
  final double shadowOpacity;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: shadowOpacity),
            blurRadius: 34,
            spreadRadius: -8,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: fillOpacity),
              borderRadius: radius,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.78),
                width: 0.8,
              ),
            ),
            child: Padding(
              padding: padding ?? EdgeInsets.zero,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
