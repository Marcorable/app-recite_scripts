#!/bin/bash
# 비민감 낭독 진단 로그와 Android 자원 지표를 정해진 시간 동안 수집한다.
set -euo pipefail

platform="${1:-}"
duration_seconds="${2:-300}"
output_dir="${3:-.build/reading-diagnostics}"
package_name="com.marcorable.maltto"

if [[ ! "$duration_seconds" =~ ^[0-9]+$ ]] || [ "$duration_seconds" -lt 1 ]; then
    echo "사용법: $0 <android|ios-simulator> [초] [출력 디렉터리]" >&2
    exit 1
fi

mkdir -p "$output_dir"
timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
events_file="$output_dir/$platform-$timestamp-events.log"
metrics_file="$output_dir/$platform-$timestamp-metrics.log"
raw_file="$(mktemp)"
logger_pid=""

cleanup() {
    if [ -n "$logger_pid" ]; then
        kill "$logger_pid" 2>/dev/null || true
        wait "$logger_pid" 2>/dev/null || true
    fi
    rm -f "$raw_file"
}
trap cleanup EXIT INT TERM

case "$platform" in
android)
    adb get-state >/dev/null
    adb logcat -c
    adb logcat -v epoch flutter:I MalttoSttFlow:D '*:S' >"$raw_file" &
    logger_pid=$!
    ;;
ios-simulator)
    xcrun simctl bootstatus booted -b >/dev/null
    xcrun simctl spawn booted log stream --style compact \
        --predicate 'eventMessage CONTAINS "MalttoReadingDiagnostics"' \
        >"$raw_file" &
    logger_pid=$!
    ;;
*)
    echo "사용법: $0 <android|ios-simulator> [초] [출력 디렉터리]" >&2
    exit 1
    ;;
esac

started_at="$(date +%s)"
while [ "$(($(date +%s) - started_at))" -lt "$duration_seconds" ]; do
    now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    if [ "$platform" = android ]; then
        total_pss="$(adb shell dumpsys meminfo "$package_name" | awk '/TOTAL PSS:/ {print $3; exit}')"
        total_rss="$(adb shell dumpsys meminfo "$package_name" | awk '/TOTAL RSS:/ {print $3; exit}')"
        printf '%s totalPssKb=%s totalRssKb=%s\n' "$now" "${total_pss:-unavailable}" "${total_rss:-unavailable}" >>"$metrics_file"
    else
        printf '%s sample=heartbeat\n' "$now" >>"$metrics_file"
    fi
    remaining="$((duration_seconds - ($(date +%s) - started_at)))"
    [ "$remaining" -le 0 ] && break
    if [ "$remaining" -lt 30 ]; then sleep "$remaining"; else sleep 30; fi
done

kill "$logger_pid" 2>/dev/null || true
wait "$logger_pid" 2>/dev/null || true
logger_pid=""
grep 'MalttoReadingDiagnostics' "$raw_file" >"$events_file" || true

echo "진단 이벤트: $events_file"
echo "자원 지표: $metrics_file"
