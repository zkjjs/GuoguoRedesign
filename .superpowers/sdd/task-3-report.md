# Task 3 implementation report

## Scope

Defined the media domain boundary, repository contract, channel section model,
typed payload error, raw DTOs, and strict DTO-to-domain mapping. No Task 2,
workflow, dependency, or remote GitHub files were changed.

## TDD record

### RED — `e1901107a321a3798163a383dd3a87e12e1e8783`

Added the two JSON fixtures and mapper contract tests before production files.
The contract covers:

- numeric and string identities normalized to `String`;
- missing/empty poster and absent/unparseable year;
- unknown media kind falling back to `MediaKind.movie`;
- empty episode lines ignored while numeric episode IDs are normalized;
- malformed envelopes and missing required ID/title throwing
  `ApiError.invalidPayload`;
- unknown optional envelope and record fields ignored.

The RED state is contractual missing implementation: the test imports referred
to files and symbols that did not exist at that commit. It was not reported as
an observed Flutter test result because the local Flutter test snapshot/package
resolution is unavailable, and GitHub Actions runners currently fail before
steps begin (`steps: null`).

### GREEN — `e2936a1fd051aa5d670e5896cd96e5e3b8f5f903`

Added immutable domain models and the exact `VideoRepository` methods required
by the plan. DTO parsing is handwritten; raw server keys occur only in
`features/video_detail/data/video_dto.dart`. Mapping creates immutable lists,
normalizes IDs, parses optional URLs with `Uri.tryParse`, and rejects required
identity failures with the typed payload error. No code generation dependency
was introduced.

## Verification performed

- `HOME=$PWD/.tooling/home .tooling/flutter/bin/dart format --output=none --set-exit-if-changed lib test` — exit 0, zero changed files.
- `git diff --check` — exit 0.
- Static raw-key boundary search — all raw video API keys are confined to
  `lib/features/video_detail/data/video_dto.dart`.

The formatter emitted an environment warning because the current offline
package configuration cannot resolve `package:flutter_lints/flutter.yaml`.
Formatting itself completed successfully.

## Required runner verification

Run these commands when the pinned Flutter package snapshot and Actions runner
are available:

```sh
HOME=$PWD/.tooling/home .tooling/flutter/bin/flutter test test/features/video_detail/video_mapper_test.dart
HOME=$PWD/.tooling/home .tooling/flutter/bin/dart format --output=none --set-exit-if-changed lib test
HOME=$PWD/.tooling/home .tooling/flutter/bin/flutter analyze
HOME=$PWD/.tooling/home .tooling/flutter/bin/flutter test
```

## Residual risks

- The server's undocumented numeric media-kind values are conservatively
  interpreted as `2 = series` and `3 = anime`; all other unknown values fall
  back to movie. This should be checked against an authorized response sample.
- Automated mapper tests and analyzer remain pending runner availability; no
  passing runtime result is claimed here.

## Independent review remediation

The independent review identified one Important finding (public collection
fields could retain caller-owned mutable lists) and one Minor finding
(fractional numeric IDs were accepted and integral doubles had unstable
spelling).

### Review RED — `bd9dc0e3ddf016278c6d86c4168a76d6958fca5d`

Added contracts proving that `MediaDetail.episodes`, `Page.items`, and
`ChannelSection.items` must be unaffected by later source-list mutation and
must reject mutation through their public fields. Added mapper contracts for
`101.0 -> "101"` and rejection of `101.5`, `NaN`, and positive infinity with
`ApiError.invalidPayload`.

These were recorded as contractual RED cases rather than claimed runtime test
results because the Flutter runner remains unavailable.

### Review GREEN — `0880e5e857e032499b7379b9b3ef206b0adc8e13`

The three public domain constructors now defensively copy collection arguments
with `List.unmodifiable`. Numeric identities now accept only finite integral
`num` values and normalize through integer spelling; fractional and non-finite
values reach the existing `ApiError.invalidPayload` path.

Review-fix verification performed:

- fixed Dart formatter across `lib` and `test` — exit 0, zero changed files;
- `bash tool/task1_ci_contract_test.sh` — exit 0;
- `git diff --check` — exit 0.

The same offline `flutter_lints` resolution warning was emitted by the
formatter. No Flutter runtime, analyzer, or build result is claimed.
