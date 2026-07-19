import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guoguo/app/app.dart';
import 'package:guoguo/core/theme/cinema_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late String goldenFontFamily;

  setUpAll(() async {
    goldenFontFamily = await loadMacOsCjkGoldenFont();
    await loadMaterialIconsGoldenFont();
  });

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
          theme: CinemaTheme.dark(fontFamily: goldenFontFamily),
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
            theme: CinemaTheme.dark(fontFamily: goldenFontFamily),
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

Future<String> loadMacOsCjkGoldenFont() async {
  const family = 'GuoguoGoldenCJK';
  const candidates = [
    '/System/Library/Fonts/PingFang.ttc',
    '/System/Library/Fonts/STHeiti Medium.ttc',
    '/System/Library/Fonts/Supplemental/Songti.ttc',
  ];

  for (final path in candidates) {
    final file = File(path);
    if (!file.existsSync()) {
      continue;
    }

    final loader = FontLoader(family);
    loader.addFont(
      file.readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
    );
    await loader.load();
    return family;
  }

  throw StateError(
    'A deterministic macOS CJK font is required for shell goldens.',
  );
}

Future<void> loadMaterialIconsGoldenFont() async {
  final executable = File(Platform.resolvedExecutable);
  final derivedFlutterRoot = executable.parent.parent.parent.parent.parent.path;
  final configuredFlutterRoot = Platform.environment['FLUTTER_ROOT'];
  final roots = <String>{
    if (configuredFlutterRoot != null && configuredFlutterRoot.isNotEmpty)
      configuredFlutterRoot,
    derivedFlutterRoot,
    '${Directory.current.path}/.tooling/flutter',
  };

  for (final root in roots) {
    final file = File(
      '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    );
    if (!file.existsSync()) {
      continue;
    }

    final loader = FontLoader('MaterialIcons');
    loader.addFont(
      file.readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
    );
    await loader.load();
    return;
  }

  throw StateError(
    'Pinned Flutter MaterialIcons-Regular.otf is required for shell goldens.',
  );
}
