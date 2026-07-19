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
    await tester.pump();
    await tester.pump();

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
    await tester.pump();
    await tester.pump();
    expect(tester.takeException(), isNull);

    expect(find.text('频道'), findsWidgets);
    expect(find.text('搜索'), findsOneWidget);
    expect(find.text('收藏'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);

    final reducedNavigationBar = tester.widget<NavigationBar>(
      find.byType(NavigationBar),
    );
    expect(reducedNavigationBar.animationDuration, Duration.zero);

    await tester.tap(find.text('搜索'));
    await tester.pump();

    final fade = tester.widget<AnimatedOpacity>(
      find.byKey(const Key('reducedMotionBranchFade')),
    );
    expect(fade.duration, const Duration(milliseconds: 180));
    expect(fade.opacity, 0);
    expect(
      find.descendant(
        of: find.byKey(const Key('reducedMotionBranchFade')),
        matching: find.byType(SlideTransition),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('reducedMotionBranchFade')),
        matching: find.byType(ScaleTransition),
      ),
      findsNothing,
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 180));
    expect(tester.takeException(), isNull);
    expect(router.routeInformationProvider.value.uri.path, '/search');

    final searchTarget = tester.getSize(
      find.byWidgetPredicate(
        (widget) => widget is NavigationDestination && widget.label == '搜索',
      ),
    );
    expect(searchTarget.width, greaterThanOrEqualTo(44));
    expect(searchTarget.height, greaterThanOrEqualTo(44));
  });

  testWidgets('two app routers can coexist without sharing navigator keys', (
    tester,
  ) async {
    final first = createAppRouter();
    final second = createAppRouter();
    addTearDown(first.dispose);
    addTearDown(second.dispose);

    await tester.pumpWidget(
      Row(
        textDirection: TextDirection.ltr,
        children: [
          Expanded(
            child: GuoguoApp(
              router: first,
              reduceTransparencyChanges: const Stream<bool>.empty(),
            ),
          ),
          Expanded(
            child: GuoguoApp(
              router: second,
              reduceTransparencyChanges: const Stream<bool>.empty(),
            ),
          ),
        ],
      ),
    );
    await tester.pump();

    expect(find.byType(NavigationBar), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('owned router is created lazily and disposed when replaced', (
    tester,
  ) async {
    var factoryCalls = 0;
    late GoRouter first;
    late GoRouter second;

    final initialApp = GuoguoApp(
      routerFactory: () {
        factoryCalls += 1;
        first = createLifecycleRouter();
        return first;
      },
      reduceTransparencyChanges: const Stream<bool>.empty(),
    );
    expect(factoryCalls, 0);

    await tester.pumpWidget(initialApp);
    expect(factoryCalls, 1);
    expect(ChangeNotifier.debugAssertNotDisposed(first.routerDelegate), isTrue);

    await tester.pumpWidget(
      GuoguoApp(
        routerFactory: () {
          factoryCalls += 1;
          second = createLifecycleRouter();
          return second;
        },
        reduceTransparencyChanges: const Stream<bool>.empty(),
      ),
    );
    expect(factoryCalls, 2);
    expect(
      () => ChangeNotifier.debugAssertNotDisposed(first.routerDelegate),
      throwsFlutterError,
    );
    expect(
      ChangeNotifier.debugAssertNotDisposed(second.routerDelegate),
      isTrue,
    );

    await tester.pumpWidget(const SizedBox());
    expect(
      () => ChangeNotifier.debugAssertNotDisposed(second.routerDelegate),
      throwsFlutterError,
    );
  });
}

GoRouter createTestRouter() => createAppRouter();

GoRouter createLifecycleRouter() => GoRouter(
  initialLocation: '/',
  routes: [GoRoute(path: '/', builder: (context, state) => const SizedBox())],
);
