import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:guoguo/app/app.dart';

void main() {
  testWidgets('shell defaults to channel and renders exact Chinese labels', (
    tester,
  ) async {
    final router = createTestRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      GuoguoApp(
        router: router,
        reduceTransparencyChanges: const Stream<bool>.empty(),
      ),
    );
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/channel');
    final navigationBar = tester.widget<NavigationBar>(
      find.byType(NavigationBar),
    );
    expect(
      navigationBar.destinations.cast<NavigationDestination>().map(
        (destination) => destination.label,
      ),
      orderedEquals(['频道', '搜索', '收藏', '我的']),
    );
    expect(navigationBar.selectedIndex, 0);
  });

  testWidgets('shell remains usable with accessibility settings at 200%', (
    tester,
  ) async {
    final router = createTestRouter();
    addTearDown(router.dispose);
    final errors = <FlutterErrorDetails>[];
    final previousHandler = FlutterError.onError;
    FlutterError.onError = errors.add;
    addTearDown(() => FlutterError.onError = previousHandler);

    await tester.pumpWidget(
      MediaQuery(
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
    );
    await tester.pumpAndSettle();

    expect(find.text('频道'), findsWidgets);
    expect(find.text('搜索'), findsOneWidget);
    expect(find.text('收藏'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);
    expect(
      errors.where((error) => error.exceptionAsString().contains('overflow')),
      isEmpty,
    );

    await tester.tap(find.text('搜索'));
    await tester.pump(const Duration(milliseconds: 180));
    expect(router.routeInformationProvider.value.uri.path, '/search');

    final searchTarget = tester.getSize(
      find.byWidgetPredicate(
        (widget) => widget is NavigationDestination && widget.label == '搜索',
      ),
    );
    expect(searchTarget.width, greaterThanOrEqualTo(44));
    expect(searchTarget.height, greaterThanOrEqualTo(44));
  });
}

GoRouter createTestRouter() => createAppRouter();
