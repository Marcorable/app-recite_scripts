# 장시간 낭독 진단 절차

> Issue #107. 진단에는 세션 ID, generation, 회차, 커서, 전체 어절 수, 경과 시간, 종료 사유만 포함한다. 대본 제목·본문·현재 어절·전사문·음성은 기록하지 않는다.

## 진단 빌드

진단은 기본값이 꺼져 있고 Debug 빌드에서 명시적으로 요청할 때만 출력된다.

```sh
flutter run --debug --dart-define=READING_DIAGNOSTICS=true -d <device-id>
```

Release 빌드와 `READING_DIAGNOSTICS`가 없는 Debug 빌드는 `NoopReadingSessionDiagnostics`를 사용한다.

## 중립 장시간 fixture

다음 명령의 출력을 새 대본 본문에 붙여 넣는다. 저장소에서 직접 작성한 중립 문장 여덟 개를 열두 번 이어 약 5분 이상 읽도록 구성한다.

```sh
./scripts/generate_long_reading_fixture.sh | pbcopy
```

제목은 `장시간 연습`, 반복은 1회로 설정한다. 실제 증거에는 제목이나 본문을 기록하지 않고 fixture ID `LONG-A`만 쓴다.

## Android 수집

앱에서 낭독 시작 직전에 다른 터미널에서 실행한다.

```sh
./scripts/collect_reading_diagnostics.sh android 330
```

이 명령은 30초 간격의 PSS·RSS와 `MalttoReadingDiagnostics` 이벤트만 `.build/reading-diagnostics`에 남긴다. 실행 전후에는 다음도 확인한다.

```sh
adb shell dumpsys media.audio_flinger
adb shell dumpsys batterystats com.marcorable.maltto
adb shell run-as com.marcorable.maltto find . -type f -print
```

## iOS 수집

Simulator에서는 다음 명령을 사용한다.

```sh
./scripts/collect_reading_diagnostics.sh ios-simulator 330
```

실기기는 Xcode Instruments의 Allocations·Energy Log를 5분 동안 기록하고 Console에서 `MalttoReadingDiagnostics`를 필터링한다. 내보낸 원본은 로컬 QA 증거 폴더에 두고 저장소에는 세션 상태와 최대 메모리·에너지 판정만 기록한다.

## 시나리오

- STAB-01: LONG-A를 5분 이상 실제로 읽고 heartbeat 1~5, 조기 종료 없음, 완료 또는 사용자가 명시적으로 나간 종료 한 번을 확인한다.
- STAB-02: `시작 → 일부 낭독 → 한 어절 뒤로 → 나가기`를 10회 수행한다. 각 회차의 generation 증가와 `sessionLeft` 한 번, 다음 세션의 ID 증가를 확인한다.
- STAB-03: 짧은 중립 대본을 10회 반복한다. 회차마다 `repetitionCompleted`, 이어하기 뒤 `nextRepetitionStarted`, 마지막에 `sessionCompleted`가 정확히 한 번이어야 한다.
- READ-06: LONG-A에서 커서가 화면 아래로 진행할 때 현재 어절이 보이도록 스크롤되고 불필요한 왕복이 없어야 한다.
- READ-07: `movedBack` 뒤 cursor가 정확히 하나 감소하고 generation이 증가하며 과거 generation 이벤트가 커서를 전진시키지 않아야 한다.

## 판정

통과 조건은 크래시·마이크 조기 종료·중복 완료가 없고, 종료 후 마이크 표시가 사라지며, 5개의 1분 heartbeat가 순서대로 남고, PSS·RSS가 지속적으로 증가하지 않는 것이다. 5분째 heartbeat가 파일에 반영될 여유를 두기 위해 수집 시간은 330초를 권장한다. 플랫폼별 결과는 `docs/qa/evidence-template.md` 형식으로 기록한다.
