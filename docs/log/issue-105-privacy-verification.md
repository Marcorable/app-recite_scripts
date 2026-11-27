# Issue #105 개인정보 검증 결과

검증일: 2026-11-27  
대상: `105` 브랜치 Debug 빌드

## 자동·정적 판정

| 케이스 | 결과 | 근거 |
|---|---|---|
| PRIV-01 | 통과 | 제품 Dart 코드의 외부 SDK 경계는 Firebase Analytics·Crashlytics·App Check뿐이며 이벤트는 고정 `debug_verification`만 사용한다. 대본·전사문·음성을 전달하는 API 호출이 없고 `scripts/verify_privacy.sh`가 회귀를 차단한다. |
| PRIV-02 | 통과 | iPhone Duo Simulator와 Samsung SM-F776N에서 앱 실행 후 샌드박스를 검사했다. SQLite와 Firebase SDK 상태 파일 외에 `.wav`, `.m4a`, `.aac`, `.pcm`, `.caf`, `.tmp` 녹음·원시 버퍼 파일이 없었다. STT 구현은 iOS 메모리 버퍼, Android 익명 pipe만 사용한다. |
| PRIV-04 Android | 통과 | `android:allowBackup="false"`와 `dataExtractionRules`가 적용되고 cloud backup·device transfer의 `root`, `file`, `database`, `sharedpref`, `external`을 모두 제외한다. Android Debug APK 빌드와 리소스 병합이 통과했다. |
| PRIV-04 iOS | 통과 | 앱 시작 시 Application Support에 `isExcludedFromBackup`을 설정한다. iPhone Duo Simulator에서 `com.apple.metadata:com_apple_backup_excludeItem = com.apple.MobileBackup` 속성을 확인했다. |

## 실행 환경

- Android: Samsung SM-F776N, Android 17/API 37, USB 연결
- iOS: iPhone Duo Simulator, iOS 27.2
- 중립 데이터: 앱 최초 설치 예시 대본
- 저장소 검사: `./scripts/check_public_repo.sh`, `./scripts/verify_privacy.sh`

실기기 프록시 캡처가 필요한 재검증 절차는 `docs/qa/privacy-verification.md`에 고정했다. 캡처 원본에는 설치 식별자와 토큰이 포함될 수 있으므로 저장소에는 커밋하지 않는다.
