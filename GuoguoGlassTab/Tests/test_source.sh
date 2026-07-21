#!/bin/sh
set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
VIEW="$ROOT/GTGlassTabView.m"
TWEAK="$ROOT/Tweak.xm"

test -f "$VIEW"
test -f "$TWEAK"

grep -q 'UIBlurEffectStyleSystemUltraThinMaterialDark' "$VIEW"
grep -q 'systemBlueColor' "$VIEW"
grep -q 'userInteractionEnabled = NO' "$VIEW"

for label in 发现 频道 任务 我的; do
  grep -q "$label" "$VIEW"
done

grep -q 'FLEX' "$TWEAK"
grep -q 'GTTabIndexForX' "$VIEW"
grep -Fq 'GTInstallOverlay((UIViewController *)self)' "$TWEAK"

echo "source contract tests passed"
