# Issue #107 장시간 낭독 진단 기록

- 일시: 2026-11-27
- 앱: Debug, `READING_DIAGNOSTICS=true`
- Samsung: SM-F776N, Android 17 (API 37)
- iPhone: iPhone 12 Pro, iOS 27.2.1

## 자동 검증

- 진단 이벤트에는 세션 ID, generation, 회차, 커서, 전체 어절 수, 경과 시간, 종료 사유만 포함된다.
- 단위 테스트에서 제목, 본문, 현재 어절, 전사문이 직렬화되지 않음을 확인했다.
- Android와 iOS 실기기에 진단 Debug 빌드를 설치하고 앱 실행을 확인했다.
- Android에서 567초 실제 음성 세션을 유지하며 60초 간격 heartbeat 8회를 확인했다.
- Android 자원 표본 12개의 PSS/RSS는 약 702~772MB 범위에서 오르내렸고 지속 상승하지 않았다.
- Android Release APK 빌드가 통과했고 산출물에서 `MalttoReadingDiagnostics` 문자열이 제거됨을 확인했다.

## 실제 낭독 판정

- 기본 중립 대본을 실제 음성으로 10회 반복해 09:27에 완료했다.
- `repetitionCompleted` 9회, `nextRepetitionStarted` 9회, 마지막 `sessionCompleted` 1회를 확인했다.
- 현재 어절이 진행될 때 후반 어절까지 화면 안에 유지되어 자동 스크롤이 정상 동작했다.
- 자동 조작 중 한 어절 뒤로가 한 번 실행됐으며 generation 증가, 인식 재시작, 이후 완료까지 확인했다.
- 크래시, 마이크 조기 종료, 중복 완료는 없었다.

STAB-01~03과 READ-06~07의 장시간 실기기 출시 게이트를 통과로 판정한다.

## 로컬 증거

- 이벤트: `.build/reading-diagnostics/issue-107-actual-reading/*-events.log`, Android logcat 후속 완료 이벤트
- 메모리: `.build/reading-diagnostics/issue-107-actual-reading/*-metrics.log`
- 완료 화면: `/tmp/issue-107-display0.png`

로컬 원본에는 대본 제목·본문·전사문·음성 데이터가 없다.
