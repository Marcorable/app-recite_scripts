#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PLATFORM="${1:-all}"
IOS_IPHONE_DEVICE_NAME="${IOS_IPHONE_DEVICE_NAME:-${IOS_DEVICE_NAME:-iPhone 18 Pro Max}}"
IOS_IPAD_DEVICE_NAME="${IOS_IPAD_DEVICE_NAME:-iPad Pro 13-inch (M5)}"
IOS_IPHONE_DEVICE_ID="${IOS_IPHONE_DEVICE_ID:-${IOS_DEVICE_ID:-}}"
IOS_IPAD_DEVICE_ID="${IOS_IPAD_DEVICE_ID:-}"
ANDROID_AVD="${ANDROID_AVD:-Medium_Phone_API_36}"
ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-$HOME/Library/Android/sdk}}"
ADB="${ADB:-$ANDROID_SDK_ROOT/platform-tools/adb}"
EMULATOR="${EMULATOR:-$ANDROID_SDK_ROOT/emulator/emulator}"
STARTED_EMULATOR_PID=""
ANDROID_SIZE_OVERRIDDEN="false"
ANDROID_FONT_SCALE_OVERRIDDEN="false"
ANDROID_ORIGINAL_FONT_SCALE=""
TEMP_CAPTURE_DIRS=()
EXPECTED=(
  01-script-list.png
  02-script-editor.png
  03-reading-setup.png
  04-reading-progress.png
)

if [[ "$PLATFORM" != "all" && "$PLATFORM" != "ios" && "$PLATFORM" != "android" ]]; then
  echo "usage: $0 [all|ios|android]" >&2
  exit 64
fi

if ! python3 -c 'import PIL' >/dev/null 2>&1; then
  echo "Pillow가 필요합니다: python3 -m pip install -r tool/store_assets/requirements.txt" >&2
  exit 1
fi

cleanup() {
  local directory
  if [[ "$ANDROID_SIZE_OVERRIDDEN" == "true" && -n "${ANDROID_DEVICE_ID:-}" ]]; then
    "$ADB" -s "$ANDROID_DEVICE_ID" shell wm size reset >/dev/null 2>&1 || true
    "$ADB" -s "$ANDROID_DEVICE_ID" shell wm density reset >/dev/null 2>&1 || true
  fi
  if [[ "$ANDROID_FONT_SCALE_OVERRIDDEN" == "true" && -n "${ANDROID_DEVICE_ID:-}" ]]; then
    "$ADB" -s "$ANDROID_DEVICE_ID" shell settings put system font_scale \
      "$ANDROID_ORIGINAL_FONT_SCALE" >/dev/null 2>&1 || true
  fi
  if [[ -n "$STARTED_EMULATOR_PID" ]]; then
    kill "$STARTED_EMULATOR_PID" >/dev/null 2>&1 || true
  fi
  for directory in "${TEMP_CAPTURE_DIRS[@]}"; do
    if [[ -d "$directory" && "$directory" == "$ROOT_DIR/store_assets/screenshots/"*".tmp."* ]]; then
      rm -rf -- "$directory"
    fi
  done
}
trap cleanup EXIT

flatten_pngs() {
  local output_dir="$1"
  local file flattened properties width height alpha
  for file in "$output_dir"/*.png; do
    flattened="${file%.png}.rgb.png"
    if ! python3 "$ROOT_DIR/tool/store_assets/png_tool.py" flatten "$file" "$flattened"; then
      echo "PNG 변환 검증 실패: $file" >&2
      rm -f "$flattened"
      exit 1
    fi
    properties="$(python3 "$ROOT_DIR/tool/store_assets/png_tool.py" inspect "$flattened")"
    read -r width height alpha <<<"$properties"
    if [[ ! "$width" =~ ^[0-9]+$ || ! "$height" =~ ^[0-9]+$ || "$alpha" != "no" ]]; then
      echo "PNG 크기 판독 실패: $file" >&2
      rm -f "$flattened"
      exit 1
    fi
    mv "$flattened" "$file"
  done
}

capture() {
  local device_id="$1"
  local output_dir="$2"
  local large_text="$3"
  local platform="$4"
  local staging_dir file

  mkdir -p "$(dirname "$output_dir")"
  staging_dir="$(mktemp -d "${output_dir}.tmp.XXXXXX")"
  TEMP_CAPTURE_DIRS+=("$staging_dir")
  if [[ "$platform" == "android" ]]; then
    if [[ "$large_text" == "true" ]]; then
      "$ADB" -s "$device_id" shell settings put system font_scale 2.0
    else
      "$ADB" -s "$device_id" shell settings put system font_scale 1.0
    fi
  fi
  if [[ "$large_text" == "true" ]]; then
    (
      cd "$ROOT_DIR"
      STORE_SCREENSHOT_OUTPUT="$staging_dir" \
        flutter drive \
        --driver=test_driver/store_screenshots_driver.dart \
        --target=integration_test/store_screenshots_test.dart \
        -d "$device_id" \
        --dart-define=STORE_LARGE_TEXT=true
    )
  else
    (
      cd "$ROOT_DIR"
      STORE_SCREENSHOT_OUTPUT="$staging_dir" \
        flutter drive \
        --driver=test_driver/store_screenshots_driver.dart \
        --target=integration_test/store_screenshots_test.dart \
        -d "$device_id"
    )
  fi
  flatten_pngs "$staging_dir"

  for file in "${EXPECTED[@]}"; do
    if [[ ! -f "$staging_dir/$file" ]]; then
      echo "캡처 누락: $staging_dir/$file" >&2
      exit 1
    fi
  done
  mkdir -p "$output_dir"
  for file in "${EXPECTED[@]}"; do
    mv "$staging_dir/$file" "$output_dir/$file"
  done
  rmdir "$staging_dir"
}

resolve_ios_device() {
  local device_name="$1"
  local device_id="$2"
  if [[ -n "$device_id" ]]; then
    printf '%s\n' "$device_id"
    return
  fi
  xcrun simctl list devices available -j | jq -r --arg name "$device_name" '
    [.devices | to_entries[] | .key as $runtime | .value[]
      | select(.name == $name and .isAvailable == true)
      | {runtime: $runtime, udid: .udid}]
    | sort_by(.runtime) | last | .udid // empty
  '
}

capture_ios_device() {
  local device_name="$1"
  local configured_device_id="$2"
  local output_name="$3"
  local device_id
  device_id="$(resolve_ios_device "$device_name" "$configured_device_id")"
  if [[ -z "$device_id" ]]; then
    echo "사용 가능한 $device_name 시뮬레이터를 찾지 못했습니다." >&2
    exit 1
  fi
  xcrun simctl boot "$device_id" >/dev/null 2>&1 || true
  xcrun simctl bootstatus "$device_id" -b

  capture \
    "$device_id" \
    "$ROOT_DIR/store_assets/screenshots/ios/ko-KR/$output_name" \
    false \
    ios
  capture \
    "$device_id" \
    "$ROOT_DIR/store_assets/screenshots/qa-large-text/ios/ko-KR/$output_name" \
    true \
    ios
}

capture_ios() {
  capture_ios_device \
    "$IOS_IPHONE_DEVICE_NAME" \
    "$IOS_IPHONE_DEVICE_ID" \
    iphone-6.9
  capture_ios_device \
    "$IOS_IPAD_DEVICE_NAME" \
    "$IOS_IPAD_DEVICE_ID" \
    ipad-13
}

wait_for_android() {
  "$ADB" -s "$ANDROID_DEVICE_ID" wait-for-device
  local attempt
  for attempt in {1..90}; do
    if [[ "$("$ADB" -s "$ANDROID_DEVICE_ID" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" == "1" ]]; then
      return
    fi
    sleep 2
  done
  echo "Android 에뮬레이터 부팅 시간이 초과됐습니다." >&2
  exit 1
}

resolve_android_device() {
  if [[ -n "${ANDROID_DEVICE_ID:-}" ]]; then
    return
  fi
  ANDROID_DEVICE_ID="$(
    "$ADB" devices | awk 'NR > 1 && $1 ~ /^emulator-/ && $2 == "device" {print $1; exit}'
  )"
  if [[ -n "$ANDROID_DEVICE_ID" ]]; then
    export ANDROID_DEVICE_ID
    return
  fi

  "$EMULATOR" -avd "$ANDROID_AVD" -no-window -no-audio -no-boot-anim &
  STARTED_EMULATOR_PID="$!"
  ANDROID_DEVICE_ID="emulator-5554"
  export ANDROID_DEVICE_ID
  wait_for_android
}

capture_android() {
  resolve_android_device
  wait_for_android
  ANDROID_ORIGINAL_FONT_SCALE="$(
    "$ADB" -s "$ANDROID_DEVICE_ID" shell settings get system font_scale | tr -d '\r'
  )"
  if [[ -z "$ANDROID_ORIGINAL_FONT_SCALE" || "$ANDROID_ORIGINAL_FONT_SCALE" == "null" ]]; then
    ANDROID_ORIGINAL_FONT_SCALE="1.0"
  fi
  ANDROID_FONT_SCALE_OVERRIDDEN="true"
  "$ADB" -s "$ANDROID_DEVICE_ID" shell wm size 1080x1920
  "$ADB" -s "$ANDROID_DEVICE_ID" shell wm density 420
  ANDROID_SIZE_OVERRIDDEN="true"

  capture \
    "$ANDROID_DEVICE_ID" \
    "$ROOT_DIR/store_assets/screenshots/android/ko-KR/phone" \
    false \
    android
  capture \
    "$ANDROID_DEVICE_ID" \
    "$ROOT_DIR/store_assets/screenshots/qa-large-text/android/ko-KR" \
    true \
    android
}

if [[ "$PLATFORM" == "all" || "$PLATFORM" == "ios" ]]; then
  capture_ios
fi
if [[ "$PLATFORM" == "all" || "$PLATFORM" == "android" ]]; then
  capture_android
fi
