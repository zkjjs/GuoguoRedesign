# Task 5 implementation report

Status: DONE_WITH_CONCERNS

## Review-fix wave

- RED: `3fd840d test: harden playback resolver boundaries`
- Replaced all raw `Object?` envelopes with typed normalized token/address
  results. No unverified wire wrappers or token/header keys remain in the
  repository.
- Enforced one global token-refresh budget across expiry and 401 paths and
  expiry-check every refreshed token before an address call.
- Added phase-complete timeout/cancellation scenarios for context, initial
  token, first address, refreshed token, and retried address.
- Canonicalized the three allowlisted headers, selected first valid value,
  and rejected CR/LF names and values.
- Made `PlaybackSource` defensively copy its header map and expanded capture
  shape traversal/tests to nested lists/maps and the optional sink.

## Delivered

- Added the playback request, context, source, failure taxonomy, and repository
  domain contracts.
- Added a normalized `PlaybackApi` boundary and the verified static host,
  endpoint, header-name, and `raw_play_url` constants only.
- Added context → token → address resolution, `PLAY-TOKEN` forwarding,
  HTTP(S) URI validation, address-header allowlisting, expired-token refresh,
  and one retry after an unauthorized address response.
- Added distinct failures for empty URL, unsupported scheme, invalid address,
  malformed token, repeated unauthorized response, timeout, and cancellation.
- Kept resolved sources in memory and redacted URI/header diagnostics.
- Added a default-off `GUOGUO_CONTRACT_CAPTURE` recorder that exposes only
  field names/types, status code, and elapsed duration.
- Documented the verified static production contract and explicitly marked
  request parameter names, token response shape, expiry representation, and
  error codes as unknown pending authorized capture.

## TDD record

- RED commit: `8c488e9 test: define secure playback resolver contract`
- GREEN implementation follows in the next commit.
- The RED test imports referenced implementation files that did not exist at
  the RED commit. Flutter could not be launched in this environment, so no
  fabricated test-failure output is claimed.

## Verification

- `dart format lib/features/player test/features/player/playback_repository_test.dart`
  completed; formatter warned only that the unavailable package configuration
  could not resolve `flutter_lints`.
- `dart analyze lib/features/player` → `No issues found!`
- `bash tool/task1_ci_contract_test.sh` completed successfully.
- `git diff --check` completed successfully.
- A pure-Dart smoke program was attempted twice. Both attempts crashed in the
  Dart VM kernel-service startup with `BUS_ADRERR` before user code ran. The
  temporary smoke file was removed.

## Concern / runtime blocker

The Flutter test runner and GitHub Actions runner are unavailable in the
current environment. Therefore the requested repository test cannot be run
twice here, and this report does **not** claim a runtime pass. The production
HTTP parameter mapping is intentionally not implemented until an authorized
capture verifies names and token/error shapes; guessing those constants would
violate the contract and security requirements.
