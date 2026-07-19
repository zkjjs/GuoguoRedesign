import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guoguo/app/app.dart';

void main() {
  Future<void> setPhoneSurface(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets('Cinema shell default golden', (tester) async {
    await setPhoneSurface(tester);
    final router = createAppRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      RepaintBoundary(
        key: const Key('golden'),
        child: GuoguoApp(
          router: router,
          reduceTransparencyChanges: const Stream<bool>.empty(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(const Key('golden')),
      matchesGoldenFile('app_shell_default.png'),
    );
  });

  testWidgets('Cinema shell accessible golden', (tester) async {
    await setPhoneSurface(tester);
    final router = createAppRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      RepaintBoundary(
        key: const Key('golden'),
        child: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            highContrast: true,
            disableAnimations: true,
            accessibleNavigation: true,
            textScaler: TextScaler.linear(2),
          ),
          child: GuoguoApp(
            router: router,
            reduceTransparencyChanges: Stream<bool>.value(true),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(const Key('golden')),
      matchesGoldenFile('app_shell_accessible.png'),
    );
  });
}
