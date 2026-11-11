#!/bin/bash

set -eu

if [[ "${PLATFORM_NAME:-}" == *simulator* ]]; then
  exit 0
fi

export PATH="${PATH}:${FLUTTER_ROOT:-}/bin:${PUB_CACHE:-}/bin:${HOME}/.pub-cache/bin"

readonly CRASHLYTICS_RELATIVE_PATH="SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run"

find_upload_script() {
  local candidate
  for candidate in \
    "${PODS_ROOT:-}/FirebaseCrashlytics/run" \
    "${BUILD_DIR:-}/${CRASHLYTICS_RELATIVE_PATH}" \
    "${BUILD_DIR%%/Build/*}/${CRASHLYTICS_RELATIVE_PATH}" \
    "${BUILD_ROOT%%/Build/*}/${CRASHLYTICS_RELATIVE_PATH}" \
    "${CI_WORKSPACE_PATH:-}/DerivedData/${CRASHLYTICS_RELATIVE_PATH}" \
    "${PROJECT_DIR:-}/build/${CRASHLYTICS_RELATIVE_PATH}"
  do
    if [ -f "${candidate}" ]; then
      printf '%s\n' "${candidate}"
      return 0
    fi
  done

  return 1
}

if ! upload_script="$(find_upload_script)"; then
  echo "Unable to locate the Firebase Crashlytics upload-symbols script." >&2
  exit 1
fi

flutterfire upload-crashlytics-symbols \
  --upload-symbols-script-path="${upload_script}" \
  --platform=ios \
  --apple-project-path="${SRCROOT}" \
  --env-platform-name="${PLATFORM_NAME}" \
  --env-configuration="${CONFIGURATION}" \
  --env-project-dir="${PROJECT_DIR}" \
  --env-built-products-dir="${BUILT_PRODUCTS_DIR}" \
  --env-dwarf-dsym-folder-path="${DWARF_DSYM_FOLDER_PATH}" \
  --env-dwarf-dsym-file-name="${DWARF_DSYM_FILE_NAME}" \
  --env-infoplist-path="${INFOPLIST_PATH}" \
  --default-config=default
