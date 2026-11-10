#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EXPECTED=(
  01-script-list.png
  02-script-editor.png
  03-reading-setup.png
  04-reading-progress.png
)
SCREENSHOT_DIRECTORIES=(
  "$ROOT_DIR/store_assets/screenshots/ios/ko-KR/iphone-6.9:ios"
  "$ROOT_DIR/store_assets/screenshots/android/ko-KR/phone:android"
  "$ROOT_DIR/store_assets/screenshots/qa-large-text/ios/ko-KR:ios"
  "$ROOT_DIR/store_assets/screenshots/qa-large-text/android/ko-KR:android"
)

fail() {
  echo "$1" >&2
  exit 1
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    fail "$1 명령이 필요합니다."
  fi
}

validate_files() {
  local directory="$1"
  local platform="$2"
  local file path properties width height alpha dimensions size png_count

  [[ -d "$directory" ]] || fail "스크린샷 디렉터리 누락: $directory"
  png_count="$(find "$directory" -maxdepth 1 -type f -name '*.png' | wc -l | tr -d ' ')"
  [[ "$png_count" == "${#EXPECTED[@]}" ]] ||
    fail "PNG 개수 오류: $directory (기대 ${#EXPECTED[@]}, 실제 $png_count)"

  for file in "${EXPECTED[@]}"; do
    path="$directory/$file"
    [[ -f "$path" ]] || fail "누락: $path"
    size="$(stat -f '%z' "$path")"
    [[ "$size" -ge 10000 ]] || fail "비정상적으로 작은 PNG: $path ($size bytes)"
    properties="$(python3 "$ROOT_DIR/tool/store_assets/png_tool.py" inspect "$path")" ||
      fail "손상된 PNG: $path"
    read -r width height alpha <<<"$properties"
    [[ "$width" =~ ^[0-9]+$ && "$height" =~ ^[0-9]+$ ]] ||
      fail "PNG 크기 판독 실패: $path (${width:-없음}x${height:-없음})"
    dimensions="${width}x${height}"

    [[ "$alpha" == "no" ]] || fail "알파 채널 금지: $path"
    if [[ "$platform" == "android" && "$dimensions" != "1080x1920" ]]; then
      fail "Android 크기 오류: $path ($dimensions)"
    fi
    if [[ "$platform" == "ios" ]]; then
      case "$dimensions" in
        1260x2736 | 1290x2796 | 1320x2868) ;;
        *) fail "iPhone 6.9형 크기 오류: $path ($dimensions)" ;;
      esac
    fi
  done
}

validate_fixture_manifest() {
  local manifest="$ROOT_DIR/store_assets/fixtures/manifest.json"
  local relative expected_hash copyright_status personal_data_status path actual_hash

  jq -e '
    .version == 1 and
    (.files | length > 0) and
    all(.files[];
      (.path | type == "string" and length > 0) and
      (.sha256 | test("^[0-9a-f]{64}$")) and
      .copyrightStatus == "original" and
      .personalDataStatus == "none"
    )
  ' "$manifest" >/dev/null || fail "픽스처 manifest 정책 오류: $manifest"

  while IFS=$'\t' read -r relative expected_hash copyright_status personal_data_status; do
    case "$relative" in
      /* | *..*) fail "안전하지 않은 픽스처 경로: $relative" ;;
    esac
    path="$ROOT_DIR/store_assets/fixtures/$relative"
    [[ -f "$path" ]] || fail "manifest 픽스처 누락: $path"
    actual_hash="$(shasum -a 256 "$path" | awk '{print $1}')"
    [[ "$actual_hash" == "$expected_hash" ]] ||
      fail "검토된 픽스처 해시 불일치: $relative"
    [[ "$copyright_status" == "original" ]] ||
      fail "원본 작성 확인이 없는 픽스처: $relative"
    [[ "$personal_data_status" == "none" ]] ||
      fail "개인정보 없음 확인이 없는 픽스처: $relative"
  done < <(jq -r '.files[] | [.path, .sha256, .copyrightStatus, .personalDataStatus] | @tsv' "$manifest")

  jq -e '
    .locale == "ko-KR" and
    .provenance.type == "original" and
    .provenance.containsPersonalData == false and
    (.scripts | length == 2) and
    all(.scripts[];
      (.id | type == "number") and
      (.title | type == "string" and length > 0) and
      (.body | type == "string" and length > 0)
    )
  ' "$ROOT_DIR/store_assets/fixtures/ko-KR/scripts.json" >/dev/null ||
    fail "고정 더미 데이터 구조 또는 provenance 오류"
}

validate_metadata_layout() {
  [[ -f "$ROOT_DIR/fastlane/metadata/ios/ko/README.md" ]] ||
    fail "App Store Fastlane 메타데이터 구조 누락"
  [[ -f "$ROOT_DIR/fastlane/metadata/android/ko-KR/README.md" ]] ||
    fail "Google Play Fastlane 메타데이터 구조 누락"
}

validate_sensitive_content() {
  local scan_file
  scan_file="$(mktemp "${TMPDIR:-/tmp}/maltto-store-validation.XXXXXX")"
  find \
    "$ROOT_DIR/store_assets" \
    "$ROOT_DIR/fastlane/metadata" \
    "$ROOT_DIR/integration_test/support/store_screenshot_fixture.dart" \
    -type f ! -name '*.png' -print0 >"$scan_file"

  if xargs -0 grep -Ein \
    '([[:alnum:]_.%+-]+@[[:alnum:].-]+\.[[:alpha:]]{2,})|(01[016789][ -]?[0-9]{3,4}[ -]?[0-9]{4})|(AKIA[0-9A-Z]{16})|(-----BEGIN [A-Z ]*PRIVATE KEY-----)|(/Users/[^/[:space:]]+)' \
    <"$scan_file"; then
    rm -f "$scan_file"
    fail "개인정보·시크릿·로컬 사용자 경로 의심 패턴 발견"
  fi
  rm -f "$scan_file"
}

validate_unique_screenshots() {
  local duplicate_hashes
  duplicate_hashes="$(
    find "$ROOT_DIR/store_assets/screenshots" -type f -name '*.png' -exec shasum -a 256 {} + |
      awk '{print $1}' |
      sort |
      uniq -d
  )"
  [[ -z "$duplicate_hashes" ]] ||
    fail "서로 다른 시나리오에 중복 PNG가 있습니다: $duplicate_hashes"
}

require_command jq
require_command python3
require_command shasum
python3 -c 'import PIL' >/dev/null 2>&1 ||
  fail "Pillow가 필요합니다: python3 -m pip install -r tool/store_assets/requirements.txt"

validate_metadata_layout
validate_fixture_manifest
validate_sensitive_content

for entry in "${SCREENSHOT_DIRECTORIES[@]}"; do
  validate_files "${entry%:*}" "${entry##*:}"
done
validate_unique_screenshots

echo "스토어 메타데이터·고정 픽스처·스크린샷 규격·민감정보 검증 완료"
