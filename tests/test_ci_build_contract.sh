#!/bin/sh
set -eu

SCRIPT="ci/build-ios-roothide.sh"
WORKFLOW=".github/workflows/codex-ios-roothide.yml"

test -f "$SCRIPT"
test -f "$WORKFLOW"

grep -F 'UPSTREAM_TAG="rust-v0.145.0"' "$SCRIPT" >/dev/null
grep -F 'PKG_VERSION="0.145.0-2"' "$SCRIPT" >/dev/null
grep -F 'rustup target add aarch64-apple-ios' "$SCRIPT" >/dev/null
grep -F 'cargo build -p codex-cli --release --target aarch64-apple-ios' "$SCRIPT" >/dev/null
grep -F 'code mode is unavailable in this iOS build' "$SCRIPT" >/dev/null
grep -F 'cargo tree -p codex-cli --target "$TARGET"' "$SCRIPT" >/dev/null
grep -F "text = text.replace('debug = \"line-tables-only\"', 'debug = \"none\"', 1)" "$SCRIPT" >/dev/null
grep -F "text = text.replace('strip = false', 'strip = \"symbols\"', 1)" "$SCRIPT" >/dev/null
grep -F 'strings "$CODEX_BIN" > "$WORK/codex.strings"' "$SCRIPT" >/dev/null
if grep -F 'strings "$CODEX_BIN" | grep' "$SCRIPT" >/dev/null; then
  echo "version check must not close the strings pipeline early" >&2
  exit 1
fi
if grep -F 'cargo build -p codex-code-mode-host' "$SCRIPT" >/dev/null; then
  echo "iOS build must not compile the V8-backed code mode host" >&2
  exit 1
fi
grep -F 'Package: codex-ios-roothide' "$SCRIPT" >/dev/null
grep -F 'Version: 0.145.0-2' "$SCRIPT" >/dev/null
grep -F 'Architecture: iphoneos-arm64e' "$SCRIPT" >/dev/null
grep -F 'export HOME="${PREFIX}/var/mobile/codex"' "$SCRIPT" >/dev/null
grep -F 'export CODEX_HOME="${HOME}/.codex"' "$SCRIPT" >/dev/null
grep -F 'sudo chown -R 501:501 "$STAGE"' "$SCRIPT" >/dev/null
if grep -F 'dpkg-deb --root-owner-group' "$SCRIPT" >/dev/null; then
  echo "roothide package must retain mobile 501/501 data ownership" >&2
  exit 1
fi

if grep -E 'rm[[:space:]].*(var/mobile/codex|CODEX_HOME)' "$SCRIPT" >/dev/null; then
  echo "build script contains a configuration deletion command" >&2
  exit 1
fi

grep -F 'runs-on: macos-14' "$WORKFLOW" >/dev/null
grep -F 'actions/upload-artifact@v4' "$WORKFLOW" >/dev/null

echo "CI build contract: PASS"
