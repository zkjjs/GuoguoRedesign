import 'package:flutter/material.dart';

/// Immutable semantic values for the Cinema Glass visual language.
abstract final class CinemaTokens {
  static const Color canvas = Color(0xFF050506);
  static const Color surface = Color(0xFF121216);
  static const Color surfaceGlass = Color(0xCC121216);
  static const Color primaryText = Color(0xFFF5F5F7);
  static const Color secondaryText = Color(0xFFA1A1AA);
  static const Color accent = Color(0xFFFF3B30);
  static const Color separator = Color(0x33F5F5F7);

  static const double navHeight = 64;
  static const double minimumHitTarget = 44;
  static const double glassBlur = 24;
  static const double radiusLarge = 24;
  static const double radiusMedium = 16;
}
