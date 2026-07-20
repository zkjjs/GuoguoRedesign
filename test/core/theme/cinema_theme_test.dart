import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guoguo/core/theme/cinema_theme.dart';
import 'package:guoguo/core/theme/cinema_tokens.dart';
import 'package:guoguo/core/theme/glass_surface.dart';
import 'package:guoguo/core/theme/motion_policy.dart';

void main() {
  test('CinemaTokens reserve red for emphasis', () {
    expect(CinemaTokens.canvas, const Color(0xFF050506));
    expect(CinemaTokens.surface, const Color(0xFF121216));
    expect(CinemaTokens.primaryText, const Color(0xFFF5F5F7));
    expect(CinemaTokens.accent, const Color(0xFFFF3B30));
    expect(CinemaTokens.navHeight, 64);
  });

  test('CinemaTheme provides dark system typography and 44 point targets', () {
    final theme = CinemaTheme.dark();

    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, CinemaTokens.canvas);
    expect(theme.colorScheme.primary, CinemaTokens.accent);
    expect(theme.textTheme.bodyLarge?.fontFamily, isNull);
    expect(theme.materialTapTargetSize, MaterialTapTargetSize.padded);
    expect(
      theme.iconButtonTheme.style?.minimumSize?.resolve(<WidgetState>{}),
      const Size.square(CinemaTokens.minimumHitTarget),
    );
  });

  testWidgets('MotionPolicy replaces motion with a 180ms fade', (tester) async {
    late MotionPolicy policy;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          disableAnimations: true,
          accessibleNavigation: true,
        ),
        child: Builder(
          builder: (context) {
            policy = MotionPolicy.fromMediaQuery(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(policy.reduceMotion, isTrue);
    expect(policy.transitionDuration, const Duration(milliseconds: 180));
    expect(policy.usesFadeOnly, isTrue);
  });

  testWidgets('GlassSurface is blurred by default', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GlassSurface(child: SizedBox(width: 100, height: 100)),
        ),
      ),
    );

    expect(find.byType(BackdropFilter), findsOneWidget);
  });

  testWidgets('GlassSurface becomes opaque for reduced transparency', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(highContrast: true),
          child: Scaffold(
            body: GlassSurface(child: SizedBox(width: 100, height: 100)),
          ),
        ),
      ),
    );

    expect(find.byType(BackdropFilter), findsNothing);
    final decoratedBox = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byType(GlassSurface),
        matching: find.byType(DecoratedBox),
      ),
    );
    final decoration = decoratedBox.decoration as BoxDecoration;
    expect(decoration.color, CinemaTokens.surface);
  });
}
