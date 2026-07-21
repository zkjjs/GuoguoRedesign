#!/bin/sh
set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
WORKFLOW="$ROOT/../.github/workflows/build-guoguo-glass-tab.yml"

grep -q 'com.example.dongmangongheguo' "$ROOT/GuoguoGlassTab.plist"
grep -q '^Package: com.zkjjs.guoguoglasstab$' "$ROOT/control"
grep -q 'THEOS_PACKAGE_SCHEME=rootless' "$WORKFLOW"
grep -q 'packages/.*\.deb' "$WORKFLOW"
grep -q '0xFF000000' "$ROOT/Resources/theme.json"
grep -q '0xFF0A84FF' "$ROOT/Resources/theme.json"
grep -q 'default_dark.zip.bak' "$ROOT/layout/DEBIAN/postinst"
grep -q 'default_dark.zip.bak' "$ROOT/layout/DEBIAN/prerm"
grep -Fq 'cp "$BACKUP" "$ARCHIVE"' "$ROOT/layout/DEBIAN/prerm"

echo "package contract tests passed"
