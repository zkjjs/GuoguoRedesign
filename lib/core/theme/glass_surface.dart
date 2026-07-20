import 'dart:ui';

import 'package:flutter/material.dart';

import 'accessibility_preferences.dart';
import 'cinema_tokens.dart';

class GlassSurface extends StatelessWidget {
  const GlassSurface({
    required this.child,
    this.borderRadius = BorderRadius.zero,
    super.key,
  });

  final Widget child;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.maybeOf(context);
    final opaque =
        (mediaQuery?.highContrast ?? false) ||
        AccessibilityPreferencesScope.reduceTransparencyOf(context);
    final decoration = BoxDecoration(
      color: opaque ? CinemaTokens.surface : CinemaTokens.surfaceGlass,
      borderRadius: borderRadius,
      border: Border.all(color: CinemaTokens.separator),
    );

    final content = DecoratedBox(decoration: decoration, child: child);
    if (opaque) {
      return ClipRRect(borderRadius: borderRadius, child: content);
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: CinemaTokens.glassBlur,
          sigmaY: CinemaTokens.glassBlur,
        ),
        child: content,
      ),
    );
  }
}
