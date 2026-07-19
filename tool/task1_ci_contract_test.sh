#!/usr/bin/env bash
set -euo pipefail

readonly repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly generator="$repository_root/tool/generate_task1_ci.sh"
readonly main_template="$repository_root/tool/task1_templates/main.dart"
readonly test_template="$repository_root/tool/task1_templates/widget_test.dart"
readonly workflow="$repository_root/.github/workflows/ios.yml"
readonly flutter_revision="ee80f08bbf97172ec030b8751ceab557177a34a6"

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
grep -Fqx "{\"flutterSdkVersion\":\"$flutter_revision\"}" "$repository_root/.fvmrc"
grep -Fq "FLUTTER_REVISION: $flutter_revision" "$workflow"

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

for dependency in \
  flutter_riverpod go_router dio flutter_secure_storage drift \
  sqlite3_flutter_libs path_provider cached_network_image connectivity_plus \
  share_plus collection; do
  grep -Fq " $dependency" "$generator"
done

for dependency in mocktail drift_dev build_runner pigeon golden_toolkit; do
  grep -Fq " $dependency" "$generator"
done

if grep -E '^[[:space:]]+uses:' "$workflow" | grep -Ev 'actions/(checkout|upload-artifact)@'; then
  echo 'Workflow references a non-official action.' >&2
  exit 1
fi

grep -Fq 'name: guoguo-task1-generated' "$workflow"
grep -Fq 'if: always()' "$workflow"
