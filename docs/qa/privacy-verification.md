# 개인정보 출시 게이트 실행 절차

> Issue #105. 검증에는 직접 작성한 중립 대본만 사용하고 대본·전사문·음성은 증거 파일에 남기지 않는다.

## 자동 검사

```sh
./scripts/verify_privacy.sh
```

이 명령은 다음을 실패 조건으로 검사한다.

- Android cloud backup과 device transfer에 앱의 모든 저장 도메인이 포함됨
- iOS Application Support에 `isExcludedFromBackup` 설정이 누락됨
- STT 코드에 녹음 파일 기록 API가 추가됨
- 사용자 대본·전사문·음성을 Firebase telemetry에 전달할 가능성이 있는 코드가 추가됨
- Public 저장소의 시크릿·개인정보·금지 콘텐츠 정책 위반

## 실기기 네트워크 검사 (PRIV-01)

1. Charles 또는 Proxyman을 실행하고 Mac과 실기기를 같은 네트워크에 연결한다.
2. 실기기의 HTTP 프록시를 Mac으로 지정한다. HTTPS 복호화는 테스트 기기에만 인증서를 설치해 사용한다.
3. 앱을 강제 종료한 뒤 캡처를 시작하고 `추가 → 저장 → 1회 낭독 → 한 어절 뒤로 → 나가기 → 삭제`를 수행한다.
4. 알려진 Firebase 목적지(`googleapis.com`, `app-measurement.com`, `crashlytics.com`)와 STT 시스템 프로세스의 연결을 분리해 기록한다.
5. 요청 URL·헤더·본문에서 중립 대본 표식, 인식 문장, 오디오 MIME 또는 바이너리 업로드가 없는지 검색한다.
6. 증거에는 목적지, HTTP 메서드, 본문 크기, 판정만 남기고 요청 토큰·설치 ID·대본·전사문은 저장하지 않는다.

앱의 Firebase Analytics·Crashlytics·App Check 연결 자체는 정상이다. 통과 기준은 사용자 대본·전사문·음성이 해당 연결에 포함되지 않는 것이다.

## 샌드박스와 로그 검사 (PRIV-02)

Android debug 빌드에서 핵심 흐름을 마친 뒤 실행한다.

```sh
adb shell run-as com.marcorable.maltto find . -type f -print
adb logcat -d -v brief MalttoSttFlow:D flutter:I '*:S'
```

허용 파일은 SQLite 데이터베이스와 앱·SDK 설정 파일이다. `.wav`, `.m4a`, `.aac`, `.pcm`, `.caf`, `.tmp` 같은 녹음·원시 버퍼 파일이 없어야 한다. 로그에는 상태 코드와 고정 오류 문구만 있어야 하며 대본·전사문이 없어야 한다.

iOS Simulator에서 핵심 흐름을 마친 뒤 앱 컨테이너를 확인한다.

```sh
container="$(xcrun simctl get_app_container booted com.marcorable.maltto data)"
find "$container" -type f -print
xcrun simctl spawn booted log show --last 10m --style compact --predicate 'process == "Runner"'
```

실기기 컨테이너 검사는 Xcode Devices and Simulators의 Download Container로 내려받은 뒤 같은 확장자 기준을 적용한다. 증거에는 전체 로컬 경로나 사용자 콘텐츠를 남기지 않고 파일 종류와 개수만 기록한다.

## 백업 제외 검사 (PRIV-04)

Android 빌드 산출물은 다음으로 확인한다.

```sh
apkanalyzer manifest print build/app/outputs/flutter-apk/app-release.apk | grep -E 'allowBackup|dataExtractionRules'
./scripts/verify_privacy.sh
```

iOS Simulator에서는 앱 실행 후 Application Support 속성을 확인한다.

```sh
container="$(xcrun simctl get_app_container booted com.marcorable.maltto data)"
xattr -p com.apple.metadata:com_apple_backup_excludeItem "$container/Library/Application Support"
```

## 결과 기록

`docs/qa/evidence-template.md` 형식으로 빌드 SHA, 기기·OS, 케이스 ID, 결과, 정제된 증거 위치를 기록한다. 실패 시 원본 캡처를 저장소에 커밋하지 말고 민감 정보를 제거한 재현 정보만 별도 Issue에 남긴다.
