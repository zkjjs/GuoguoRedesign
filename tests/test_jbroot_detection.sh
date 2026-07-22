#!/usr/bin/env bash
set -euo pipefail

BASE="$(mktemp -d)"
trap 'rm -rf "$BASE"' EXIT

mkdir -p "$BASE/real-jbroot"
ln -s "$BASE/real-jbroot" "$BASE/.jbroot-test"

PREFIX="$(ls -d "$BASE"/.jbroot-* 2>/dev/null | head -n 1)"
test "$PREFIX" = "$BASE/.jbroot-test"
test -L "$PREFIX"

echo "roothide symlink prefix detection: PASS"
