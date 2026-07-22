#!/usr/bin/env bash
set -euo pipefail

DEB="${1:?usage: test_roothide_ownership.sh package.deb}"

owners="$({ dpkg-deb --fsys-tarfile "$DEB" | tar --numeric-owner -tvf -; } | awk '{print $2}' | sort -u)"

if [ "$owners" != "501/501" ]; then
    echo "expected every data archive entry to be owned by mobile 501/501; found:" >&2
    printf '%s\n' "$owners" >&2
    exit 1
fi

echo "roothide data ownership: PASS"
