#!/usr/bin/env bash
set -euo pipefail

readonly flutter_revision="ee80f08bbf97172ec030b8751ceab557177a34a6"
readonly flutter_version="3.44.6"
readonly repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly sdk_directory="$repository_root/.tooling/flutter"

cd "$repository_root"

if [[ -d "$sdk_directory" ]]; then
  if ! git -C "$sdk_directory" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Flutter SDK directory is not a Git checkout: $sdk_directory" >&2
    exit 1
  fi

  if [[ -n "$(git -C "$sdk_directory" status --porcelain)" ]]; then
    echo "Flutter SDK checkout is dirty; refusing to modify it." >&2
    exit 1
  fi
else
  mkdir -p "$(dirname "$sdk_directory")"
  git clone https://github.com/flutter/flutter.git "$sdk_directory"
fi

git -C "$sdk_directory" fetch --depth=1 origin "refs/tags/$flutter_version:refs/tags/$flutter_version"
git -C "$sdk_directory" checkout --detach "refs/tags/$flutter_version"

actual_revision="$(git -C "$sdk_directory" rev-parse HEAD)"
if [[ "$actual_revision" != "$flutter_revision" ]]; then
  echo "Flutter revision mismatch: expected $flutter_revision, got $actual_revision" >&2
  exit 1
fi

actual_version="$(git -C "$sdk_directory" describe --tags --exact-match HEAD)"
if [[ "$actual_version" != "$flutter_version" ]]; then
  echo "Flutter version mismatch: expected $flutter_version, got $actual_version" >&2
  exit 1
fi

"$sdk_directory/bin/flutter" doctor -v
"$sdk_directory/bin/flutter" pub get
