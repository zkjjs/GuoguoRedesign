# Guoguo Apple Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 从已授权分析的 Guoguo IPA 和既有服务端契约出发，交付一个 iOS 15+、可维护、可测试、完整支持浏览与播放的 Flutter 客户端，并实现已确认的 Cinema Glass Apple 风格界面。

**Architecture:** Flutter 负责 UI、导航、领域状态和 API 适配；独立 iOS Flutter plugin 封装 AliyunPlayer、媒体下载和系统播放能力。功能模块只能依赖领域仓储接口，HTTP JSON、Keychain、SQLite 和原生 SDK 均位于基础设施边界。播放链路通过单一状态机串联详情、`PLAY-TOKEN`、`raw_play_url` 和播放器，不允许页面直接拼装播放请求。

**Tech Stack:** Flutter stable revision `ee80f08bbf97172ec030b8751ceab557177a34a6`、Dart、Riverpod、go_router、Dio、Drift/SQLite、flutter_secure_storage、Pigeon、Swift、XCTest、AliyunPlayer、Flutter unit/widget/golden/integration tests、GitHub Actions macOS runner。

## Global Constraints

- 目标系统为 iOS 15 及以上；保持现有 bundle identifier `com.example.dongmangongheguo`，除非签名配置明确要求新标识。
- 不恢复原 Flutter AOT 源码，不复制原页面，不把 DYYY Hook 注入新应用；DYYY 只作为已分析行为参考。
- 不提交真实账号、`X-Token`、`UserToken`、`PLAY-TOKEN`、签名、手机号、用户 ID、播放地址或授权测试响应。
- 从 IPA 提取的二进制只能在授权范围内使用；仓库只记录校验值和接入说明。优先使用版权方或阿里云提供的可再分发 SDK 包。
- 每个任务按红—绿—重构执行；测试失败信息必须先被观察，再写最小实现。
- 每个任务结束前运行该任务列出的定向测试；每个阶段结束使用固定 SDK 运行 `flutter analyze` 和完整 `flutter test`。
- 播放令牌最多自动刷新一次；播放地址只驻留内存，不写 SQLite、偏好、崩溃日志或测试快照。
- 频道分区、评论、投屏、下载、任务或金币失败不得中断基础浏览和播放。
- 所有玻璃效果都必须支持“降低透明度”的实色退化；所有大范围动效都必须支持“降低动态效果”。
- 不以阻断式弹窗呈现常规网络错误；错误必须附着到对应内容区域并提供重试。

---

## File and Module Map

```text
GuoguoRedesign/
├── .fvmrc
├── .github/workflows/ios.yml
├── analysis_options.yaml
├── pubspec.yaml
├── assets/
│   ├── branding/
│   └── fallback_artwork/
├── lib/
│   ├── main.dart
│   ├── app/
│   │   ├── app.dart
│   │   ├── bootstrap.dart
│   │   ├── router.dart
│   │   └── shell.dart
│   ├── core/
│   │   ├── auth/{auth_repository.dart,auth_session.dart,keychain_token_store.dart}
│   │   ├── database/{app_database.dart,tables.dart}
│   │   ├── network/{api_client.dart,api_error.dart,auth_interceptor.dart,redacting_log_interceptor.dart}
│   │   ├── sync/{offline_command.dart,offline_sync_service.dart}
│   │   ├── theme/{accessibility_preferences.dart,cinema_theme.dart,cinema_tokens.dart,glass_surface.dart,motion_policy.dart}
│   │   └── widgets/{async_section.dart,poster_card.dart,inline_error.dart}
│   └── features/
│       ├── channel/{data,domain,presentation}/
│       ├── search/{data,domain,presentation}/
│       ├── favorites/{data,domain,presentation}/
│       ├── profile/{data,domain,presentation}/
│       ├── video_detail/{data,domain,presentation}/
│       ├── player/{data,domain,presentation}/
│       ├── comments/{data,domain,presentation}/
│       ├── downloads/{data,domain,presentation}/
│       └── casting/{data,domain,presentation}/
├── packages/guoguo_player/
│   ├── pigeons/player_api.dart
│   ├── lib/{guoguo_player.dart,src/player_controller.dart,src/player_models.dart}
│   ├── ios/Classes/{GuoguoPlayerPlugin.swift,AliyunPlayerHostApi.swift,PlayerEventStream.swift}
│   ├── ios/guoguo_player.podspec
│   └── test/player_controller_test.dart
├── test/
│   ├── fixtures/
│   ├── core/
│   ├── features/
│   ├── golden/
│   └── helpers/
├── integration_test/{browse_playback_test.dart,offline_sync_test.dart}
├── ios/Runner/{AccessibilityPreferencesPlugin.swift,Info.plist,Runner.entitlements,SystemControlsPlugin.swift}
├── ios/RunnerTests/GuoguoPlayerBridgeTests.swift
└── tool/{bootstrap_flutter.sh,verify_no_secrets.sh}
```

## Milestone 1 — Reproducible Foundation

### Task 1: Bootstrap the pinned Flutter workspace and CI

**Files:**
- Create: `.fvmrc`
- Create: `tool/bootstrap_flutter.sh`
- Create: `pubspec.yaml`
- Create: `analysis_options.yaml`
- Create: `.github/workflows/ios.yml`
- Generate: `ios/**`, `lib/main.dart`, `test/widget_test.dart`
- Modify: `.gitignore`

- [ ] Write `tool/bootstrap_flutter_test.sh` first. It must fail when the checked-out Flutter revision differs:

```bash
#!/usr/bin/env bash
set -euo pipefail
expected="ee80f08bbf97172ec030b8751ceab557177a34a6"
actual="$(git -C .tooling/flutter rev-parse HEAD 2>/dev/null || true)"
test "$actual" = "$expected"
```

- [ ] Run `bash tool/bootstrap_flutter_test.sh`; expect non-zero exit because `.tooling/flutter` does not exist.
- [ ] Add `.fvmrc` with `{"flutterSdkVersion":"ee80f08bbf97172ec030b8751ceab557177a34a6"}` and implement `tool/bootstrap_flutter.sh` to clone `flutter/flutter`, checkout that revision, run `flutter doctor -v`, then `flutter pub get`. The script must be idempotent and reject a dirty SDK checkout.
- [ ] Run `bash tool/bootstrap_flutter.sh`; expect `flutter doctor` to report an available iOS toolchain on macOS, or a clearly isolated Xcode-only warning on non-macOS.
- [ ] Generate the application with:

```bash
.tooling/flutter/bin/flutter create --platforms=ios --org com.example --project-name guoguo .
.tooling/flutter/bin/flutter config --no-analytics
```

- [ ] Immediately replace the generated iOS bundle identifier with the user-confirmed original identifier `com.example.dongmangongheguo` in all Runner build configurations and tests; the Dart package name remains `guoguo`.
- [ ] Set the deployment target to iOS 15 in the Xcode project and Podfile. Add dependencies with `.tooling/flutter/bin/flutter pub add flutter_riverpod go_router dio flutter_secure_storage drift sqlite3_flutter_libs path_provider cached_network_image connectivity_plus share_plus collection` and dev dependencies with `.tooling/flutter/bin/flutter pub add --dev mocktail drift_dev build_runner pigeon golden_toolkit`.
- [ ] Replace the generated counter test with a smoke test asserting `GuoguoApp` renders four navigation destinations.
- [ ] Run `.tooling/flutter/bin/flutter test test/widget_test.dart`; expect failure because `GuoguoApp` is not implemented.
- [ ] Add the minimal `GuoguoApp` shell needed to make the smoke test pass; no feature UI yet.
- [ ] Add CI steps for format check, analyze, unit/widget tests, secret scan, `pod install`, and unsigned simulator build.
- [ ] Run `.tooling/flutter/bin/flutter analyze` and `.tooling/flutter/bin/flutter test`; expect zero errors and all tests passing.
- [ ] Commit:

```bash
git add .fvmrc .github analysis_options.yaml pubspec.yaml pubspec.lock lib test tool ios .gitignore
git commit -m "build: bootstrap pinned Flutter iOS workspace"
```

### Task 2: Build Cinema Glass tokens, accessibility policies, and app shell

**Files:**
- Create: `lib/core/theme/cinema_tokens.dart`
- Create: `lib/core/theme/cinema_theme.dart`
- Create: `lib/core/theme/motion_policy.dart`
- Create: `lib/core/theme/accessibility_preferences.dart`
- Create: `lib/core/theme/glass_surface.dart`
- Create: `ios/Runner/AccessibilityPreferencesPlugin.swift`
- Create: `lib/app/router.dart`
- Create: `lib/app/shell.dart`
- Modify: `lib/app/app.dart`
- Test: `test/core/theme/cinema_theme_test.dart`
- Test: `test/app/app_shell_test.dart`
- Golden: `test/golden/app_shell_default.png`
- Golden: `test/golden/app_shell_accessible.png`

- [ ] Write token tests asserting exact semantic colors and dimensions:

```dart
test('CinemaTokens reserve red for emphasis', () {
  expect(CinemaTokens.canvas, const Color(0xFF050506));
  expect(CinemaTokens.surface, const Color(0xFF121216));
  expect(CinemaTokens.primaryText, const Color(0xFFF5F5F7));
  expect(CinemaTokens.accent, const Color(0xFFFF3B30));
  expect(CinemaTokens.navHeight, 64);
});
```

- [ ] Run `.tooling/flutter/bin/flutter test test/core/theme/cinema_theme_test.dart`; expect missing `CinemaTokens` failure.
- [ ] Implement immutable tokens, a dark `ThemeData`, Dynamic Type-safe text styles, 44-point minimum hit targets, and `MotionPolicy.fromMediaQuery` using `disableAnimations` and `accessibleNavigation`.
- [ ] Implement `AccessibilityPreferencesPlugin` with an event channel backed by `UIAccessibility.isReduceTransparencyEnabled` and `UIAccessibility.reduceTransparencyStatusDidChangeNotification`. Expose it as an injectable `Stream<bool>` in Dart.
- [ ] Write widget tests that pump the app with `highContrast`, `disableAnimations`, and `textScaler: TextScaler.linear(2.0)`. Assert no overflow and four labels exactly: `频道`, `搜索`, `收藏`, `我的`.
- [ ] Run `.tooling/flutter/bin/flutter test test/app/app_shell_test.dart`; expect failure before shell/router implementation.
- [ ] Implement a stateful `ShellRoute` with independent navigation stacks and default `/channel`; use `NavigationBar` semantics but custom dark glass presentation. When `MediaQueryData.disableAnimations` is true, replace springs with 180 ms fades.
- [ ] Implement `GlassSurface` so the native reduce-transparency value or `MediaQueryData.highContrast` selects opaque `CinemaTokens.surface` instead of `BackdropFilter`.
- [ ] Generate and inspect two golden files at 390×844: default and 200% text/reduced transparency. Verify the tab bar remains tappable and labels are not clipped.
- [ ] Run `.tooling/flutter/bin/flutter test test/core/theme test/app test/golden`; expect pass.
- [ ] Commit:

```bash
git add lib/core/theme lib/app test/core/theme test/app test/golden
git commit -m "feat: add Cinema Glass theme and navigation shell"
```

## Milestone 2 — Stable Domain and Service Boundaries

### Task 3: Define media domain models and strict API decoding

**Files:**
- Create: `lib/features/video_detail/domain/media_models.dart`
- Create: `lib/features/video_detail/domain/video_repository.dart`
- Create: `lib/features/channel/domain/channel_models.dart`
- Create: `lib/core/network/api_error.dart`
- Create: `lib/features/video_detail/data/video_dto.dart`
- Create: `lib/features/video_detail/data/video_mapper.dart`
- Test: `test/features/video_detail/video_mapper_test.dart`
- Fixtures: `test/fixtures/video_list.json`, `test/fixtures/video_detail.json`

- [ ] Define the stable domain contract before DTOs:

```dart
typedef MediaId = String;

enum MediaKind { movie, series, anime }

final class EpisodeRef {
  const EpisodeRef({required this.lineId, required this.episodeId, required this.title});
  final String lineId;
  final String episodeId;
  final String title;
}

final class MediaSummary {
  const MediaSummary({
    required this.id,
    required this.title,
    required this.kind,
    required this.posterUrl,
    required this.year,
  });
  final MediaId id;
  final String title;
  final MediaKind kind;
  final Uri? posterUrl;
  final int? year;
}
```

- [ ] Write mapper tests for numeric/string IDs, missing poster, absent year, unknown media kind, empty episode line, and malformed envelope. Unknown optional fields must be ignored; missing required identity must return `ApiError.invalidPayload`.
- [ ] Run `.tooling/flutter/bin/flutter test test/features/video_detail/video_mapper_test.dart`; expect missing mapper failure.
- [ ] Implement DTOs that retain raw server keys only inside `data/`; map to immutable domain objects and normalize URLs with `Uri.tryParse`.
- [ ] Define `VideoRepository` with exact methods: `Future<MediaDetail> detail(MediaId id)`, `Future<Page<MediaSummary>> search(SearchQuery query)`, and `Future<List<ChannelSection>> channelSections()`.
- [ ] Run mapper tests and `.tooling/flutter/bin/dart format --output=none --set-exit-if-changed lib test`; expect pass.
- [ ] Commit:

```bash
git add lib/core/network lib/features/channel/domain lib/features/video_detail test/features/video_detail test/fixtures
git commit -m "feat: define media domain and API mapping"
```

### Task 4: Implement authenticated HTTP, Keychain storage, redaction, and one-shot refresh

**Files:**
- Create: `lib/core/auth/auth_session.dart`
- Create: `lib/core/auth/auth_repository.dart`
- Create: `lib/core/auth/keychain_token_store.dart`
- Create: `lib/core/network/api_client.dart`
- Create: `lib/core/network/auth_interceptor.dart`
- Create: `lib/core/network/redacting_log_interceptor.dart`
- Test: `test/core/network/auth_interceptor_test.dart`
- Test: `test/core/network/redacting_log_interceptor_test.dart`
- Test: `test/core/auth/keychain_token_store_test.dart`

- [ ] Define interfaces:

```dart
abstract interface class TokenStore {
  Future<String?> readUserToken();
  Future<void> writeUserToken(String value);
  Future<void> clear();
}

abstract interface class SessionRefresher {
  Future<String> refreshUserToken();
}
```

- [ ] Write Dio adapter tests proving every authenticated request gets `X-Token` and `UserToken` when available, concurrent 401 responses share one refresh future, replay occurs once, and a second 401 returns `ApiError.authenticationExpired` without recursion.
- [ ] Run `.tooling/flutter/bin/flutter test test/core/network/auth_interceptor_test.dart`; expect missing interceptor failure.
- [ ] Implement `AuthInterceptor` with a per-instance `Future<String>? _refreshing`; mark replayed requests with `extra['authRetried'] = true`.
- [ ] Write redaction tests for case-insensitive headers plus JSON/body/query keys `token`, `sign`, `mobile`, `user_id`, `raw_play_url`. Assert safe values remain visible and sensitive values become `[REDACTED]`.
- [ ] Implement `RedactingLogInterceptor`; it must receive cloned maps and never mutate the outgoing request.
- [ ] Implement `KeychainTokenStore` with iOS accessibility `first_unlock_this_device`; use an in-memory fake in tests.
- [ ] Run `.tooling/flutter/bin/flutter test test/core`; expect pass.
- [ ] Commit:

```bash
git add lib/core/auth lib/core/network test/core
git commit -m "feat: add secure authenticated API client"
```

### Task 5: Reconstruct and contract-test the playback address flow

**Files:**
- Create: `lib/features/player/domain/playback_request.dart`
- Create: `lib/features/player/domain/playback_source.dart`
- Create: `lib/features/player/domain/playback_repository.dart`
- Create: `lib/features/player/data/playback_api.dart`
- Create: `lib/features/player/data/playback_repository_impl.dart`
- Test: `test/features/player/playback_repository_test.dart`
- Fixtures: `test/fixtures/play_token.json`, `test/fixtures/play_address.json`
- Create: `docs/contracts/playback-address.md`

- [ ] Record the verified static contract in `docs/contracts/playback-address.md`: base host `https://vod.api.zshtys888.com`, token endpoint `/app/playaddr/get/token`, address endpoint `/app/playaddr/v3/get`, authorization header `PLAY-TOKEN`, and response field `raw_play_url`. Mark request parameter names and error codes as values to capture from an authorized test session, never as guessed production constants.
- [ ] Define the repository API:

```dart
abstract interface class PlaybackRepository {
  Future<PlaybackSource> resolve(PlaybackRequest request);
}

final class PlaybackSource {
  const PlaybackSource({required this.uri, required this.headers, required this.expiresAt});
  final Uri uri;
  final Map<String, String> headers;
  final DateTime? expiresAt;
}
```

- [ ] Write mock-adapter tests that assert call order `detail/episode context → token → address`, address request carries `PLAY-TOKEN`, `raw_play_url` is parsed as `Uri`, headers are allowlisted, and token expiry triggers exactly one new token request.
- [ ] Add negative tests for empty URL, non-http(s) URL, malformed token envelope, 401 twice, timeout, and cancelled request. Assert distinct `PlaybackFailureKind` values.
- [ ] Run `.tooling/flutter/bin/flutter test test/features/player/playback_repository_test.dart`; expect missing repository implementation failure.
- [ ] Implement the smallest adapter that passes fixtures. Keep `PlaybackSource` in memory only and override `toString()` so the URI and headers are redacted.
- [ ] Add an authorized-capture harness disabled by default through `--dart-define=GUOGUO_CONTRACT_CAPTURE=false`; when enabled, it may save only field names, types, status codes, and timing—never values.
- [ ] Run playback repository tests twice to catch hidden shared state; expect pass both times.
- [ ] Commit:

```bash
git add lib/features/player docs/contracts test/features/player test/fixtures
git commit -m "feat: implement secure playback address resolver"
```

### Task 6: Add local history, favorites, preferences, and ordered offline sync

**Files:**
- Create: `lib/core/database/tables.dart`
- Create: `lib/core/database/app_database.dart`
- Create: `lib/core/sync/offline_command.dart`
- Create: `lib/core/sync/offline_sync_service.dart`
- Create: `lib/features/favorites/data/favorites_repository_impl.dart`
- Create: `lib/features/video_detail/data/history_repository_impl.dart`
- Test: `test/core/database/app_database_test.dart`
- Test: `test/core/sync/offline_sync_service_test.dart`

- [ ] Write Drift tests for a watching-progress unique key `(mediaId, lineId, episodeId)`, favorite upsert, completed/uncompleted filtering, search history de-duplication, and cascade-free retention after logout.
- [ ] Run `.tooling/flutter/bin/flutter test test/core/database`; expect missing schema failure.
- [ ] Implement schema version 1 with tables `watch_progress`, `favorites`, `search_history`, `offline_commands`, and `user_preferences`. Explicitly exclude token and playback URL columns.
- [ ] Write sync tests proving commands execute oldest-first, retryable errors remain queued with incremented attempts, authentication errors pause the queue, and successful server state resolves last-write-wins conflicts using `updatedAt`.
- [ ] Implement `OfflineSyncService.flush()` with a transaction per command, exponential retry metadata but no background loop; connectivity/app-lifecycle callers trigger it.
- [ ] Run `.tooling/flutter/bin/dart run build_runner build --delete-conflicting-outputs`, then full database/sync tests.
- [ ] Commit:

```bash
git add lib/core/database lib/core/sync lib/features/favorites/data lib/features/video_detail/data test/core
git commit -m "feat: persist viewing state and offline sync queue"
```

## Milestone 3 — Native Playback Boundary

### Task 7: Create the typed AliyunPlayer Flutter plugin and state controller

**Files:**
- Create: `packages/guoguo_player/pubspec.yaml`
- Create: `packages/guoguo_player/pigeons/player_api.dart`
- Generate: `packages/guoguo_player/lib/src/generated/player_api.g.dart`
- Generate: `packages/guoguo_player/ios/Classes/GeneratedPlayerApi.g.swift`
- Create: `packages/guoguo_player/lib/src/player_models.dart`
- Create: `packages/guoguo_player/lib/src/player_controller.dart`
- Create: `packages/guoguo_player/ios/Classes/GuoguoPlayerPlugin.swift`
- Create: `packages/guoguo_player/ios/Classes/AliyunPlayerHostApi.swift`
- Create: `packages/guoguo_player/ios/Classes/PlayerEventStream.swift`
- Create: `packages/guoguo_player/ios/guoguo_player.podspec`
- Test: `packages/guoguo_player/test/player_controller_test.dart`
- Test: `ios/RunnerTests/GuoguoPlayerBridgeTests.swift`

- [ ] Define the Pigeon contract with commands `create`, `setSource`, `prepare`, `play`, `pause`, `seekTo`, `selectTrack`, `setRate`, `setMuted`, `startPictureInPicture`, `stopPictureInPicture`, and `dispose`; events carry `playerId`, sequence number, state, position, duration, buffering, available tracks, selected track, and sanitized error code.
- [ ] Define Dart states exactly:

```dart
sealed class PlaybackState { const PlaybackState(); }
final class PlaybackIdle extends PlaybackState { const PlaybackIdle(); }
final class PlaybackResolving extends PlaybackState { const PlaybackResolving(); }
final class PlaybackPreparing extends PlaybackState { const PlaybackPreparing(); }
final class PlaybackPlaying extends PlaybackState { const PlaybackPlaying(); }
final class PlaybackPaused extends PlaybackState { const PlaybackPaused(); }
final class PlaybackBuffering extends PlaybackState { const PlaybackBuffering(); }
final class PlaybackEnded extends PlaybackState { const PlaybackEnded(); }
final class PlaybackFailed extends PlaybackState {
  const PlaybackFailed(this.code);
  final String code;
}
```

- [ ] Write Dart tests with a fake host API for legal transitions, stale event sequence rejection, duplicate event coalescing, seek cancellation, source replacement, and dispose idempotency.
- [ ] Run `.tooling/flutter/bin/flutter test packages/guoguo_player/test`; expect missing controller failure.
- [ ] Generate Pigeon code and implement the Dart controller. It must never expose raw SDK objects or log source URIs.
- [ ] Write XCTest cases with a fake `AliyunPlayerProtocol` proving main-thread event delivery, one native player per ID, safe foreground/background transitions, and disposal after PiP stops.
- [ ] Implement Swift adapter against the authorized AliyunPlayer SDK. Store native instances in a dictionary owned by the plugin; remove on dispose and on engine detach.
- [ ] Add `AVAudioSession` playback configuration, PiP capability checks, and event sequence numbering. Unsupported PiP returns a typed capability error without stopping playback.
- [ ] Run Dart tests, `pod install`, and `xcodebuild test -workspace ios/Runner.xcworkspace -scheme Runner -destination 'platform=iOS Simulator,name=iPhone 16'`; expect pass.
- [ ] Commit:

```bash
git add packages/guoguo_player ios/RunnerTests ios/Podfile ios/Podfile.lock pubspec.yaml pubspec.lock
git commit -m "feat: add typed AliyunPlayer bridge"
```

## Milestone 4 — Browse and Account Experience

### Task 8: Implement the Channel page with independently loading shelves

**Files:**
- Create: `lib/features/channel/domain/channel_repository.dart`
- Create: `lib/features/channel/data/channel_repository_impl.dart`
- Create: `lib/features/channel/presentation/channel_controller.dart`
- Create: `lib/features/channel/presentation/channel_page.dart`
- Create: `lib/features/channel/presentation/featured_hero.dart`
- Create: `lib/features/channel/presentation/media_shelf.dart`
- Create: `lib/core/widgets/async_section.dart`
- Test: `test/features/channel/channel_controller_test.dart`
- Test: `test/features/channel/channel_page_test.dart`
- Golden: `test/golden/channel_page.png`

- [ ] Write controller tests proving hero, continue-watching, hot movies, latest episodes, and server categories load independently; failure of one section leaves successful sections visible.
- [ ] Write page tests asserting hero is manually swipeable, never starts a timer, never creates a player, and exposes `播放` and `加入片单` actions.
- [ ] Run channel tests; expect missing controller/page failures.
- [ ] Implement section-scoped `AsyncValue` state, viewport-triggered shelf fetching, next-screen image prefetch only, and `AsyncSection` inline retry.
- [ ] Use `PageView` with user drag only for the hero. Do not set `Timer`, auto-page calls, or preview autoplay.
- [ ] Build shelves in order: continue watching, hot movies, latest episodes, then configured categories. Show progress and remaining time only in continue watching; show update count only in latest episodes.
- [ ] Capture 390×844 and iPad 1024×1366 goldens. Verify 200% text does not cover hero actions.
- [ ] Run `.tooling/flutter/bin/flutter test test/features/channel test/golden`; expect pass.
- [ ] Commit:

```bash
git add lib/features/channel lib/core/widgets test/features/channel test/golden
git commit -m "feat: build resilient channel experience"
```

### Task 9: Implement search, debounce, filters, history, and pagination

**Files:**
- Create: `lib/features/search/domain/search_repository.dart`
- Create: `lib/features/search/domain/search_query.dart`
- Create: `lib/features/search/data/search_repository_impl.dart`
- Create: `lib/features/search/presentation/search_controller.dart`
- Create: `lib/features/search/presentation/search_page.dart`
- Create: `lib/features/search/presentation/search_filter_sheet.dart`
- Test: `test/features/search/search_controller_test.dart`
- Test: `test/features/search/search_page_test.dart`

- [ ] Use fake time to test a 350 ms debounce, cancellation of obsolete requests, explicit submit, local history de-duplication, and page cursor reset after filter changes.
- [ ] Test empty, loading, no-result, initial-error, and load-more-error states. Assert load-more failure preserves existing posters and offers inline retry.
- [ ] Run search tests; expect failures for missing feature classes.
- [ ] Implement `SearchQuery(term, kind, year, sort, cursor)` as a value object; normalize whitespace and reject empty network requests.
- [ ] Implement expandable system-style search field, hot terms/history when empty, responsive poster grid, and bottom glass filter sheet for type/year/sort.
- [ ] Ensure keyboard submit records history only after a non-empty query; clearing text cancels request and restores discovery state.
- [ ] Run `.tooling/flutter/bin/flutter test test/features/search`; expect pass.
- [ ] Commit:

```bash
git add lib/features/search test/features/search
git commit -m "feat: add searchable filtered catalog"
```

### Task 10: Implement Favorites and Profile, including membership and tasks

**Files:**
- Create: `lib/features/favorites/domain/favorites_repository.dart`
- Create: `lib/features/favorites/presentation/favorites_controller.dart`
- Create: `lib/features/favorites/presentation/favorites_page.dart`
- Create: `lib/features/profile/domain/profile_repository.dart`
- Create: `lib/features/profile/presentation/profile_page.dart`
- Create: `lib/features/profile/presentation/account_header.dart`
- Create: `lib/features/profile/presentation/profile_sections.dart`
- Create: `lib/features/profile/presentation/login_page.dart`
- Create: `lib/features/profile/presentation/history_page.dart`
- Create: `lib/features/profile/presentation/messages_page.dart`
- Create: `lib/features/profile/presentation/settings_page.dart`
- Create: `lib/features/profile/presentation/membership_page.dart`
- Create: `lib/features/profile/presentation/tasks_page.dart`
- Test: `test/features/favorites/favorites_controller_test.dart`
- Test: `test/features/profile/profile_page_test.dart`

- [ ] Write favorites tests for movie/series/anime tabs, all/unwatched/watched filters, optimistic local toggle, offline enqueue, server reconciliation, and logout retention.
- [ ] Write profile tests for guest and authenticated states. Assert membership expiry, history, downloads, messages, settings, tasks, and coins appear in Profile; assert no fifth bottom tab exists. Write login tests for validation, server rejection, successful Keychain persistence, cancellation, and post-login return to the originally gated action.
- [ ] Run favorites/profile tests; expect missing implementation failures.
- [ ] Implement favorites from local database first, then reconcile with `/app/collect*`; show a compact sync state without blocking browsing.
- [ ] Implement Profile using grouped iOS-style lists and an account header. Implement login, history, messages, settings, membership, and tasks routes. Gate membership sync and task actions behind login while keeping public browsing available.
- [ ] Map `/app/users/*`, `/app/vip_price/*`, and `/app/task/*` behind repository interfaces. Do not put response maps in widgets.
- [ ] Run `.tooling/flutter/bin/flutter test test/features/favorites test/features/profile`; expect pass.
- [ ] Commit:

```bash
git add lib/features/favorites lib/features/profile test/features/favorites test/features/profile
git commit -m "feat: add favorites and profile hubs"
```

## Milestone 5 — Detail and Playback Experience

### Task 11: Build video detail, source/episode selection, and shared player surface

**Files:**
- Create: `lib/features/video_detail/presentation/video_detail_controller.dart`
- Create: `lib/features/video_detail/presentation/video_detail_page.dart`
- Create: `lib/features/video_detail/presentation/source_episode_sheet.dart`
- Create: `lib/features/player/presentation/player_surface.dart`
- Create: `lib/features/player/presentation/player_controls.dart`
- Create: `lib/features/player/presentation/fullscreen_player_page.dart`
- Modify: `lib/app/router.dart`
- Test: `test/features/video_detail/video_detail_controller_test.dart`
- Test: `test/features/video_detail/video_detail_page_test.dart`
- Test: `test/features/player/player_controls_test.dart`

- [ ] Write controller tests covering detail load, initial episode selection, resolve/prepare/play, switch episode, switch line, one-shot token retry, auto-next, and progress save under `(mediaId,lineId,episodeId)`.
- [ ] Write UI tests asserting a 16:9 portrait player, metadata/actions/source/episode/summary/comments order, and a glass bottom sheet for lines/episodes.
- [ ] Write route tests proving portrait detail and landscape fullscreen reuse the same `PlayerSession` and do not re-resolve the URL on rotation.
- [ ] Run detail/player tests; expect missing controller and widgets.
- [ ] Implement `PlayerSession` as a Riverpod keep-alive object owned by the detail route, not by `PlayerSurface`. Dispose only when the detail route exits and PiP is inactive.
- [ ] Implement source/episode switching with cancellation generation IDs so late resolves cannot replace the current source.
- [ ] Implement controls: single-tap visibility, idle hide, play/pause, progress, next episode, quality, rate, danmaku, PiP, casting, lock, and fullscreen. Unsupported capabilities remain disabled with accessible labels.
- [ ] Preserve position through foreground/background and orientation changes. Save local progress at 10-second intervals, on pause, and on route exit; never save source URI.
- [ ] Run tests plus an iOS simulator build; expect pass.
- [ ] Commit:

```bash
git add lib/features/video_detail lib/features/player/presentation lib/app/router.dart test/features/video_detail test/features/player
git commit -m "feat: add detail and shared playback session"
```

### Task 12: Add cancellable fullscreen gestures and accessibility fallbacks

**Files:**
- Create: `lib/features/player/presentation/player_gesture_layer.dart`
- Create: `lib/features/player/presentation/gesture_feedback_overlay.dart`
- Create: `lib/features/player/domain/system_controls.dart`
- Create: `ios/Runner/SystemControlsPlugin.swift`
- Modify: `lib/features/player/presentation/fullscreen_player_page.dart`
- Test: `test/features/player/player_gesture_layer_test.dart`
- Golden: `test/golden/fullscreen_controls.png`

- [ ] Write gesture tests for horizontal seek, left brightness, right volume, lock mode, reverse drag, cancellation, and velocity threshold. Assert values track the finger continuously and commit only on pointer up.
- [ ] Test `disableAnimations=true`: overlays fade for 180 ms without translation or spring. Test large text and VoiceOver semantics for every control.
- [ ] Run gesture tests; expect missing gesture layer failure.
- [ ] Implement a gesture session that captures the starting value, previews deltas, clamps ranges, and calls one commit callback on end; cancellation restores the captured value.
- [ ] Use system brightness/volume adapters behind `SystemControls`; widget tests use fakes, while `SystemControlsPlugin.swift` changes screen brightness and player audio output on the main thread. Never alter values while player controls are locked.
- [ ] Capture fullscreen golden in landscape and inspect contrast against both bright and dark frames.
- [ ] Run `.tooling/flutter/bin/flutter test test/features/player test/golden/fullscreen_controls*`; expect pass.
- [ ] Commit:

```bash
git add lib/features/player/presentation test/features/player test/golden
git commit -m "feat: add accessible fullscreen player gestures"
```

### Task 13: Integrate comments, downloads, casting, sharing, and feedback as isolated capabilities

**Files:**
- Create: `lib/features/comments/domain/comments_repository.dart`
- Create: `lib/features/comments/presentation/comments_section.dart`
- Create: `lib/features/player/domain/danmaku_service.dart`
- Create: `lib/features/player/presentation/danmaku_layer.dart`
- Create: `lib/features/downloads/domain/download_service.dart`
- Create: `lib/features/downloads/presentation/downloads_page.dart`
- Create: `lib/features/casting/domain/casting_service.dart`
- Create: `lib/features/casting/presentation/casting_sheet.dart`
- Create: `lib/features/video_detail/presentation/share_feedback_actions.dart`
- Modify: `ios/Runner/Info.plist`
- Modify: `ios/Runner/Runner.entitlements`
- Test: `test/features/comments/comments_section_test.dart`
- Test: `test/features/player/danmaku_service_test.dart`
- Test: `test/features/downloads/download_service_test.dart`
- Test: `test/features/casting/casting_service_test.dart`

- [ ] Define capability interfaces before SDK wiring:

```dart
abstract interface class DownloadService {
  Stream<List<DownloadTask>> watchTasks();
  Future<void> enqueue(DownloadRequest request);
  Future<void> pause(String taskId);
  Future<void> resume(String taskId);
  Future<void> remove(String taskId);
}

abstract interface class CastingService {
  Stream<List<CastingDevice>> discover();
  Future<CastingSession> connect(CastingDevice device, PlaybackRequest request);
  Future<void> disconnect();
}

abstract interface class DanmakuService {
  Stream<List<DanmakuItem>> load(EpisodeRef episode);
  Future<void> send(EpisodeRef episode, Duration position, String text);
}
```

- [ ] Write comments tests for loading, empty, pagination failure, submit-login gate, and service failure while player remains mounted/playing.
- [ ] Write danmaku tests for timeline ordering, duplicate suppression, toggle persistence, send-login gate, and failure isolation. Assert danmaku failure leaves video playback and ordinary comments available.
- [ ] Write download tests for entitlement denial, queue persistence without raw URL, authorized re-resolution on resume, progress events, and file deletion confirmation.
- [ ] Write casting tests for permission denied, no devices, discovery failure, connect failure, and disconnect. Assert all failures stay inside the casting sheet.
- [ ] Run capability tests; expect missing implementations.
- [ ] Implement comments against `/app/vod_comment/*`; only authenticated submit is gated. Implement danmaku behind `DanmakuService`; if the authorized contract exposes no danmaku endpoint, use an empty supported state and disable send with a clear capability label instead of inventing an endpoint.
- [ ] Wrap AliyunMediaDownloader behind `DownloadService`; persist media/episode identifiers and task metadata, never the resolved playback URL or token.
- [ ] Implement local-network casting discovery behind `CastingService`; request Local Network permission only when opening the casting sheet. If the authorized SDK lacks required DLNA support, return `CastingCapability.unavailable` and keep local playback unchanged.
- [ ] Use `share_plus` for system share sheet. Feedback posts only explicit user text and sanitized diagnostics after confirmation.
- [ ] Add only required iOS permission strings and background modes; verify cold launch requests no permission.
- [ ] Run all capability tests and simulator smoke test; expect pass.
- [ ] Commit:

```bash
git add lib/features/comments lib/features/downloads lib/features/casting lib/features/video_detail/presentation ios/Runner test/features
git commit -m "feat: add isolated playback companion features"
```

## Milestone 6 — End-to-End Verification and Delivery

### Task 14: Add contract fixtures, security scanning, and failure-path integration tests

**Files:**
- Create: `test/helpers/fake_guoguo_server.dart`
- Create: `integration_test/browse_playback_test.dart`
- Create: `integration_test/offline_sync_test.dart`
- Create: `tool/verify_no_secrets.sh`
- Modify: `.github/workflows/ios.yml`
- Create: `docs/testing/authorized-contract-capture.md`

- [ ] Implement a fake server with deterministic routes for list/detail/search/token/address/collect/history/users/comments and switches for timeout, empty body, 401-once, 401-always, partial-section failure, and network restoration.
- [ ] Write an integration test that launches Channel, opens detail, selects an episode, resolves token/address, starts fake native playback, rotates fullscreen, pauses, returns portrait, and verifies position continuity.
- [ ] Write an offline integration test that favorites two media items, restores network, and verifies oldest-first sync and local state retention.
- [ ] Run both integration tests; expect failure until fake server and dependency overrides are connected.
- [ ] Connect dependency injection at `bootstrap.dart`; production uses real implementations, tests use the fake server and fake player host API.
- [ ] Implement `tool/verify_no_secrets.sh` to fail on known sensitive key/value patterns, `http(s)` media extensions in source/test snapshots, and accidentally staged IPA/framework binaries outside approved vendor paths. Exclude only documented fixtures containing redacted literals.
- [ ] Run `bash tool/verify_no_secrets.sh`; expect pass. Seed a temporary tracked sample secret, verify failure, then remove it and verify pass again.
- [ ] Update CI to run integration tests on an iOS simulator and upload only screenshots/test reports, never app data or network captures.
- [ ] Run `.tooling/flutter/bin/flutter analyze`, `.tooling/flutter/bin/flutter test`, secret scan, and integration tests; expect pass.
- [ ] Commit:

```bash
git add lib/app/bootstrap.dart test/helpers integration_test tool docs/testing .github/workflows/ios.yml
git commit -m "test: cover playback and offline flows end to end"
```

### Task 15: Profile performance, complete device acceptance, and produce the signed artifact

**Files:**
- Create: `docs/testing/device-matrix.md`
- Create: `docs/testing/performance-report.md`
- Create: `docs/release/release-checklist.md`
- Modify: `README.md`
- Modify: `pubspec.yaml`
- Modify: `ios/Runner/Info.plist`

- [ ] Document the exact acceptance matrix: iOS 15 device/simulator, current iOS device, small iPhone, standard iPhone, 120 Hz iPhone, and iPad; standard/200% text; Reduce Motion; Reduce Transparency; Bold Text; VoiceOver.
- [ ] Add a repeatable performance scenario: cold launch → Channel scroll through three shelves → detail → 60 seconds playback → fullscreen → portrait → background/foreground. Capture Flutter frame timings, memory warning behavior, image cache size, and player instance count.
- [ ] Verify p95 UI/raster frame build stays inside the active display budget during non-decoding UI interactions, no duplicate native player appears during rotation, and current playback survives an iOS memory warning.
- [ ] Test all required failure paths against the fake server and authorized environment: timeout, empty response, expired user token, expired play token, bad line, comment outage, casting outage, and offline recovery.
- [ ] Run the complete automated suite:

```bash
.tooling/flutter/bin/dart format --output=none --set-exit-if-changed lib packages test integration_test
.tooling/flutter/bin/flutter analyze
.tooling/flutter/bin/flutter test
bash tool/verify_no_secrets.sh
.tooling/flutter/bin/flutter test integration_test -d "iPhone 16"
```

- [ ] Build unsigned first: `.tooling/flutter/bin/flutter build ios --simulator`; expect a launchable `.app` with no missing framework or architecture errors.
- [ ] On the authorized signing machine, set the approved team/profile and run `.tooling/flutter/bin/flutter build ipa --release --export-options-plist=ios/ExportOptions.plist`. Verify signature, entitlements, bundle ID, version, and minimum OS before distribution.
- [ ] Install on each acceptance device and complete `docs/testing/device-matrix.md`; every critical path must be checked, and any waiver must link to a tracked issue.
- [ ] Update README with reproducible bootstrap/build/test steps, SDK licensing boundary, environment injection, and troubleshooting for player framework linking.
- [ ] Commit documentation and release metadata only; never commit the signed IPA:

```bash
git add README.md pubspec.yaml ios/Runner/Info.plist docs/testing docs/release
git commit -m "docs: complete iOS release verification"
```

## Final Definition of Done

- [ ] Four root tabs render exactly as approved and Channel is the default.
- [ ] Authorized account can log in, browse, search, favorite, resolve an episode, and play it through AliyunPlayer.
- [ ] Player state survives orientation and foreground/background transitions without duplicate address resolution.
- [ ] 线路/选集、清晰度、倍速、弹幕（danmaku）、画中画（PiP）、投屏、下载、分享、反馈、评论和自动下一集均具有经过测试的成功与失败行为。
- [ ] Token refresh is bounded to one retry and all sensitive values are absent from logs, database, snapshots, Git history, and CI artifacts.
- [ ] Partial service failures never stop unrelated shelves or active playback.
- [ ] Standard and accessibility goldens are approved; device matrix is complete.
- [ ] Pinned-SDK `dart format`, `flutter analyze`, unit/widget/golden/integration tests, native XCTest, secret scan, simulator build, and release IPA build all pass.

