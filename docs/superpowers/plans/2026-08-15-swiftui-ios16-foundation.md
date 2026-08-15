# SwiftUI iOS 16 Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first standalone native SwiftUI Guoguo client that targets iOS 16.0, reproduces the approved Apple-glass root experience, establishes the backend transport layer, and produces an unsigned IPA in GitHub Actions.

**Architecture:** The new native app lives under `GuoguoSwift/` and does not reuse Flutter runtime code. SwiftUI views use `ObservableObject`/`@StateObject` for iOS 16 compatibility, while networking is isolated behind `APIClient` using `URLSession` and Swift concurrency. The first milestone uses verified endpoint paths only; request bodies, signing rules, authenticated endpoints, and playback resolution remain disabled until their exact protocol contracts are verified from the original client.

**Tech Stack:** Swift 5.9-compatible source, SwiftUI, UIKit only for compatibility bridges, URLSession, async/await, XCTest, Xcode 16.4 CI, iOS deployment target 16.0.

## Global Constraints

- Minimum deployment target: iOS 16.0.
- Must run on iOS 16.0.2.
- Avoid APIs introduced after iOS 16 unless guarded by availability checks with an iOS 16 fallback.
- Use SwiftUI for screens and navigation.
- Use UIKit wrappers only where required by third-party player SDKs or APIs unavailable directly in SwiftUI.
- Use `ObservableObject` rather than the iOS 17 Observation framework.
- Use `URLSession` with Swift concurrency; no third-party networking framework.
- No request parameter, signing behavior, authentication header semantics, or playback-token behavior may be guessed.
- Preserve the existing Flutter implementation on its own branch as a reference.
- The root dock is one connected floating glass surface with system-blue selection.

---

## File Structure

- `GuoguoSwift/GuoguoSwift.xcodeproj/project.pbxproj` — native app/test build graph and iOS 16 deployment settings.
- `GuoguoSwift/App/GuoguoApp.swift` — SwiftUI app entry point and root dependency ownership.
- `GuoguoSwift/App/AppState.swift` — selected root tab and shared navigation state.
- `GuoguoSwift/App/RootView.swift` — root page switching and connected floating dock placement.
- `GuoguoSwift/Core/Network/APIEndpoint.swift` — HTTP method and verified backend path definitions.
- `GuoguoSwift/Core/Network/APIRequest.swift` — request representation and URLRequest construction inputs.
- `GuoguoSwift/Core/Network/APIError.swift` — typed networking failures.
- `GuoguoSwift/Core/Network/APIClient.swift` — the only URLSession request executor.
- `GuoguoSwift/Core/Network/AuthSession.swift` — centralized optional auth/cookie/playback header state without assuming token semantics.
- `GuoguoSwift/Core/Models/MediaItem.swift` — shared media display model.
- `GuoguoSwift/DesignSystem/AppTheme.swift` — system colors and dimensions.
- `GuoguoSwift/DesignSystem/GlassSurface.swift` — native iOS material/glass surface.
- `GuoguoSwift/DesignSystem/FloatingGlassDock.swift` — connected root navigation dock.
- `GuoguoSwift/DesignSystem/MediaCard.swift` — reusable media card.
- `GuoguoSwift/Features/Home/HomeView.swift` — native home screen.
- `GuoguoSwift/Features/Search/SearchView.swift` — native searchable screen.
- `GuoguoSwift/Features/VideoDetail/VideoDetailView.swift` — native detail shell.
- `GuoguoSwift/Features/Collection/CollectionView.swift` — collection shell.
- `GuoguoSwift/Features/History/HistoryView.swift` — history shell.
- `GuoguoSwift/Features/Settings/SettingsView.swift` — interactive local settings.
- `GuoguoSwiftTests/APIEndpointTests.swift` — endpoint construction tests.
- `GuoguoSwiftTests/AuthSessionTests.swift` — centralized header injection tests.
- `GuoguoSwiftTests/AppStateTests.swift` — root destination state tests.
- `.github/workflows/swiftui-ios.yml` — xcodebuild test/build and unsigned IPA packaging.

### Task 1: Native project and red tests

**Files:**
- Create: `GuoguoSwift/GuoguoSwift.xcodeproj/project.pbxproj`
- Create: `GuoguoSwiftTests/APIEndpointTests.swift`
- Create: `GuoguoSwiftTests/AuthSessionTests.swift`
- Create: `GuoguoSwiftTests/AppStateTests.swift`
- Create: `.github/workflows/swiftui-ios.yml`

**Interfaces:**
- Consumes: no production Swift types yet.
- Produces: an iOS 16 app target, XCTest target, and CI job that can demonstrate missing production types before implementation.

- [ ] **Step 1: Add tests that reference the required production interfaces**

```swift
func testVideoSearchPath() {
    XCTAssertEqual(APIEndpoint.videoSearch.path, "/app/video/search")
}

func testAuthSessionInjectsOnlyConfiguredHeaders() throws {
    var session = AuthSession()
    session.xToken = "x-value"
    let headers = session.headers
    XCTAssertEqual(headers["X-Token"], "x-value")
    XCTAssertNil(headers["PLAY-TOKEN"])
}

func testRootDestinationSelection() {
    let state = AppState()
    XCTAssertEqual(state.selectedRoot, .home)
    state.selectedRoot = .search
    XCTAssertEqual(state.selectedRoot, .search)
}
```

- [ ] **Step 2: Configure CI to run the native tests**

Run in CI:

```bash
xcodebuild -project GuoguoSwift/GuoguoSwift.xcodeproj \
  -scheme GuoguoSwift \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  CODE_SIGNING_ALLOWED=NO test
```

Expected before Task 2: build/test failure because `APIEndpoint`, `AuthSession`, and `AppState` do not exist.

- [ ] **Step 3: Commit the failing test harness**

```bash
git add GuoguoSwift GuoguoSwiftTests .github/workflows/swiftui-ios.yml
git commit -m "test: define SwiftUI rewrite foundation contracts"
```

### Task 2: Network contracts and app state

**Files:**
- Create: `GuoguoSwift/App/AppState.swift`
- Create: `GuoguoSwift/Core/Network/APIEndpoint.swift`
- Create: `GuoguoSwift/Core/Network/APIRequest.swift`
- Create: `GuoguoSwift/Core/Network/APIError.swift`
- Create: `GuoguoSwift/Core/Network/AuthSession.swift`
- Create: `GuoguoSwift/Core/Network/APIClient.swift`

**Interfaces:**
- Produces: `enum RootDestination: String, CaseIterable, Identifiable`.
- Produces: `final class AppState: ObservableObject` with `@Published var selectedRoot: RootDestination`.
- Produces: `enum APIEndpoint` with verified paths for config, banners, channels, video list/search/detail/play, playback token/address, collection, history, login, user info, task, VIP, comments, danmaku, report, and message-box families when the exact path is known.
- Produces: `struct APIRequest` with `method`, `endpoint`, `queryItems`, `headers`, and optional `body`.
- Produces: `struct AuthSession` with optional `authorization`, `cookie`, `xToken`, and `playToken` fields and a computed `headers` dictionary.
- Produces: `actor APIClient` with `func send<T: Decodable>(_ request: APIRequest, as type: T.Type) async throws -> T`.

- [ ] **Step 1: Implement the smallest types required by the red tests**

```swift
final class AppState: ObservableObject {
    @Published var selectedRoot: RootDestination = .home
}

struct AuthSession {
    var authorization: String?
    var cookie: String?
    var xToken: String?
    var playToken: String?

    var headers: [String: String] {
        var result: [String: String] = [:]
        if let authorization { result["authorization"] = authorization }
        if let cookie { result["cookie"] = cookie }
        if let xToken { result["X-Token"] = xToken }
        if let playToken { result["PLAY-TOKEN"] = playToken }
        return result
    }
}
```

- [ ] **Step 2: Implement endpoint paths without inventing request schemas**

```swift
enum APIEndpoint {
    case appConfig
    case banners
    case channels
    case videoList
    case videoSearch
    case videoDetail
    case videoPlay
    case playbackAddressV3
    case playbackToken

    var path: String {
        switch self {
        case .appConfig: "/app/config"
        case .banners: "/app/banners/"
        case .channels: "/app/channel/"
        case .videoList: "/app/video/list"
        case .videoSearch: "/app/video/search"
        case .videoDetail: "/app/video/detail"
        case .videoPlay: "/app/video/play"
        case .playbackAddressV3: "/app/playaddr/v3/get"
        case .playbackToken: "/app/playaddr/get/token"
        }
    }
}
```

- [ ] **Step 3: Implement URLSession transport against the known base URL**

```swift
actor APIClient {
    static let baseURL = URL(string: "https://vod.api.zshtys888.com")!
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func send<T: Decodable>(_ request: APIRequest, as type: T.Type) async throws -> T {
        let urlRequest = try request.makeURLRequest(baseURL: Self.baseURL)
        let (data, response) = try await session.data(for: urlRequest)
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard 200..<300 ~= http.statusCode else { throw APIError.httpStatus(http.statusCode, data) }
        do { return try JSONDecoder().decode(type, from: data) }
        catch { throw APIError.decoding(error) }
    }
}
```

- [ ] **Step 4: Run tests**

Expected: endpoint, auth-header, and state tests pass.

- [ ] **Step 5: Commit**

```bash
git add GuoguoSwift/App GuoguoSwift/Core
git commit -m "feat: add native network foundation"
```

### Task 3: Native app shell and Apple-glass design system

**Files:**
- Create: `GuoguoSwift/App/GuoguoApp.swift`
- Create: `GuoguoSwift/App/RootView.swift`
- Create: `GuoguoSwift/DesignSystem/AppTheme.swift`
- Create: `GuoguoSwift/DesignSystem/GlassSurface.swift`
- Create: `GuoguoSwift/DesignSystem/FloatingGlassDock.swift`

**Interfaces:**
- Consumes: `AppState`, `RootDestination`.
- Produces: a native SwiftUI application entry point and one connected floating glass dock.

- [ ] **Step 1: Create the iOS 16 app entry point**

```swift
@main
struct GuoguoApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
        }
    }
}
```

- [ ] **Step 2: Build `GlassSurface` using native material**

```swift
struct GlassSurface<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(.white.opacity(0.55), lineWidth: 0.7)
            )
            .shadow(color: .black.opacity(0.08), radius: 18, y: 9)
    }
}
```

- [ ] **Step 3: Build the connected root dock**

Use one material capsule, five destinations (`home`, `collection`, `history`, `search`, `settings`), system blue for selection, and `Button` rather than tap gestures so hit-testing and accessibility work by default.

- [ ] **Step 4: Build RootView destination switching**

Expected: tapping each dock button changes the visible root screen and updates selected color.

- [ ] **Step 5: Run the app target build**

```bash
xcodebuild -project GuoguoSwift/GuoguoSwift.xcodeproj -scheme GuoguoSwift -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO build
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add GuoguoSwift/App GuoguoSwift/DesignSystem
git commit -m "feat: add native Apple glass app shell"
```

### Task 4: First native feature screens

**Files:**
- Create: `GuoguoSwift/Core/Models/MediaItem.swift`
- Create: `GuoguoSwift/DesignSystem/MediaCard.swift`
- Create: `GuoguoSwift/Features/Home/HomeView.swift`
- Create: `GuoguoSwift/Features/Search/SearchView.swift`
- Create: `GuoguoSwift/Features/VideoDetail/VideoDetailView.swift`
- Create: `GuoguoSwift/Features/Collection/CollectionView.swift`
- Create: `GuoguoSwift/Features/History/HistoryView.swift`
- Create: `GuoguoSwift/Features/Settings/SettingsView.swift`

**Interfaces:**
- Produces: native SwiftUI screens with local interaction and navigation-ready models.
- Does not claim authenticated or playback functionality until protocol verification.

- [ ] **Step 1: Add a simple shared media value model**

```swift
struct MediaItem: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let artworkURL: URL?
}
```

- [ ] **Step 2: Build Home using native ScrollView/LazyHStack**

The view includes a large title, search affordance, featured card, continue-watching shelf, and media shelf. Until the first response contract is verified, local fixtures are visually marked as preview/demo data rather than presented as live backend content.

- [ ] **Step 3: Build Search with a real TextField and local filtering state**

Use `@State private var query = ""`; filtering must be immediate and every result row is a `NavigationLink` to `VideoDetailView`.

- [ ] **Step 4: Build Collection, History, and Settings**

Collection and History render clear empty/content states. Settings uses native `Toggle` and UserDefaults-backed `@AppStorage` for autoplay and preferred-HD settings.

- [ ] **Step 5: Verify root navigation and feature compilation**

Expected: all six root/detail screens compile and are reachable without dead taps.

- [ ] **Step 6: Commit**

```bash
git add GuoguoSwift/Core/Models GuoguoSwift/DesignSystem/MediaCard.swift GuoguoSwift/Features
git commit -m "feat: add native SwiftUI feature screens"
```

### Task 5: CI build and unsigned IPA

**Files:**
- Modify: `.github/workflows/swiftui-ios.yml`

**Interfaces:**
- Consumes: native project and tests.
- Produces: passing tests, device build, `GuoguoSwift-unsigned.ipa`, and `GuoguoSwift.app` artifacts.

- [ ] **Step 1: Run XCTest in CI**

```bash
xcodebuild -project GuoguoSwift/GuoguoSwift.xcodeproj \
  -scheme GuoguoSwift \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  CODE_SIGNING_ALLOWED=NO test
```

- [ ] **Step 2: Build unsigned device application**

```bash
xcodebuild -project GuoguoSwift/GuoguoSwift.xcodeproj \
  -scheme GuoguoSwift \
  -configuration Release \
  -sdk iphoneos \
  -derivedDataPath build/DerivedData \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  build
```

- [ ] **Step 3: Package the application**

```bash
APP_PATH="build/DerivedData/Build/Products/Release-iphoneos/GuoguoSwift.app"
mkdir -p build/ipa/Payload
cp -R "$APP_PATH" build/ipa/Payload/GuoguoSwift.app
cd build/ipa
/usr/bin/zip -qry ../GuoguoSwift-unsigned.ipa Payload
```

- [ ] **Step 4: Upload artifacts**

Upload `build/GuoguoSwift-unsigned.ipa` and the release `.app` with 14-day retention.

- [ ] **Step 5: Verify deployment target from build settings**

```bash
xcodebuild -project GuoguoSwift/GuoguoSwift.xcodeproj -scheme GuoguoSwift -showBuildSettings | grep IPHONEOS_DEPLOYMENT_TARGET
```

Expected: `IPHONEOS_DEPLOYMENT_TARGET = 16.0`.

- [ ] **Step 6: Commit any CI-only fixes**

```bash
git add .github/workflows/swiftui-ios.yml GuoguoSwift
git commit -m "ci: build native SwiftUI unsigned IPA"
```

## Deferred Verified-Protocol Plans

The following work is intentionally not implemented by guessing. Each becomes a separate executable plan after exact traffic/contract verification: authenticated login/user state; collection/history write APIs; playback metadata and play-address token chain; AliyunPlayer SDK integration; task/VIP/payment actions; comments/danmaku/report/message-box writes.
