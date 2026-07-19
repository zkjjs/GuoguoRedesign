#!/usr/bin/env bash
set -euo pipefail

readonly repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly generator="$repository_root/tool/generate_task1_ci.sh"
readonly committed_main="$repository_root/lib/main.dart"
readonly committed_test="$repository_root/test/widget_test.dart"
readonly committed_app="$repository_root/lib/app/app.dart"
readonly committed_router="$repository_root/lib/app/router.dart"
readonly committed_navigation="$repository_root/lib/app/shell.dart"
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
require_file "$committed_main"
require_file "$committed_test"
require_file "$committed_app"
require_file "$committed_router"
require_file "$committed_navigation"
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

for required_path in \
  'lib/**' 'test/**' pubspec.yaml pubspec.lock analysis_options.yaml 'ios/**'; do
  if ! trigger_paths push | grep -Fxq "$required_path"; then
    echo "Workflow triggers must include committed project input: $required_path" >&2
    exit 1
  fi
done

workflow_step() {
  local step_name="$1"
  awk -v heading="      - name: $step_name" '
    $0 == heading { in_step = 1 }
    in_step && $0 != heading && /^      - name: / { exit }
    in_step { print }
  ' "$workflow"
}

for committed_step in \
  'Resolve committed project dependencies' \
  'Check committed Dart formatting' \
  'Analyze committed Flutter sources' \
  'Run committed unit and widget tests' \
  'Install committed CocoaPods dependencies' \
  'Build committed unsigned iOS simulator app'; do
  step_definition="$(workflow_step "$committed_step")"
  if [[ -z "$step_definition" ]]; then
    echo "Workflow is missing committed-project step: $committed_step" >&2
    exit 1
  fi
  if grep -Fq 'runner.temp' <<<"$step_definition"; then
    echo "Committed-project step must run in the checkout: $committed_step" >&2
    exit 1
  fi
done

workflow_step 'Resolve committed project dependencies' | grep -Fq 'run: flutter pub get'
workflow_step 'Check committed Dart formatting' | grep -Fq 'run: dart format --output=none --set-exit-if-changed lib test'
workflow_step 'Analyze committed Flutter sources' | grep -Fq 'run: flutter analyze'
workflow_step 'Run committed unit and widget tests' | grep -Fq 'run: flutter test'
workflow_step 'Install committed CocoaPods dependencies' | grep -Fq 'working-directory: ios'
workflow_step 'Install committed CocoaPods dependencies' | grep -Fq 'run: pod install'
workflow_step 'Build committed unsigned iOS simulator app' | grep -Fq 'run: flutter build ios --simulator --no-codesign'
grep -Fq -- '- name: Verify bootstrap contracts' "$workflow"
grep -Fq -- '- name: Generate project and prove smoke-test RED' "$workflow"

readonly expected_navigation_labels=$'频道\n搜索\n收藏\n我的'

navigation_labels() {
  sed -n -E "s/.*label: '([^']+)'.*/\\1/p" "$1"
}

test "$(grep -c 'NavigationDestination(' "$main_template")" -eq 4
grep -Fq 'class GuoguoApp extends StatelessWidget' "$main_template"
grep -Fq 'selectedIndex: 0' "$main_template"
test "$(navigation_labels "$main_template")" = "$expected_navigation_labels"

test "$(grep -c 'NavigationDestination(' "$committed_navigation")" -eq 4
grep -Fq 'class GuoguoApp extends StatefulWidget' "$committed_app"
grep -Fq "initialLocation: '/channel'" "$committed_router"
grep -Fq 'selectedIndex: navigationShell.currentIndex' "$committed_navigation"
if [[ "$(navigation_labels "$committed_navigation")" != "$expected_navigation_labels" ]]; then
  echo "Navigation labels must be 频道, 搜索, 收藏, 我的 in order: $committed_navigation" >&2
  exit 1
fi

grep -Fq 'await tester.pumpWidget(const GuoguoApp());' "$test_template"
for widget_test in "$committed_test" "$test_template"; do
  grep -Fq 'GuoguoApp(' "$widget_test"
  grep -Fq 'findsNWidgets(4)' "$widget_test"
  grep -Fq "orderedEquals(['频道', '搜索', '收藏', '我的'])" "$widget_test"
  grep -Fq 'expect(navigationBar.selectedIndex, 0);' "$widget_test"
done

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
