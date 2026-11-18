# Google Play 심사 준비 체크리스트

> MAR-36의 Google Play 제출 준비 문서. 검증 기준일: 2026-11-16. 실제 Play Console 저장·제출·출시는 Marco의 별도 승인 전 수행하지 않는다.

## 사용 방법

- 제출 직전 **선택할 release App Bundle과 같은 커밋**에서 다시 확인한다.
- `[확인]`은 저장소나 Play Console 읽기 전용 확인 결과, `[의존]`은 다른 Linear 작업의 산출물, `[Marco]`는 계정에서 직접 판단·입력할 항목이다.
- 계정 정보, 테스터 정보, 연락처, 기기 식별자, 인증 정보는 저장소나 Linear에 남기지 않는다.
- Play Console 질문이 이 문서와 다르면 실제 화면을 우선하고 답을 추측하지 않는다.

## 2026-11-16 현재 판정

| 영역 | 판정 | 근거와 다음 단계 |
|---|---|---|
| 제출 상태 | 차단 | Play Console은 변경사항이 아직 검토 전송되지 않았고 프로덕션이 비활성이라고 표시한다. 추가 제출은 하지 않았다. |
| 프로덕션 접근 | 차단 | 비공개 테스트 `Alpha`에 12명이 참여했지만 Console 표시상 14일 중 4일만 경과했다. 12명이 연속 14일 참여한 뒤 프로덕션 접근을 신청해야 한다. |
| 테스트 release | 확인 | `0.1.0`이 선택된 테스터에게 제공 중이며 2026-11-11 게시로 표시된다. 이름 없는 초안 release가 하나 있으므로 승인 없이 수정·삭제하지 않는다. |
| 앱 식별자·버전 | 확인 | package/namespace는 `com.marcorable.maltto`, `pubspec.yaml`은 `0.1.0+1`, Android `minSdk 33`, `targetSdk 36`이다. Console의 테스트 release 이름과 버전명은 일치하지만 최종 version code와 AAB 소스 커밋은 제출 직전 다시 대조한다. |
| 권한·음성 처리 | 확인 | 앱의 소스 manifest가 직접 선언한 권한은 `RECORD_AUDIO` 하나다. 실제 release 병합 manifest에는 Firebase/Google SDK가 추가한 네트워크·wake lock·광고 ID/Attribution 관련 권한도 있다. Android `SpeechRecognizer`를 온디바이스 모드와 `ko-KR`로 사용하며 오디오 파일 저장 코드는 찾지 못했다. 사용자 대본은 로컬 SQLite에만 저장한다. |
| 로그인·계정·광고·결제 | 확인 | 로그인, 계정 생성·삭제, 광고 SDK/UI, 결제·구독·인앱 상품 구현은 찾지 못했다. App access는 제한된 영역 없음, Ads는 광고 없음이 코드 기준 초안이다. |
| 기본 콘텐츠·권리 | 확인 | 기본 대본, 제3자 기도문·경전·가사·시는 없다. 사용자가 자기 대본을 직접 입력하며 공유·UGC 게시 기능이 없다. |
| 개인정보·Data Safety | 차단 | Firebase Analytics, Crashlytics, App Check가 실행 시 활성화된다. Crashlytics 오류·기기 상태와 설치 식별자, Analytics 자동 이벤트·App Instance ID·광고 ID, App Check의 Play Integrity 토큰 등 최종 SDK 데이터 처리를 MAR-35에서 감사하고 Privacy Policy 및 Data Safety 답변을 확정해야 한다. `수집하지 않음`으로 답하면 안 된다. |
| 스토어 문구·URL | 의존 | 제목·간단한 설명·전체 설명·지원 경로는 MAR-34, 공개 Privacy Policy URL은 MAR-35 소유다. 이 작업에서 중복 작성하지 않는다. |
| 그래픽 자산 | 확인/의존 | MAR-52의 Android 홍보 스크린샷과 검증 자동화가 있다. Play listing은 최소 2장, JPEG 또는 알파 없는 24-bit PNG를 요구한다. feature graphic 1024×500과 앱 아이콘의 Console 등록 상태는 최종 화면에서 확인한다. |
| App content | 미확인 | Privacy policy, Ads, App access, Target audience/content, Content rating, Data Safety의 실제 저장 상태를 Console에서 다시 확인해야 한다. 현재 브라우저 상태만으로 완료 여부를 확정하지 않는다. |

## 프로덕션 접근 신청 준비

Google은 2023-11-13 이후 만든 개인 개발자 계정에 12명 이상의 테스터가 **연속 14일** 비공개 테스트에 참여하도록 요구한다. Console이 요건 충족을 표시한 뒤 다음 답변을 실제 테스트 기록에 근거해 작성한다.

- [ ] [Marco] 12명 이상이 연속 14일 참여했는지 Dashboard에서 확인
- [ ] [Marco] 테스터 모집 방식과 난이도 기록
- [ ] [Marco] 테스터가 사용한 기능과 실제 사용자가 쓸 방식과의 차이 기록
- [ ] [Marco] 받은 피드백과 수집 방법 기록
- [ ] [Marco] 피드백을 반영해 바꾼 점 기록; 변경이 없으면 근거를 사실대로 설명
- [ ] [Marco] 안정성·정책·기능 검증으로 프로덕션 준비를 판단한 근거 기록
- [ ] [Marco] 대상 사용자, 앱 가치, 첫해 예상 설치 범위를 실제 질문에 맞춰 입력

테스터의 이름, 이메일, 기기 정보나 원문 피드백은 이 문서에 기록하지 않는다.

## App content 감사

- [ ] [의존: MAR-35] 전 세계에서 로그인 없이 열리는 HTTPS Privacy Policy URL
- [ ] [의존: MAR-35] 앱 내부에서 Privacy Policy를 여는 경로와 최종 문구
- [ ] [의존: MAR-35] Analytics·Crashlytics·App Check 및 전이 SDK를 포함한 Data Safety 답변
- [ ] [Marco] Ads: 광고 없음으로 저장 전 최종 AAB 의존성 재확인
- [ ] [의존: MAR-35] release 병합 manifest의 `AD_ID`·Ad Services 권한과 Analytics 광고 ID 수집 설정을 감사하고 Play Console의 Advertising ID 선언을 실제 사용에 맞게 완료
- [ ] [Marco] App access: 로그인이나 제한 영역 없음; 별도 자격 증명 미입력
- [ ] [Marco] Target audience and content: 실제 대상 연령을 결정하고 어린이 대상 여부를 일관되게 답변
- [ ] [Marco] Content rating 설문을 실제 기능과 대조해 완료하고 등급 확인
- [ ] [Marco] 기타 `Needs attention` 항목이 0개인지 확인

## Main store listing·release 감사

- [ ] [의존: MAR-34] 앱 이름, 간단한 설명, 전체 설명 확정
- [ ] [의존: MAR-34/35] 지원 및 개인정보 URL을 실제 공개 환경에서 확인
- [ ] [MAR-52] 전화 스크린샷 최소 2장, 알파 없는 PNG/JPEG 및 화면·문구 최신성 확인
- [ ] [Marco] 앱 아이콘, 1024×500 feature graphic, 스크린샷과 각 대체 텍스트 확인
- [ ] [Marco] 카테고리, 연락 경로, 국가/지역, 가격을 실제 Console에서 확인
- [ ] [Marco] release AAB의 package, version name/code, target API, 서명, 소스 커밋 대조
- [x] [확인] `processReleaseMainManifest` 결과에 Firebase/Google SDK가 `INTERNET`, `ACCESS_NETWORK_STATE`, `WAKE_LOCK`, `AD_ID`, Ad Services 관련 권한을 병합함
- [ ] [Marco] 자동 사전 검토와 오류·경고 확인; 오류는 제출 전 모두 해소
- [ ] [Marco] 이름 없는 초안 release의 생성 목적을 확인하고 유지·완성·폐기 중 하나를 별도 승인 후 선택

## Marco의 Google Play Console 단계

이 순서는 실행 준비용이다. 저장, 프로덕션 접근 신청, 검토 전송, 출시는 각각 외부 변경이므로 실행 전에 승인한다.

1. 비공개 테스트 참여 인원이 연속 14일을 충족할 때까지 `Alpha` 상태와 이탈 여부를 확인한다.
2. MAR-34·35·52 산출물이 최종 release UI 및 SDK 동작과 일치하는지 확인한다.
3. **Policy and programs > App content**에서 모든 필수 선언과 Data Safety를 완료한다.
4. **Store presence > Main store listing**에서 문구, 아이콘, feature graphic, 스크린샷, URL을 확인한다.
5. Dashboard에서 프로덕션 접근 신청 질문을 실제 테스트 기록으로 작성한다.
6. 접근 승인 후 최종 AAB와 release notes를 준비하고 사전 검토 오류를 해소한다.
7. **Publishing overview**에서 전송 대상 변경만 포함됐는지 확인한다.
8. `Send changes for review`, 프로덕션 rollout 또는 managed publishing 변경은 Marco의 명시적 승인 뒤 실행한다.

## 공식 Google 출처

모두 2026-11-16에 확인했다.

- [App testing requirements for new personal developer accounts](https://support.google.com/googleplay/android-developer/answer/14151465): 12명·연속 14일과 프로덕션 접근 신청 질문
- [Prepare your app for review](https://support.google.com/googleplay/android-developer/answer/9859455): App content 필수 선언과 Privacy Policy 요건
- [Prepare and roll out a release](https://support.google.com/googleplay/android-developer/answer/9859348): release 준비, 미처리 release, 검토 전송과 rollout 흐름
- [Add preview assets to showcase your app](https://support.google.com/googleplay/android-developer/answer/9866151): 스크린샷·feature graphic 형식과 크기
- [Prepare for Google Play's data disclosure requirements](https://firebase.google.com/docs/android/play-data-disclosure): Firebase SDK별 자동·조건부 수집 항목
