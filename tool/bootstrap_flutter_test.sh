#!/usr/bin/env bash
set -euo pipefail
expected="ee80f08bbf97172ec030b8751ceab557177a34a6"
actual="$(git -C .tooling/flutter rev-parse HEAD 2>/dev/null || true)"
test "$actual" = "$expected"
