# Apple Glass Home Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first reviewable Flutter home screen using the approved connected Apple-style frosted glass dock, soft capsule curvature, light background, mock media content, and reusable visual components.

**Architecture:** Keep `main.dart` limited to bootstrap and app theme. Put the home screen under `lib/ui/home/` and shared glass primitives under `lib/ui/components/`. Use only Flutter SDK/Cupertino APIs already available in the project; mock artwork is rendered with gradients so no network or asset dependency is required for this milestone.

**Tech Stack:** Flutter 3.44.6, Dart, Cupertino icons, BackdropFilter/ImageFilter, widget tests, GitHub Actions iOS build.

## Global Constraints

- UI-only milestone: no production API, authentication, persistence, or Aliyun player integration.
- Light iOS-style background with subtle cool gradients.
- Use system-like blue as primary accent.
- Glass surfaces must use real `BackdropFilter` blur, translucent white fill, hairline border, and broad low-opacity shadow.
- Bottom navigation must be one connected floating glass dock.
- No default Material `NavigationBar` appearance.
- Layout must be scrollable and safe-area aware on iPhone-sized screens.

---

### Task 1: Glass primitives and theme

**Files:**
- Modify: `lib/main.dart`
- Create: `lib/ui/components/apple_glass_surface.dart`
- Test: `test/widget_test.dart`

**Interfaces:**
- Produces: `AppleGlassSurface({required Widget child, double borderRadius, EdgeInsetsGeometry? padding})`.
- Produces: `GuoguoApp` with Cupertino-like light theme and system-blue accent.

- [ ] **Step 1: Write a failing widget smoke test**

```dart
await tester.pumpWidget(const GuoguoApp());
expect(find.text('首页'), findsOneWidget);
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget_test.dart`
Expected: FAIL because the current bootstrap renders only `Guoguo`.

- [ ] **Step 3: Implement the shared glass surface and bootstrap theme**

Use `ClipRRect`, `BackdropFilter(filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24))`, translucent `Color(0xB8FFFFFF)`, a white hairline border, and low-opacity broad shadow. Keep bootstrap logic in `main.dart` and route to `HomeScreen`.

- [ ] **Step 4: Run formatting and analysis**

Run: `dart format lib test && flutter analyze`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/main.dart lib/ui/components/apple_glass_surface.dart test/widget_test.dart
git commit -m "feat: add Apple glass visual foundation"
```

### Task 2: Home content and connected floating dock

**Files:**
- Create: `lib/ui/home/home_screen.dart`
- Create: `lib/ui/home/widgets/glass_search_bar.dart`
- Create: `lib/ui/home/widgets/hero_media_card.dart`
- Create: `lib/ui/home/widgets/continue_watching_card.dart`
- Create: `lib/ui/home/widgets/media_shelf.dart`
- Create: `lib/ui/home/widgets/floating_glass_dock.dart`
- Modify: `test/widget_test.dart`

**Interfaces:**
- Produces: `HomeScreen`.
- Produces: `FloatingGlassDock({required int selectedIndex, required ValueChanged<int> onSelected})`.
- Consumes: `AppleGlassSurface`.

- [ ] **Step 1: Add a failing dock interaction test**

```dart
await tester.pumpWidget(const GuoguoApp());
await tester.tap(find.text('搜索').last);
await tester.pumpAndSettle();
final selected = tester.widget<Icon>(find.byIcon(CupertinoIcons.search).last);
expect(selected.color, const Color(0xFF007AFF));
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/widget_test.dart`
Expected: FAIL because the dock does not yet exist.

- [ ] **Step 3: Implement the home screen hierarchy**

Build a safe-area `Stack` with a scrollable content column and bottom padding for the floating dock. Add: title, frosted search field, large gradient hero card, continue-watching shelf with progress, media glass cards, poster shelf. Use mock gradients instead of external image URLs.

- [ ] **Step 4: Implement the connected glass dock**

Use a single `AppleGlassSurface` container with height about 78 logical pixels and a very soft pill silhouette. Render Home / Library / History / Search / Settings using Cupertino icons. Selection is blue icon/text plus a subtle translucent internal highlight; do not split the dock into separate bubbles.

- [ ] **Step 5: Run tests and analysis**

Run: `dart format lib test && flutter analyze && flutter test`
Expected: all PASS.

- [ ] **Step 6: Commit**

```bash
git add lib test
git commit -m "feat: build Apple glass home screen"
```

### Task 3: CI build verification

**Files:**
- Modify only if required: `.github/workflows/ios.yml`

**Interfaces:**
- Consumes: committed Flutter source.
- Produces: successful GitHub Actions analyze/test/iOS unsigned build and IPA artifact.

- [ ] **Step 1: Push the feature branch and inspect workflow run**

Expected checks: `flutter analyze`, `flutter test`, `flutter build ios --release --no-codesign`.

- [ ] **Step 2: If CI reports a source error, fix only the failing source and rerun**

Use the exact failing job log as the source of truth; do not make unrelated changes.

- [ ] **Step 3: Verify artifact output**

Expected artifact: `GuoguoRedesign-unsigned-ipa`.

- [ ] **Step 4: Final commit if CI fixes were required**

```bash
git add .
git commit -m "fix: pass Apple glass home iOS CI"
```
