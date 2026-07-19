# Task 2 implementation report

Status: **GREEN implementation prepared for GitHub macOS validation**

## Tests written before production

- `test/core/theme/cinema_theme_test.dart`
- `test/app/app_shell_test.dart`
- `test/golden/app_shell_golden_test.dart`

The tests specify the exact Cinema semantic tokens, dark/system theme,
44-point targets, reduced-motion policy, opaque accessibility fallback for
glass, default `/channel` routing, exact Chinese labels, 200% text behavior,
and the two required 390x844 goldens.

## Observed RED

Official GitHub macOS evidence:

- Workflow run: `29706191467`
- Job: `88243510219`
- Formatting passed.
- Analyze failed with 31 issues caused by the deliberately absent Task 2
  production files and symbols: `app/app.dart`, `CinemaTokens`, `CinemaTheme`,
  `GlassSurface`, `MotionPolicy`, `GuoguoApp`, and `createAppRouter`.

This is the expected missing-implementation failure required before GREEN.

## GREEN implementation

Added:

- immutable Cinema semantic tokens and dark system-font theme;
- 44-point minimum controls and Dynamic Type-safe styles;
- `MotionPolicy` honoring both `disableAnimations` and
  `accessibleNavigation`, with the specified 180ms reduced-motion timing;
- injectable Dart reduce-transparency stream and native Swift EventChannel;
- `GlassSurface` with blur plus opaque reduced-transparency/high-contrast
  fallback;
- a `StatefulShellRoute.indexedStack` with four independent navigator keys,
  `/channel` default, and exact labels `频道`, `搜索`, `收藏`, `我的`;
- Cinema Glass navigation shell, app wiring, and Xcode source registration;
- 390x844 default and 200% text/reduced-transparency golden test cases.

The implementation follows the installed Apple Design guidance: immediate
navigation feedback, restrained red emphasis, system typography, spatially
stable independent stacks, high contrast, reduced transparency, reduced
motion, and at least 44-point touch targets.

## Local checks

```text
HOME=$PWD/.tooling/home .tooling/flutter/bin/cache/dart-sdk/bin/dart format \
  --output=none --set-exit-if-changed lib test/core test/app test/golden \
  test/widget_test.dart
Formatted 13 files (0 changed) in 0.02 seconds.
```

The formatter also warned that `package:flutter_lints/flutter.yaml` could not
be resolved because the local project pub bootstrap is unavailable; formatting
itself completed successfully.

```text
git diff --check
(no output)

bash tool/task1_ci_contract_test.sh
(no output; exit 0)
```

Static inspections confirmed the original bundle identifier, matching Dart
and Swift EventChannel names, the Swift file's Xcode Sources membership, and
all four exact Chinese labels.

## Remote GREEN iteration 1

GitHub macOS run `29706521426` reached `flutter analyze` with only two
`const_with_non_const` errors: the new stateful `GuoguoApp` was still invoked
with `const` in `lib/main.dart` and the Task 1 generated-test template. Both
call sites were corrected without changing behavior, and the Task 1 contract
was updated to match the still-valid non-const smoke-test construction.

## Remote GREEN iteration 2

GitHub macOS run `29706748970` passed committed formatting, `flutter analyze`,
golden generation, all 10 tests, iOS engine precache, and CocoaPods. The
simulator build then identified one Swift type-safety issue: on pinned Flutter
3.44.6, `registrar(forPlugin:)` returns an optional. `AppDelegate` now unwraps
it with `guard let`, records a debug assertion if unavailable, and preserves
normal generated plugin registration before registering the accessibility
EventChannel.

## Golden typography correction

The first macOS-generated 390x844 images used Flutter's Ahem test font, which
intentionally has no Chinese glyphs and rendered the four labels as tofu
squares. Those images were rejected rather than committed. Flutter 3.44.6 then
rejected the attempted `--no-test-fonts` flag in run `29706932205` with exit
64, so the workflow remains on the supported plain `flutter test` command.

The golden test now loads PingFang from macOS using `FontLoader` under a stable
test-only family name (with two macOS CJK fallback paths). `CinemaTheme.dark`
accepts an optional font family and `GuoguoApp` accepts an optional `ThemeData`
for deterministic test injection. Production passes neither and therefore
continues to use native system typography. Only golden tests override Ahem;
ordinary widget tests remain platform-independent.

GitHub macOS run `29707074526` confirmed the approach reached analyze; its only
finding was an unnecessary explicit `dart:typed_data` import because
`flutter/services.dart` already exports `ByteData`. The redundant import was
removed without changing the font-loading behavior.

## Local runner constraint

The pinned Flutter SDK remains checked out at
`ee80f08bbf97172ec030b8751ceab557177a34a6`, but bootstrapping the local
Flutter tool is blocked while resolving its pub dependencies. Therefore no
local Flutter GREEN or golden PNG generation is claimed. The controller will
run format/analyze/tests/iOS simulator build and generate the two golden PNGs
on the official GitHub macOS runner before Task 2 is considered complete.
