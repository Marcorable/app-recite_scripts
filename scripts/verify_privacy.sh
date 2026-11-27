#!/bin/bash
# 개인정보 출시 게이트의 정적 설정과 제품 코드 경계를 검사한다.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

fail() {
    echo "개인정보 검증 실패: $1" >&2
    exit 1
}

manifest="android/app/src/main/AndroidManifest.xml"
rules="android/app/src/main/res/xml/data_extraction_rules.xml"
ios_adapter="ios/Runner/IosLocalStorageAdapter.swift"
database="lib/src/infrastructure/database/app_database.dart"

grep -Fq 'android:allowBackup="false"' "$manifest" || fail "Android allowBackup이 false가 아니다"
grep -Fq 'android:dataExtractionRules="@xml/data_extraction_rules"' "$manifest" || fail "Android data extraction 규칙이 연결되지 않았다"

for section in cloud-backup device-transfer; do
    section_body="$(sed -n "/<$section>/,/<\/$section>/p" "$rules")"
    for domain in root file database sharedpref external; do
        grep -Fq "<exclude domain=\"$domain\" path=\".\" />" <<<"$section_body" ||
            fail "Android $section에서 $domain 데이터가 제외되지 않았다"
    done
done

grep -Fq 'values.isExcludedFromBackup = true' "$ios_adapter" || fail "iOS Application Support 백업 제외 속성이 없다"
grep -Fq 'excludeApplicationSupportFromBackup' "$database" || fail "iOS 데이터베이스 생성 전에 백업 제외를 호출하지 않는다"

# STT 오디오는 메모리 버퍼나 익명 파이프로만 전달해야 한다. 실제 파일 기록 API가
# 제품 STT 코드에 추가되면 사람이 용도를 검토할 때까지 출시 게이트를 닫는다.
recording_file_pattern='AVAudioFile|MediaRecorder[.]OutputFormat|setOutputFile|FileOutputStream|RandomAccessFile'
if recording_matches="$(git grep -n -E "$recording_file_pattern" -- \
    ios/Runner/IosSpeechAdapter.swift \
    ios/Runner/IosSpeechSession.swift \
    android/app/src/main/kotlin/com/marcorable/maltto/AndroidSpeechAdapter.kt \
    android/app/src/main/kotlin/com/marcorable/maltto/AndroidRecognitionAudioSource.kt 2>/dev/null)"; then
    printf '%s\n' "$recording_matches"
    fail "STT 제품 코드에서 오디오 파일 기록 API가 발견됐다"
fi

# 사용자 입력이나 STT 전사문을 Firebase에 전달하는 호출을 금지한다. 허용되는
# debug_verification 이벤트는 고정 문자열만 전송하며 사용자 필드를 갖지 않는다.
# 호출명과 인자가 서로 다른 줄에 있어도 닫는 `);`까지 하나의 블록으로 검사한다.
telemetry_scanner='while (/(?:logEvent|recordError|setUserId|setUserProperty|setCustomKey)\s*\((?:(?!\s*\);)[\s\S]){0,4000}?\b(?:script|transcript|text|body|audio)\b(?:(?!\s*\);)[\s\S])*?\s*\);/gi) { print "$ARGV:$&\n" }'
scanner_fixture="$(mktemp)"
trap 'rm -f "$scanner_fixture"' EXIT
printf '%s\n' \
    '_analytics.logEvent(' \
    "  name: 'read'," \
    "  parameters: {'body': script.body}," \
    ');' \
    "_analytics.logEvent(name: 'read', parameters: {'body': script.body});" \
    >"$scanner_fixture"
scanner_fixture_matches="$(perl -0 -ne "$telemetry_scanner" "$scanner_fixture" | grep -c "$scanner_fixture")"
if [ "$scanner_fixture_matches" -ne 2 ]; then
    fail "한 줄·여러 줄 telemetry 회귀 검사기가 동작하지 않는다"
fi

dart_sources="$(git ls-files 'lib/src/*.dart' 'lib/src/**/*.dart')"
# 파일 이름은 저장소 정책상 공백을 포함하지 않는다.
# shellcheck disable=SC2086
if telemetry_matches="$(perl -0 -ne "$telemetry_scanner" $dart_sources)" &&
    [ -n "$telemetry_matches" ]; then
    printf '%s\n' "$telemetry_matches"
    fail "사용자 콘텐츠가 telemetry로 전달될 가능성이 있다"
fi

./scripts/check_public_repo.sh
echo "개인정보 정적 출시 게이트 통과"
