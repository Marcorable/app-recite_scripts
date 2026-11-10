#!/bin/sh

set -eu

readonly FLUTTER_VERSION="3.47.7"
readonly FLUTTER_INSTALL_DIR="${HOME}/flutter"

cd "${CI_PRIMARY_REPOSITORY_PATH:?CI_PRIMARY_REPOSITORY_PATH is required}"

git clone \
  --branch "${FLUTTER_VERSION}" \
  --depth 1 \
  https://github.com/flutter/flutter.git \
  "${FLUTTER_INSTALL_DIR}"

export PATH="${FLUTTER_INSTALL_DIR}/bin:${PATH}"

flutter config --no-analytics
flutter precache --ios
flutter pub get

readonly WORKSPACE_PACKAGE_RESOLVED="ios/Runner.xcworkspace/xcshareddata/swiftpm/Package.resolved"
readonly PROJECT_SWIFTPM_DIR="ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/swiftpm"

if [ ! -f "${WORKSPACE_PACKAGE_RESOLVED}" ]; then
  echo "Missing ${WORKSPACE_PACKAGE_RESOLVED}" >&2
  exit 1
fi

mkdir -p "${PROJECT_SWIFTPM_DIR}"
cp "${WORKSPACE_PACKAGE_RESOLVED}" "${PROJECT_SWIFTPM_DIR}/Package.resolved"

set -- --release --no-codesign --config-only
if [ -n "${CI_BUILD_NUMBER:-}" ]; then
  set -- "$@" "--build-number=${CI_BUILD_NUMBER}"
fi

flutter build ios "$@"
