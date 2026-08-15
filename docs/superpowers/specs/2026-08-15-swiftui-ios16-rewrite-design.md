# SwiftUI iOS 16 Rewrite Design

## Goal

Build a new native iOS client in SwiftUI with a minimum deployment target of iOS 16.0, while preserving the existing Guoguo backend protocol and recreating the approved Apple-style glass visual language with native iOS components.

## Scope

This is a full client rewrite, not a Flutter port. The new app will replace the current Flutter UI, state handling, navigation, networking, storage, and player integration with native Swift code.

The existing Flutter implementation remains untouched as a visual/reference branch. The SwiftUI work lives on `rewrite/swiftui-ios16`.

## Compatibility

- Minimum deployment target: iOS 16.0.
- Must run on iOS 16.0.2.
- Avoid APIs introduced after iOS 16 unless guarded by availability checks with an iOS 16 fallback.
- Use SwiftUI for screens and navigation.
- Use UIKit wrappers only where required by third-party player SDKs or APIs unavailable directly in SwiftUI.

## Architecture

```text
GuoguoSwift/
├── App/
│   ├── GuoguoApp.swift
│   ├── AppState.swift
│   └── AppRouter.swift
├── Core/
│   ├── Network/
│   │   ├── APIClient.swift
│   │   ├── APIEndpoint.swift
│   │   ├── APIRequest.swift
│   │   ├── APIError.swift
│   │   └── AuthSession.swift
│   ├── Storage/
│   │   ├── TokenStore.swift
│   │   ├── HistoryStore.swift
│   │   └── SettingsStore.swift
│   └── Models/
├── DesignSystem/
│   ├── GlassSurface.swift
│   ├── FloatingGlassDock.swift
│   ├── MediaCard.swift
│   └── AppTheme.swift
├── Features/
│   ├── Home/
│   ├── Search/
│   ├── VideoDetail/
│   ├── Collection/
│   ├── History/
│   ├── Account/
│   ├── Task/
│   ├── VIP/
│   └── Settings/
└── Player/
    ├── PlayerController.swift
    ├── PlayerView.swift
    └── AliyunPlayerAdapter.swift
```

## Networking

Use `URLSession` with Swift concurrency (`async/await`) rather than a third-party networking framework.

`APIClient` is the only layer allowed to perform HTTP requests. Feature modules call typed endpoint methods and receive decoded Swift models.

Authentication and playback headers are centralized in `AuthSession` / request construction. The client must be able to support protocol fields observed in the original app, including ordinary authorization tokens, cookies, `X-Token`, and playback-specific tokens such as `PLAY-TOKEN`, without scattering header logic across views.

No request parameter or signing behavior will be guessed. Each migrated endpoint must be verified against the original app behavior before it is considered complete.

## Backend Migration Order

### Phase 1: Core viewing path

1. App configuration
2. Banners
3. Channels / home video list
4. Video search
5. Video detail
6. Video play metadata
7. Playback token / play-address resolution
8. Player start / pause / seek / resume

### Phase 2: User state

1. Login / logout
2. User info
3. Collection / favorites
4. History
5. Profile update and account actions

### Phase 3: Extended features

1. Tasks / sign-in rules
2. VIP pricing / ticket exchange / purchase flow
3. Comments
4. Danmaku
5. Reports / message box

## Playback

Player code is isolated behind a native `PlayerController` interface so SwiftUI does not depend on SDK-specific APIs.

Conceptual interface:

```swift
@MainActor
protocol VideoPlayerControlling: AnyObject {
    var state: PlayerState { get }
    func load(_ source: PlaybackSource) async throws
    func play()
    func pause()
    func seek(to seconds: Double)
    func stop()
}
```

If AliyunPlayer is required, it is wrapped in `AliyunPlayerAdapter` and surfaced to SwiftUI with `UIViewRepresentable` only where necessary.

## UI Direction

- Native light iOS appearance.
- Soft Apple-style continuous capsule curvature.
- Connected floating glass bottom dock.
- System blue primary accent.
- Real native materials/blur where iOS 16 supports them; custom translucent layering only where needed to match the approved reference.
- System typography, safe areas, haptics, sheets, menus, navigation transitions, and controls should feel native rather than imitate UIKit through custom drawing.

## State Management

Use small `ObservableObject` view models on iOS 16. Do not depend on the iOS 17 Observation framework.

Global app state is limited to authentication/session, selected root destination, and cross-feature shared user state. Feature-specific loading/error/content state stays within each feature view model.

## Storage

- Sensitive tokens: Keychain.
- Lightweight user preferences: UserDefaults.
- Viewing history / cached metadata: begin with a small repository abstraction so storage can later use Core Data or SQLite without changing feature APIs.

## Error Handling

The networking layer exposes typed transport, HTTP, decoding, authentication, and backend errors. Views render explicit loading, empty, retry, and authentication-required states.

Playback failures must distinguish between play-address resolution errors and player-engine errors.

## Testing

- Unit tests for endpoint construction and decoding.
- Unit tests for auth/playback header injection.
- Unit tests for view-model state transitions.
- UI smoke tests for root navigation, search, details, collection, history, and settings.
- GitHub Actions builds the iOS 16-compatible app with `xcodebuild` and packages an unsigned `.app` / IPA artifact for installation testing.

## First Deliverable

The first native milestone is considered successful when:

1. A standalone SwiftUI app project builds for iOS 16.0.
2. The connected Apple-style glass root dock works.
3. Home, Search, Detail, Collection, History, and Settings are native SwiftUI screens.
4. The networking foundation is present and the first verified public/configuration endpoints can be called without hardcoded mock UI state.
5. GitHub Actions produces an unsigned iOS artifact.

Playback and authenticated endpoints are added only after their exact request/response behavior is verified.