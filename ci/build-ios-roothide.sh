#!/usr/bin/env bash
set -euo pipefail

UPSTREAM_TAG="rust-v0.145.0"
VERSION="0.145.0"
PKG_VERSION="0.145.0-1"
TARGET="aarch64-apple-ios"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$ROOT/.codex-ios-work"
DIST="$ROOT/dist"
SRC="$WORK/codex"
STAGE="$WORK/package"

rm -rf "$WORK" "$DIST"
mkdir -p "$WORK" "$DIST"

git clone --depth 1 --branch "$UPSTREAM_TAG" https://github.com/openai/codex.git "$SRC"
git -C "$SRC" rev-parse HEAD > "$DIST/UPSTREAM_COMMIT"
printf '%s\n' "$VERSION" > "$DIST/UPSTREAM_VERSION"

python3 - "$SRC" <<'PY'
from pathlib import Path
import re
import sys

src = Path(sys.argv[1])
cargo = src / "codex-rs/Cargo.toml"
text = cargo.read_text()
assert 'version = "0.145.0"' in text
old = 'arboard = { version = "3", features = ["wayland-data-control"] }'
assert old in text
text = text.replace(old, 'arboard = { version = "3" }', 1)
text = text.replace('[profile.release]\nlto = "thin"', '[profile.release]\nlto = "off"', 1)
text = text.replace('codegen-units = 4', 'codegen-units = 16', 1)
cargo.write_text(text)

hardening = src / "codex-rs/process-hardening/src/lib.rs"
text = hardening.read_text()
needle = '    target_os = "macos",\n    target_os = "freebsd",'
assert needle in text
text = text.replace(
    needle,
    '    target_os = "macos",\n    target_os = "ios",\n    target_os = "freebsd",',
    1,
)
hardening.write_text(text)

main = src / "codex-rs/cli/src/main.rs"
text = main.read_text()
anchor = 'use supports_color::Stream;\n'
assert anchor in text
ios_stack_probe = '''

// iOS compatibility: older jailbreak runtimes may not export the stack probe
// emitted by newer Apple SDK toolchains.
#[cfg(all(target_os = "ios", target_arch = "aarch64"))]
#[unsafe(no_mangle)]
pub extern "C" fn __chkstk_darwin() {}
'''
text = text.replace(anchor, anchor + ios_stack_probe, 1)
main.write_text(text)

assert 'target_os = "ios"' in hardening.read_text()
assert '__chkstk_darwin' in main.read_text()
PY

git -C "$SRC" diff --binary > "$DIST/0001-codex-0.145.0-ios.patch"
test -s "$DIST/0001-codex-0.145.0-ios.patch"

rustup toolchain install 1.95.0 --profile minimal
rustup target add aarch64-apple-ios --toolchain 1.95.0

export RUSTUP_TOOLCHAIN=1.95.0
export SDKROOT="$(xcrun --sdk iphoneos --show-sdk-path)"
export IPHONEOS_DEPLOYMENT_TARGET=14.0
export CC_aarch64_apple_ios="$(xcrun --sdk iphoneos --find clang)"
export CXX_aarch64_apple_ios="$(xcrun --sdk iphoneos --find clang++)"
export AR_aarch64_apple_ios="$(xcrun --sdk iphoneos --find ar)"
export CFLAGS_aarch64_apple_ios="-isysroot $SDKROOT -miphoneos-version-min=$IPHONEOS_DEPLOYMENT_TARGET"
export CXXFLAGS_aarch64_apple_ios="$CFLAGS_aarch64_apple_ios"
export CARGO_TARGET_AARCH64_APPLE_IOS_LINKER="$CC_aarch64_apple_ios"

cd "$SRC/codex-rs"
cargo build -p codex-cli --release --target aarch64-apple-ios
cargo build -p codex-code-mode-host --release --target aarch64-apple-ios

CODEX_BIN="$SRC/codex-rs/target/$TARGET/release/codex"
CODE_MODE_BIN="$SRC/codex-rs/target/$TARGET/release/codex-code-mode-host"
test -x "$CODEX_BIN"
test -x "$CODE_MODE_BIN"
file "$CODEX_BIN" | grep -E 'Mach-O 64-bit.*arm64'
file "$CODE_MODE_BIN" | grep -E 'Mach-O 64-bit.*arm64'
strings "$CODEX_BIN" | grep -F -m1 "$VERSION" >/dev/null

cd "$WORK"
npm pack "@openai/codex@$VERSION" --silent
NPM_TGZ="$(find "$WORK" -maxdepth 1 -name 'openai-codex-*.tgz' -print -quit)"
test -n "$NPM_TGZ"
mkdir -p "$WORK/npm"
tar -xzf "$NPM_TGZ" -C "$WORK/npm"
test "$(node -p "require('$WORK/npm/package/package.json').version")" = "$VERSION"

MODULE="$STAGE/var/jb/usr/local/lib/node_modules/@openai/codex"
VENDOR="$MODULE/vendor/aarch64-apple-ios"
mkdir -p "$STAGE/DEBIAN" "$MODULE" "$VENDOR/codex" "$VENDOR/path"
mkdir -p "$STAGE/var/jb/usr/local/bin" "$STAGE/var/jb/usr/local/share/entitlements"
cp -R "$WORK/npm/package/." "$MODULE/"
cp "$CODEX_BIN" "$VENDOR/codex/codex"
cp "$CODE_MODE_BIN" "$STAGE/var/jb/usr/local/bin/codex-code-mode-host"

cat > "$VENDOR/path/rg" <<'EOF'
#!/bin/sh
PREFIX="${JB_ROOT:-/var/jb}"
if [ -x "${PREFIX}/usr/bin/rg" ]; then
    exec "${PREFIX}/usr/bin/rg" "$@"
fi
exec /usr/bin/grep "$@"
EOF

cat > "$STAGE/var/jb/usr/local/bin/codex" <<'EOF'
#!/var/jb/usr/bin/zsh
if [ -n "${JB_ROOT:-}" ]; then
    PREFIX="$JB_ROOT"
else
    PREFIX="$(find /var/containers/Bundle/Application -maxdepth 1 -type d -name '.jbroot-*' 2>/dev/null | head -n 1)"
    [ -n "$PREFIX" ] || PREFIX="/var/jb"
fi

MODULE="${PREFIX}/usr/local/lib/node_modules/@openai/codex"
CODEX_BIN="${MODULE}/vendor/aarch64-apple-ios/codex/codex"
CODEX_PATH="${MODULE}/vendor/aarch64-apple-ios/path"

export HOME="${PREFIX}/var/mobile/codex"
export CODEX_HOME="${HOME}/.codex"
export PATH="${CODEX_PATH}:${PREFIX}/usr/local/bin:${PREFIX}/usr/bin:${PREFIX}/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export SHELL="${PREFIX}/usr/bin/zsh"
export LANG="${LANG:-en_US.UTF-8}"
export LC_ALL="${LC_ALL:-en_US.UTF-8}"
export TERM="${TERM:-xterm-256color}"
export UV_THREADPOOL_SIZE="${UV_THREADPOOL_SIZE:-1}"

mkdir -p "$HOME" "$CODEX_HOME"

for cert in /etc/ssl/certs/cacert.pem /etc/ssl/cert.pem "${PREFIX}/etc/ssl/certs/cacert.pem"; do
    if [ -f "$cert" ]; then
        export SSL_CERT_FILE="$cert"
        break
    fi
done

exec "$CODEX_BIN" "$@"
EOF

cat > "$STAGE/var/jb/usr/local/share/entitlements/codex.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>platform-application</key><true/>
    <key>com.apple.private.security.no-sandbox</key><true/>
    <key>get-task-allow</key><true/>
    <key>com.apple.private.skip-library-validation</key><true/>
</dict>
</plist>
EOF

cat > "$STAGE/DEBIAN/control" <<'EOF'
Package: codex-ios-roothide
Name: codex-ios-roothide
Version: 0.145.0-1
Architecture: iphoneos-arm64e
Section: Development
Priority: optional
Maintainer: DaFei
Depends: firmware (>= 14.0), nodejs22-ios-roothide (>= 22.12.0), ldid
Description: OpenAI Codex CLI 0.145.0 for roothide iOS arm64
 Native aarch64-apple-ios build of the OpenAI Codex coding agent.
 Preserves the existing roothide configuration directory and custom providers.
EOF

cat > "$STAGE/DEBIAN/postinst" <<'EOF'
#!/bin/sh
set -eu

if [ -n "${JB_ROOT:-}" ]; then
    PREFIX="$JB_ROOT"
else
    PREFIX="$(find /var/containers/Bundle/Application -maxdepth 1 -type d -name '.jbroot-*' 2>/dev/null | head -n 1)"
    [ -n "$PREFIX" ] || PREFIX="/var/jb"
fi

ENTS="${PREFIX}/usr/local/share/entitlements/codex.plist"
LDID="${PREFIX}/usr/bin/ldid"

for binary in \
    "${PREFIX}/usr/local/lib/node_modules/@openai/codex/vendor/aarch64-apple-ios/codex/codex" \
    "${PREFIX}/usr/local/bin/codex-code-mode-host"
do
    [ -f "$binary" ] || continue
    chmod 755 "$binary"
    if [ -x "$LDID" ]; then
        "$LDID" -S"$ENTS" "$binary" || "$LDID" -S "$binary"
    fi
done

exit 0
EOF

chmod 755 "$STAGE/DEBIAN/postinst"
chmod 755 "$STAGE/var/jb/usr/local/bin/codex"
chmod 755 "$STAGE/var/jb/usr/local/bin/codex-code-mode-host"
chmod 755 "$VENDOR/codex/codex" "$VENDOR/path/rg"
chmod 644 "$STAGE/DEBIAN/control" "$STAGE/var/jb/usr/local/share/entitlements/codex.plist"

grep -Fx 'Version: 0.145.0-1' "$STAGE/DEBIAN/control"
grep -Fx 'Architecture: iphoneos-arm64e' "$STAGE/DEBIAN/control"
sh -n "$STAGE/DEBIAN/postinst"
zsh -n "$STAGE/var/jb/usr/local/bin/codex"
! grep -R -E 'rm[[:space:]].*(var/mobile/codex|CODEX_HOME)|rm[[:space:]]+-r' "$STAGE/DEBIAN" "$STAGE/var/jb/usr/local/bin/codex"

if ! command -v dpkg-deb >/dev/null 2>&1; then
    brew install dpkg
fi

DEB="$DIST/codex-ios-roothide-$PKG_VERSION.deb"
COPYFILE_DISABLE=1 dpkg-deb -Zxz -b "$STAGE" "$DEB"
dpkg-deb --info "$DEB"
dpkg-deb --contents "$DEB" > "$DIST/PACKAGE-CONTENTS.txt"

cat > "$DIST/README.txt" <<EOF
Codex CLI $VERSION native iOS arm64 build for roothide
Package version: $PKG_VERSION
Upstream tag: $UPSTREAM_TAG
Configuration path is preserved at <jbroot>/var/mobile/codex/.codex
EOF

cd "$DIST"
shasum -a 256 "$(basename "$DEB")" > SHA256SUMS
COPYFILE_DISABLE=1 zip -9 "codex-ios-roothide-$PKG_VERSION.zip" \
    "$(basename "$DEB")" SHA256SUMS README.txt UPSTREAM_COMMIT \
    UPSTREAM_VERSION 0001-codex-0.145.0-ios.patch PACKAGE-CONTENTS.txt

echo "Built $DIST/codex-ios-roothide-$PKG_VERSION.zip"
