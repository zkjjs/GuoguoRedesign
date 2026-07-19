import 'package:flutter/material.dart';

import 'cinema_tokens.dart';

abstract final class CinemaTheme {
  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    const systemTextTheme = TextTheme(
      displayLarge: TextStyle(
        color: CinemaTokens.primaryText,
        fontSize: 48,
        fontWeight: FontWeight.w700,
        height: 1.08,
        letterSpacing: -1.2,
      ),
      headlineMedium: TextStyle(
        color: CinemaTokens.primaryText,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.18,
        letterSpacing: -0.4,
      ),
      titleLarge: TextStyle(
        color: CinemaTokens.primaryText,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1.25,
      ),
      bodyLarge: TextStyle(
        color: CinemaTokens.primaryText,
        fontSize: 17,
        fontWeight: FontWeight.w400,
        height: 1.45,
      ),
      bodyMedium: TextStyle(
        color: CinemaTokens.secondaryText,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.45,
        letterSpacing: 0.1,
      ),
      labelMedium: TextStyle(
        color: CinemaTokens.primaryText,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.25,
        letterSpacing: 0.2,
      ),
    );

    const minimumSize = WidgetStatePropertyAll<Size>(
      Size.square(CinemaTokens.minimumHitTarget),
    );

    return base.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: CinemaTokens.canvas,
      canvasColor: CinemaTokens.canvas,
      colorScheme: const ColorScheme.dark(
        primary: CinemaTokens.accent,
        onPrimary: Colors.white,
        surface: CinemaTokens.surface,
        onSurface: CinemaTokens.primaryText,
        error: CinemaTokens.accent,
      ),
      textTheme: systemTextTheme,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      iconButtonTheme: const IconButtonThemeData(
        style: ButtonStyle(minimumSize: minimumSize),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        height: CinemaTokens.navHeight,
        backgroundColor: Colors.transparent,
        indicatorColor: Color(0x33FF3B30),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStatePropertyAll(
          IconThemeData(color: CinemaTokens.primaryText, size: 22),
        ),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            color: CinemaTokens.primaryText,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}
