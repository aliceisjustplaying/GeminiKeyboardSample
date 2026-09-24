#!/bin/zsh
set -euo pipefail

project_root="${0:A:h:h}"
export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"

cd "$project_root"
xcodegen_bin="${XCODEGEN_BIN:-$(command -v xcodegen || true)}"
if [[ -n "$xcodegen_bin" ]]; then
  "$xcodegen_bin" generate
else
  echo "XcodeGen not found; using the committed Xcode project."
fi

device_id="$(xcrun simctl list devices available --json | ruby -rjson -e '
devices = JSON.parse(STDIN.read).fetch("devices").select { |runtime, _| runtime.include?("iOS-27-") }.values.flatten.select { |device| device["name"].start_with?("iPhone") }
devices.sort_by! { |device| device["state"] == "Booted" ? 0 : 1 }
puts devices.first&.fetch("udid", "")
')"
if [[ -z "$device_id" ]]; then
  echo "No available iOS 27 iPhone simulator was found."
  exit 1
fi

xcodebuild \
  -project GeminiVoiceKeyboard.xcodeproj \
  -scheme GeminiVoice \
  -destination "platform=iOS Simulator,id=$device_id" \
  -derivedDataPath DerivedData \
  test
