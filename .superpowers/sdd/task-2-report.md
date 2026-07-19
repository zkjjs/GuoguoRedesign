# Task 2 implementation report

Status: **RED checkpoint prepared for GitHub macOS CI**

## Tests written before production

- `test/core/theme/cinema_theme_test.dart`
- `test/app/app_shell_test.dart`
- `test/golden/app_shell_golden_test.dart`

The tests specify the exact Cinema semantic tokens, dark/system theme,
44-point targets, reduced-motion policy, opaque accessibility fallback for
glass, default `/channel` routing, exact Chinese labels, 200% text behavior,
and the two required 390x844 goldens.

## Local runner constraint

The pinned Flutter SDK is checked out at
`ee80f08bbf97172ec030b8751ceab557177a34a6`, but bootstrapping the local
Flutter tool is blocked while resolving its pub dependencies. Per controller
direction, local Flutter execution was not retried and no production code was
written. This tests-only commit will be run by the existing official GitHub
macOS workflow so the missing Task 2 production symbols are observed as RED.

## Expected RED

Command:

```text
flutter test test/core/theme/cinema_theme_test.dart
```

Expected cause: imports such as `core/theme/cinema_tokens.dart` and symbols
such as `CinemaTokens` do not exist yet.

## GREEN resume point

After the CI failure is captured, implement Task 2, generate and inspect both
goldens, run the full directed verification, and commit with:

```text
feat: add Cinema Glass theme and navigation shell
```
