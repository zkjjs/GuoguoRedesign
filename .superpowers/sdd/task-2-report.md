# Task 2 implementation report

Status: **DONE — GitHub macOS GREEN and goldens visually approved**

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

GitHub macOS run `29707166898` then passed analyze, all tests, CocoaPods, and
the unsigned simulator build. Visual inspection confirmed Chinese labels were
correct and unclipped at both 100% and 200%, but Flutter's test font still
replaced Material icons with tofu squares. The golden setup now also loads
`MaterialIcons-Regular.otf` into the exact `MaterialIcons` family. It locates
the pinned SDK from `FLUTTER_ROOT`, `Platform.resolvedExecutable`, or the local
`.tooling/flutter` checkout, and fails explicitly if the deterministic asset
is unavailable. The otherwise-green tofu-icon images were not committed.

## Final GREEN verification

Official GitHub macOS run `29707543417`, job `88246932475`, completed every
step successfully using the original committed workflow and committed golden
baselines:

- bootstrap contracts;
- committed Dart format check;
- `flutter analyze` with zero issues;
- all 10 unit, widget, and golden tests;
- iOS engine precache;
- CocoaPods install;
- unsigned iOS simulator build.

Both final PNGs are exactly 390x844. Visual inspection approved correct Chinese
and Material icon rendering, unclipped navigation labels at default and 200%
text scaling, and the opaque accessible material fallback.

```text
8ab9dfb2b96a5cd903050c49cc69ae660adead3f6e16b8fe84ac80d62a2d0c8d  test/golden/app_shell_default.png
8b793cc64b1e3dec4b032c95947a304a748b92ac1bb6ff9de87da14c58abf645  test/golden/app_shell_accessible.png
```

## Independent review fixes

The Task 2 independent review found one Important and three Minor issues. All
four received tests-first fixes:

- Reduced-motion mode now reads `MotionPolicy.usesFadeOnly` in `AppShell`,
  disables the Material `NavigationBar` indicator animation with
  `Duration.zero`, and applies an actual linear 180ms opacity-only transition
  to branch content. It uses the same `StatefulNavigationShell` instance, so
  independent branch stacks remain intact, and restores opacity from a guarded
  post-frame callback only while mounted.
- The 200% accessibility test now fails on every captured Flutter framework
  error, not only overflow strings. It also asserts the zero-duration
  NavigationBar animation and the 180ms opacity-only content path with no
  slide or scale transition.
- `createAppRouter()` allocates all five navigator keys inside each factory
  call. A widget test mounts two live app routers together and checks for no
  duplicate-key exception.
- `GuoguoApp` no longer constructs a router in its widget constructor. Its
  State lazily creates an owned router, preserves it across equivalent widget
  rebuilds, disposes it before a changed router configuration, and disposes the
  current owned router on unmount. A tracking-router widget test covers lazy
  creation, replacement, and final disposal.

GitHub macOS run `29707986547` found that `GoRouter` exposes a factory
constructor and therefore cannot be subclassed by the initial tracking test.
The lifecycle test now uses real `GoRouter` instances and Flutter's supported
`ChangeNotifier.debugAssertNotDisposed` signal on each `routerDelegate`: it is
true while owned, and throws `FlutterError` after replacement and unmount.
Factory-call counts continue to prove lazy construction.

GitHub macOS run `29708102107` passed analyze but exposed an unbounded settle in
the new review tests. The two-router coexistence test now uses one explicit
bounded pump instead of `pumpAndSettle`. The reduced-motion test uses bounded
initial pumps, then explicitly builds the post-frame opacity target and advances
the full 180ms animation so no transient callback or animation remains pending.

## Local runner constraint

The pinned Flutter SDK remains checked out at
`ee80f08bbf97172ec030b8751ceab557177a34a6`, but bootstrapping the local
Flutter tool is blocked while resolving its pub dependencies. Therefore no
local Flutter GREEN or golden PNG generation is claimed. The final macOS run
above supplies the authoritative GREEN and visual evidence.
