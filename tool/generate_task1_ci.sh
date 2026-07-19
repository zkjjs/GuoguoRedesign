#!/usr/bin/env bash
set -euo pipefail

if [[ "$#" -ne 2 ]]; then
  echo "Usage: $0 FLUTTER_SDK_DIRECTORY PROJECT_DIRECTORY" >&2
  exit 64
fi

readonly flutter_sdk_directory="$1"
readonly project_directory="$2"
readonly repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly flutter="$flutter_sdk_directory/bin/flutter"
readonly red_log="${RUNNER_TEMP:-/tmp}/guoguo-task1-red.log"

if [[ ! -x "$flutter" ]]; then
  echo "Flutter executable not found: $flutter" >&2
  exit 1
fi

if [[ -e "$project_directory" ]]; then
  echo "Generated project destination already exists: $project_directory" >&2
  exit 1
fi

mkdir -p "$project_directory"
cd "$project_directory"

"$flutter" create --platforms=ios --org com.example --project-name guoguo .
"$flutter" config --no-analytics
"$flutter" config --no-enable-swift-package-manager

cp "$flutter_sdk_directory/packages/flutter_tools/templates/cocoapods/Podfile-ios" ios/Podfile

ruby - ios/Runner.xcodeproj/project.pbxproj ios/Podfile <<'RUBY'
project_path, podfile_path = ARGV

project = File.read(project_path)
generated_identifier = 'com.example.guoguo'
required_identifier = 'com.example.dongmangongheguo'
abort "Generated bundle identifier not found in #{project_path}" unless project.include?(generated_identifier)

project.gsub!(generated_identifier, required_identifier)
project.gsub!(/IPHONEOS_DEPLOYMENT_TARGET = [0-9.]+;/, 'IPHONEOS_DEPLOYMENT_TARGET = 15.0;')
File.write(project_path, project)

podfile = File.read(podfile_path)
platform = "platform :ios, '15.0'"
updated = podfile.sub(/^#?\s*platform :ios, '[0-9.]+'$/, platform)
abort "iOS platform declaration not found in #{podfile_path}" if updated == podfile
File.write(podfile_path, updated)
RUBY

if grep -Fq 'com.example.guoguo' ios/Runner.xcodeproj/project.pbxproj; then
  echo 'Generated bundle identifier remains in the Xcode project.' >&2
  exit 1
fi

test "$(grep -c 'PRODUCT_BUNDLE_IDENTIFIER = com.example.dongmangongheguo;' ios/Runner.xcodeproj/project.pbxproj)" -eq 3
test "$(grep -c 'PRODUCT_BUNDLE_IDENTIFIER = com.example.dongmangongheguo.RunnerTests;' ios/Runner.xcodeproj/project.pbxproj)" -eq 3
test "$(grep -c 'IPHONEOS_DEPLOYMENT_TARGET = 15.0;' ios/Runner.xcodeproj/project.pbxproj)" -eq 3
grep -Fqx "platform :ios, '15.0'" ios/Podfile

"$flutter" pub add flutter_riverpod go_router dio flutter_secure_storage drift sqlite3_flutter_libs path_provider cached_network_image connectivity_plus share_plus collection
"$flutter" pub add --dev mocktail drift_dev build_runner pigeon golden_toolkit

cp "$repository_root/tool/task1_templates/widget_test.dart" test/widget_test.dart

set +e
"$flutter" test test/widget_test.dart 2>&1 | tee "$red_log"
red_status="${PIPESTATUS[0]}"
set -e

if [[ "$red_status" -eq 0 ]]; then
  echo 'Smoke test unexpectedly passed before GuoguoApp was implemented.' >&2
  exit 1
fi

if ! grep -Fq 'GuoguoApp' "$red_log"; then
  echo 'Smoke test failed for an unexpected reason.' >&2
  exit 1
fi

cp "$repository_root/tool/task1_templates/main.dart" lib/main.dart
