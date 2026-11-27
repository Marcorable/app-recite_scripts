# Issue #107 장시간 낭독 진단 기록

- 일시: 2026-11-27
- 앱: Debug, `READING_DIAGNOSTICS=true`
- Samsung: SM-F776N, Android 17 (API 37)
- iPhone: iPhone 12 Pro, iOS 27.2.1

## 자동 검증

- 진단 이벤트에는 세션 ID, generation, 회차, 커서, 전체 어절 수, 경과 시간, 종료 사유만 포함된다.
- 단위 테스트에서 제목, 본문, 현재 어절, 전사문이 직렬화되지 않음을 확인했다.
- Android와 iOS 실기기에 진단 Debug 빌드를 설치하고 앱 실행을 확인했다.
- Android에서 300초 세션을 유지하며 60·120·180·240·300초 heartbeat를 확인했다.
- Android 자원 표본 11개 중 시작 직후를 제외한 PSS/RSS는 약 718~722MB 범위였다.
- Android Release APK 빌드가 통과했고 산출물에서 `MalttoReadingDiagnostics` 문자열이 제거됨을 확인했다.

## 실제 낭독 판정

25초 동안 첫 8어절 전진은 확인했지만 조용한 테스트 환경을 유지하기 위해 음성 재생을 중단했다. 따라서 5분 전체 실제 낭독, 자동 스크롤, 반복 회차 완료는 아직 통과로 판정하지 않는다. 위 자동 검증 결과를 실제 낭독 통과 근거로 대체하지 않는다.

## 로컬 증거

- 이벤트: `.build/reading-diagnostics/issue-107-samsung-final/*-events.log`
- 메모리: `.build/reading-diagnostics/issue-107-samsung-final/*-metrics.log`

로컬 원본에는 대본 제목·본문·전사문·음성 데이터가 없다.
