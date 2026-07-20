# Playback address contract

## Verified static contract

The authorized static analysis verified only these production constants:

- Base host: `https://vod.api.zshtys888.com`
- Token endpoint: `/app/playaddr/get/token`
- Address endpoint: `/app/playaddr/v3/get`
- Address authorization header: `PLAY-TOKEN`
- Address response field: `raw_play_url`

Request parameter names, the token response shape, expiry representation, all
unverified response wrappers, header transport shape, and server error codes
remain **unknown pending an authorized test capture**. They must not be
inferred from fixtures or introduced as guessed production constants.

`PlaybackApi` is deliberately a typed normalized adapter boundary. It returns
`PlaybackTokenResult` and `PlaybackAddressResult`; it does not expose maps or
wire envelopes. No production HTTP adapter or wire parser exists until an
authorized capture verifies those shapes. The JSON fixtures describe test
states at that typed boundary only and are not production-response examples.

## Capture safety

The optional contract-capture harness is disabled unless the application is
built with `--dart-define=GUOGUO_CONTRACT_CAPTURE=true`. It records only field
names, field types, HTTP status codes, and elapsed timing. It never records
field values, tokens, headers, request bodies, response bodies, or playback
URLs.

Playback tokens and resolved addresses remain in memory. They must not be
written to preferences, SQLite, crash reports, logs, snapshots, or fixtures.
