#!/usr/bin/env bash
set -euo pipefail

readonly repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly generator="$repository_root/tool/generate_task1_ci.sh"
readonly main_template="$repository_root/tool/task1_templates/main.dart"
readonly test_template="$repository_root/tool/task1_templates/widget_test.dart"
readonly workflow="$repository_root/.github/workflows/ios.yml"
readonly flutter_revision="ee80f08bbf97172ec030b8751ceab557177a34a6"
readonly flutter_version="3.44.6"

require_file() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    echo "Missing required file: $path" >&2
    return 1
  fi
}

require_file "$generator"
require_file "$main_template"
require_file "$test_template"
require_file "$workflow"

test "$(git -C "$repository_root/.tooling/flutter" rev-parse HEAD 2>/dev/null || true)" = "$flutter_revision"
git -C "$repository_root/.tooling/flutter" tag --points-at HEAD | grep -Fxq "$flutter_version"
grep -Fqx "{\"flutterSdkVersion\":\"$flutter_revision\"}" "$repository_root/.fvmrc"
grep -Fq "FLUTTER_REVISION: $flutter_revision" "$workflow"

if ! grep -Fq "FLUTTER_VERSION: $flutter_version" "$workflow"; then
  echo "Workflow must fetch Flutter tag $flutter_version for version metadata." >&2
  exit 1
fi

grep -Fq 'fetch --depth=1 origin "refs/tags/$FLUTTER_VERSION:refs/tags/$FLUTTER_VERSION"' "$workflow"
grep -Fq 'checkout --detach "refs/tags/$FLUTTER_VERSION"' "$workflow"
grep -Fq 'test "$(git -C "$FLUTTER_SDK_DIRECTORY" rev-parse HEAD)" = "$FLUTTER_REVISION"' "$workflow"
grep -Fq 'test "$(git -C "$FLUTTER_SDK_DIRECTORY" describe --tags --exact-match HEAD)" = "$FLUTTER_VERSION"' "$workflow"
grep -Fq "readonly flutter_version=\"$flutter_version\"" "$repository_root/tool/bootstrap_flutter.sh"
grep -Fq 'fetch --depth=1 origin "refs/tags/$flutter_version:refs/tags/$flutter_version"' "$repository_root/tool/bootstrap_flutter.sh"
grep -Fq 'checkout --detach "refs/tags/$flutter_version"' "$repository_root/tool/bootstrap_flutter.sh"

job_environment() {
  awk '
    /^    env:/ { in_environment = 1; next }
    in_environment && /^    steps:/ { exit }
    in_environment { print }
  ' "$workflow"
}

if job_environment | grep -Fq '${{ runner.'; then
  echo 'Job-level env must not reference the unavailable runner context.' >&2
  exit 1
fi

grep -Fq 'echo "FLUTTER_SDK_DIRECTORY=$RUNNER_TEMP/flutter" >> "$GITHUB_ENV"' "$workflow"
grep -Fq 'echo "PROJECT_DIRECTORY=$RUNNER_TEMP/guoguo-task1-generated" >> "$GITHUB_ENV"' "$workflow"

trigger_paths() {
  local trigger="$1"
  awk -v trigger="$trigger" '
    $0 == "  " trigger ":" { in_trigger = 1; next }
    in_trigger && $0 == "    paths:" { in_paths = 1; next }
    in_paths && $0 ~ /^      - / { sub(/^      - /, ""); print; next }
    in_paths { exit }
  ' "$workflow"
}

test -n "$(trigger_paths pull_request)"
diff -u <(trigger_paths push) <(trigger_paths pull_request)

test "$(grep -c 'NavigationDestination(' "$main_template")" -eq 4
grep -Fq 'class GuoguoApp extends StatelessWidget' "$main_template"
grep -Fq 'await tester.pumpWidget(const GuoguoApp());' "$test_template"
grep -Fq 'findsNWidgets(4)' "$test_template"

grep -Fq 'com.example.dongmangongheguo' "$generator"
grep -Fq "platform :ios, '15.0'" "$generator"

if ! grep -Eq 'pub add .* connectivity_plus@6\.1\.5( |$)' "$generator"; then
  echo 'Generator must pin connectivity_plus exactly to Xcode-compatible 6.1.5.' >&2
  exit 1
fi

for dependency in \
  flutter_riverpod go_router dio flutter_secure_storage drift \
  sqlite3_flutter_libs path_provider cached_network_image connectivity_plus \
  share_plus collection; do
  grep -Fq " $dependency" "$generator"
done

for dependency in mocktail drift_dev build_runner pigeon golden_toolkit; do
  grep -Fq " $dependency" "$generator"
done

precache_line="$(grep -nF '"$FLUTTER_SDK_DIRECTORY/bin/flutter" precache --ios' "$workflow" | cut -d: -f1 || true)"
pod_install_line="$(grep -nF 'run: pod install' "$workflow" | cut -d: -f1 || true)"
if [[ -z "$precache_line" ]]; then
  echo 'Workflow must pre-cache pinned iOS engine artifacts.' >&2
  exit 1
fi
test -n "$pod_install_line"
test "$precache_line" -lt "$pod_install_line"

if grep -E '^[[:space:]]+uses:' "$workflow" | grep -Ev 'actions/(checkout|upload-artifact)@'; then
  echo 'Workflow references a non-official action.' >&2
  exit 1
fi

grep -Fq 'name: guoguo-task1-generated' "$workflow"
grep -Fq 'if: always()' "$workflow"
