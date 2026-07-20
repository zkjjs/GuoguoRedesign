# Task 4 implementation report

Status: DONE_WITH_CONCERNS

## TDD commits

- RED: `4f2b31b test: define authenticated HTTP security contract`
- GREEN: `6105669 feat: add secure authenticated API client`
- REVIEW RED: `57976bf test: cover authenticated client security races`
- REVIEW GREEN: `4659e28 fix: harden authenticated client failure boundaries`
- GENERATION RED: `9facd4a test: require opaque invalidated auth generations`
- GENERATION GREEN: `1872940 fix: invalidate auth with opaque generations`
- ATOMIC CLEAR RED: `704e688 test: require atomic rejected-token clearing`
- ATOMIC CLEAR GREEN: `e489134 fix: clear rejected tokens atomically`

The RED tests were committed before production code. The repository Flutter
runner cannot currently execute because its SDK/upgrade lock is held, so no
Flutter test result is claimed.

## Implemented contract

- `TokenStore` and `SessionRefresher` expose the exact planned methods.
- Authenticated requests add `X-Token` and `UserToken` only when values exist.
- A per-interceptor `_refreshing` future coalesces concurrent 401 refreshes.
- Requests record the token generation they used. A delayed old-token 401
  replays with the already-refreshed token and cannot start a second refresh.
- Request extras now contain only an opaque monotonic generation integer, never
  a raw application or user token.
- The interceptor owns an independent active/expired generation state. If a
  refreshed replay is rejected, a later old-generation 401 terminates as
  authentication-expired without another refresh even after durable deletion.
- Failed Keychain deletion cannot re-enable a rejected token: subsequent
  requests suppress the header and refresh. A different externally stored token
  is treated as a new sign-in generation on the next request; the same rejected
  token intentionally cannot reactivate itself.
- `ConditionalTokenStore` is an optional capability that preserves the exact
  `TokenStore` API while allowing compare-and-delete semantics. Keychain read,
  write, clear, and conditional-clear operations share one per-instance async
  queue, so a concurrent new-login write cannot be deleted by an old rejection.
- Generic stores without conditional clearing never use a racy read-then-clear
  fallback. They rely on immediate in-memory invalidation; durable cleanup is
  deferred until the store provides an atomic capability.
- Same-Dio refresh requests use the documented internal `skipAuthRefresh`
  marker, preventing a refresh request from joining its own refresh future.
- `RefreshAuthenticationRejected` is the minimal explicit convention for a
  confirmed credential rejection. Timeouts, server/storage failures, and raw
  refresh transport errors preserve their original error and stored token.
- A replay is marked with `extra['authRetried'] = true`; a second 401 clears
  the user token and surfaces `ApiError.authenticationExpired` without another
  refresh.
- Request logs recursively redact sensitive header, query, and body keys using
  case-insensitive matching while leaving safe values visible. Logging builds
  new maps/lists and does not mutate request data.
- FormData is converted to detached fields plus safe file metadata; unsupported
  body containers become type-only markers. Query parameters embedded directly
  in the path are parsed and redacted before reaching the sink.
- Blank refresh results are rejected before storage, and all case variants of
  token headers are removed before the canonical header is added.
- `KeychainTokenStore` uses an injected storage boundary and
  `KeychainAccessibility.first_unlock_this_device` for every operation.

## Verification evidence

- Direct Dart formatter completed for Task 4 production and test files. It
  reported only the expected unresolved `flutter_lints` include warning caused
  by the unavailable project package resolution.
- `git diff --check`: passed.
- `bash tool/task1_ci_contract_test.sh`: passed.
- Dio 5.10.0 and flutter_secure_storage 10.3.1 source archives were inspected
  to validate adapter, interceptor, `copyWith`, `IOSOptions`, and keychain enum
  APIs.
- The non-Flutter authentication/redaction production sources were copied into
  a clean temporary Dart package pinned to Dio 5.10.0; `dart analyze lib`
  completed with `No issues found!`.
- The same isolated Dio analysis was repeated after the review fixes and again
  completed with `No issues found!`.
- Production networking sources and pure-Dart equivalents of both Dio test
  files were analyzed again after opaque-generation changes: `No issues found!`.
- Atomic-clear networking sources/tests were analyzed against Dio 5.10.0 with
  `No issues found!`; Keychain queue code was separately analyzed against a
  signature-compatible secure-storage boundary with `No issues found!`.
- A temporary pure-Dart test attempt did not produce a usable runner result in
  this environment, so it is not counted as passing.

## Remaining verification concern

Run these when the Flutter runner/Actions runner is restored:

```sh
.tooling/flutter/bin/flutter test test/core/network/auth_interceptor_test.dart
.tooling/flutter/bin/flutter test test/core
.tooling/flutter/bin/flutter analyze
```
