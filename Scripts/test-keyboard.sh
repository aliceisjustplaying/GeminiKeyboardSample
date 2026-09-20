#!/bin/zsh
set -euo pipefail

project_root="${0:A:h:h}"
cd "$project_root"
if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <iPhone simulator UDID>"
  exit 1
fi
xcodegen generate --spec KeyboardIntegrationTests/project.yml
xcodebuild \
  -project KeyboardIntegrationTests/KeyboardIntegrationCheck.xcodeproj \
  -scheme KeyboardIntegrationCheck \
  -destination "platform=iOS Simulator,id=$1" \
  -derivedDataPath build/IntegrationDerivedData \
  -clonedSourcePackagesDirPath build/SourcePackages \
  -parallel-testing-enabled NO \
  test
