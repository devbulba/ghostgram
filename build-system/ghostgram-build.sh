#!/usr/bin/env bash
set -euo pipefail

BUILD_NUMBER=$(( $(git rev-list --count HEAD) + $(cat build_number_offset) ))
echo "BUILD_NUMBER=$BUILD_NUMBER"

python3 -u build-system/Make/Make.py \
  --overrideXcodeVersion \
  build \
  --configurationPath="build-system/appstore-configuration.json" \
  --codesigningInformationPath=build-system/fake-codesigning \
  --configuration=release_arm64 \
  --buildNumber="$BUILD_NUMBER"