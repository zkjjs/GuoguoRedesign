# Apple Glass Home UI Design

## Goal

Rebuild the first usable Guoguo home screen in Flutter with the visual language approved in chat: Apple-like soft capsule curvature, translucent frosted glass, restrained shadows, large media artwork, and a connected floating bottom dock.

## Scope

This first pass is UI-only. It does not yet connect production APIs, authentication, history persistence, or the Aliyun player bridge. Mock data will be used so the visual system can be reviewed and iterated before wiring business logic.

## Visual Language

- Light iOS-style background with subtle cool gradients behind translucent surfaces.
- Main accent uses system-like blue instead of the previous pink-heavy palette.
- Surfaces use real `BackdropFilter` blur plus semi-transparent white fills and a very light white border.
- Shadows are broad and low-opacity; no heavy Material elevation.
- Corners should feel like the user reference: soft, pill-like continuous curvature rather than boxy Material rounded rectangles.
- The bottom navigation remains one connected floating glass dock. It is not split into independent bubbles.
- Selected tab is indicated primarily by blue icon/text and a subtle internal glass highlight, not a solid colored rectangle.

## Screen Structure

1. Status-safe top area and large `首页` title.
2. Frosted search field.
3. Large hero media card with artwork, title, episode metadata, play affordance and page indicators.
4. `继续观看` horizontal cards with progress bars.
5. `我的媒体` glass cards.
6. Additional media category row to demonstrate reusable poster styling.
7. Connected floating glass bottom dock with Home / Library / History / Search / Settings.

## Component Boundaries

- `AppleGlassSurface`: reusable blur + translucent fill + hairline border + soft shadow.
- `GlassSearchBar`: search affordance using the shared glass surface.
- `HeroMediaCard`: large featured content card.
- `ContinueWatchingCard`: landscape card with title, metadata and progress.
- `MediaShelf`: reusable section heading and horizontal content row.
- `FloatingGlassDock`: connected pill-shaped bottom navigation with selected state.

The screen should not remain one large `main.dart` widget. The first implementation may keep app bootstrap in `main.dart`, while visual components move into focused files under `lib/ui/`.

## Interaction

- Bottom dock switches selected index locally.
- Search field and media cards are tappable but may use no-op callbacks for this UI milestone.
- Hero play button is tappable but does not start real playback yet.
- Scroll content must remain usable on standard iPhone sizes and safe areas.

## Error Handling

No remote calls exist in this milestone, so there are no network error states yet. Mock-image placeholders must render safely without assets or external URLs.

## Testing

- Widget smoke test verifies the home screen renders.
- Widget test verifies selecting a different bottom dock item updates its selected state.
- `flutter analyze` and `flutter test` must pass in GitHub Actions.
- Existing iOS unsigned build workflow remains the build verification path.

## Success Criteria

- Visual result clearly matches the approved Apple frosted-glass direction.
- Bottom dock has the requested connected soft capsule silhouette.
- No default Material `NavigationBar` appearance remains.
- Layout compiles and remains readable on iPhone-sized screens.
- Code structure is ready for later API and player integration without rewriting the visual components.
