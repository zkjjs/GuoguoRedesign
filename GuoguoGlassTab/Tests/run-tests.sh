#!/bin/sh
set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
BUILD_DIR="${TMPDIR:-/tmp}/guoguo-glass-tab-tests"
mkdir -p "$BUILD_DIR"

cc -std=c11 -Wall -Wextra -Werror \
  "$ROOT/Tests/test_layout.c" \
  "$ROOT/Layout/GTLayout.c" \
  -lm -o "$BUILD_DIR/test_layout"

"$BUILD_DIR/test_layout"
"$ROOT/Tests/test_source.sh"
"$ROOT/Tests/test_package.sh"

