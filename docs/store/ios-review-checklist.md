# iOS App Store 심사 준비 체크리스트

> MAR-36의 iOS 선행 작업. 검증 기준일: 2026-11-10. 실제 App Store Connect 입력, 빌드 업로드, TestFlight 배포, 심사 제출은 이 문서의 범위가 아니다.

## 사용 방법

- 제출 직전 `origin/develop`이 아니라 **선택할 release 빌드와 같은 커밋**에서 다시 확인한다.
- `[확인]`은 저장소에서 확인된 사실, `[의존]`은 다른 Linear 작업의 산출물, `[Marco]`는 App Store Connect 계정에서 직접 확인하거나 입력할 항목이다.
- Apple 화면이나 질문이 이 문서와 다르면 Apple 화면을 우선하고, 답을 추측하지 말고 출처와 실제 화면을 MAR-36에 기록한다.
- 연락처, 계정 정보, 기기 식별자, 인증 정보는 저장소나 Linear 코멘트에 남기지 않는다.

## 현재 판정

| 영역 | 판정 | 근거와 다음 단계 |
|---|---|---|
| 기준선 | 확인 | 작업 중 새로 병합된 PR #95·#98을 반영해 HEAD를 `origin/develop`의 `c31669e`로 fast-forward했다. 제출 빌드 선택 시 다시 대조한다. |
| 앱 이름 | 확인 | 표시 이름은 `말또` (`ios/Runner/Info.plist`). 스토어 이름·부제·설명·키워드는 MAR-34가 Backlog이므로 이 작업에서 확정하지 않는다. |
| 버전·빌드 | 확인 | `pubspec.yaml`은 `1.0.0+1`; Xcode는 `FLUTTER_BUILD_NAME`/`FLUTTER_BUILD_NUMBER`를 사용한다. Xcode Cloud 빌드는 `CI_BUILD_NUMBER`를 사용한다 (`docs/deployment.md`). |
| 번들 ID | 확인 | `com.marcorable.maltto` (`ios/Runner.xcodeproj/project.pbxproj`). App Store Connect 앱 레코드와 일치 여부는 Marco가 확인한다. |
| 지원 기기·OS | 확인 | iOS deployment target 26.0, iPhone·iPad 지원(`TARGETED_DEVICE_FAMILY = "1,2"`). |
| 권한 | 확인 | 마이크와 음성 인식 purpose string이 한국어로 있으며, 사용 시작 전에 두 권한을 확인·요청한다. 거부 시 설정 이동 안내가 있다. |
| 음성 처리 | 확인 | iOS 구현은 `SpeechAnalyzer`/`SpeechTranscriber`와 `AVAudioEngine`을 사용하고 `ko-KR` 지원·Speech asset 상태를 확인한다. 오디오 버퍼는 분석기에 전달되며 파일 저장 코드는 찾지 못했다. 백그라운드 전환·종료 시 세션과 오디오 세션을 중단한다. |
| 기본 콘텐츠 | 확인 | 제품 코드와 고정 스토어 픽스처에는 사용자가 직접 입력하는 흐름만 있다. 기본 탑재 대본이나 제3자 기도문·경전·가사·시는 없다. |
| 로그인·계정 | 확인 | 로그인, 계정 생성·삭제, 데모 계정 요구 흐름이 없다. Review Information에서 `Sign-in required`를 켜지 않는다. |
| 광고·추적·결제 | 확인 | 제품 코드와 의존성에서 광고 UI, ATT 요청, 인앱 구매, 구독, 결제 흐름을 찾지 못했다. 제출 빌드의 의존성 감사에서 다시 확인한다. |
| 개인정보 | 차단 | Firebase Core가 앱 시작 시 초기화되고 iOS Firebase SDK가 링크된다. 수집 API 사용은 찾지 못했지만 Apple은 제3자 SDK의 처리까지 포함하라고 요구한다. MAR-35의 SDK/네트워크 감사와 공개 Privacy Policy URL이 끝나기 전 `No, we do not collect data`를 확정하지 않는다. |
| 콘텐츠 권리 | 제안 | 앱과 스토어 자산이 제3자 콘텐츠를 제공·접근하지 않으므로 App Information의 Content Rights는 `No`가 코드 기준 초안이다. 최종 바이너리와 MAR-34 문구에 외부 콘텐츠가 없는지 확인한 뒤 Marco가 저장한다. |
| 연령 등급 | 제안 | 사용자 생성 콘텐츠 공유·웹 접근·광고·도박·성인 콘텐츠 기능이 없으므로 관련 질문은 `None/No`가 코드 기준 초안이다. Apple이 계산한 등급을 사용하고 `Made for Kids` 또는 상향 override는 적용하지 않는 안이다. Marco가 실제 설문 문구와 최종 빌드 대조 후 저장한다. |
| 수출 규정 | 결정 필요 | Firebase가 OS 네트워크 암호화를 사용할 수 있고 `ITSAppUsesNonExemptEncryption` 선언은 없다. 아래 단일 결정 게이트를 통과하기 전 답변이나 plist 값을 확정하지 않는다. |
| 지원·마케팅·Privacy URL | 의존 | Support URL과 스토어 문구는 MAR-34, Privacy Policy URL과 App Privacy 답변은 MAR-35 산출물이다. Marketing URL은 Apple상 선택 항목이며 MAR-34에서 사용할지 결정한다. URL은 HTTPS로 실제 공개 접근이 가능해야 한다. |
| 스크린샷 | 확인 | MAR-52 PR #95가 `develop`에 병합됐다. iPhone 1320×2868, iPad 2064×2752 홍보용 PNG와 알파 채널·픽스처·민감정보 검증 자동화가 있다. 제출 빌드와 화면이 같은지는 release 선택 뒤 다시 확인한다. |

## 단일 결정 게이트 — 수출 규정/암호화

공식 문서는 OS의 암호 기능을 사용하는 앱도 App Store Connect에서 수출 규정 판단을 하라고 요구한다. 현재 앱은 자체 암호 알고리즘을 구현하지 않지만 Firebase Core를 초기화한다.

**Marco 결정 1개:** MAR-35가 최종 release 빌드의 Firebase/네트워크 사용과 포함 SDK를 감사한 뒤, App Store Connect의 실제 암호화 질문 흐름에서 “면제되는 표준/OS 암호화만 사용”으로 답하고 `ITSAppUsesNonExemptEncryption = NO`를 코드에 추가할지, 별도 수출 규정 문서가 필요한 경로로 갈지 결정한다.

에이전트는 법률 판단을 대신하지 않는다. 결정 전에는 plist 변경, 설문 저장, 문서 업로드를 하지 않는다.

## 제출 메타데이터 감사

### App Information

- [ ] [Marco] 앱 레코드의 Bundle ID가 `com.marcorable.maltto`와 정확히 일치
- [ ] [의존: MAR-34] 이름·부제·기본 언어·카테고리·스토어 문구 확정
- [ ] [Marco] SKU 입력(공개 저장소에는 기록하지 않음)
- [ ] [Marco] Content Rights를 최종 바이너리와 문구에 대조해 저장
- [ ] [Marco] 연령 등급 설문을 실제 App Store Connect 문구 기준으로 완료; Unrated 상태가 아님을 확인
- [ ] [Marco] 한국 배포 및 조직 계정에 표시되는 추가 가용성 정보를 실제 화면 기준으로 완료

### iOS 버전 정보

- [x] [MAR-52] 스크린샷 PR #95 병합 및 재생성·검증 자동화 확보
- [ ] [Marco] 최종 release 커밋과 스크린샷 UI 일치 확인
- [ ] [Marco] App Store Connect가 iPhone 1320×2868 세트를 올바른 슬롯에서 수락하는지 확인
  - Apple 문서 요약은 Dynamic Island 중형 최소 1장을 요구하지만 같은 규격표는 1320×2868 대형을 허용하고 중형 미제공 시 대형을 축소한다고 설명한다.
  - 실제 슬롯에서 거부되면 MAR-36에서 임의 리사이즈하지 말고 MAR-52 후속으로 1179×2556 또는 1206×2622 원본을 생성한다.
- [ ] [Marco] iPad 지원 앱이므로 13형 2064×2752 세트 수락 확인
- [ ] [의존: MAR-34] Description, Keywords, Support URL 확정; Promotional Text와 Marketing URL은 선택 여부 확정
- [ ] [Marco] Version `1.0.0`, Copyright, release 방식 입력
- [ ] [Marco] 업로드된 빌드 번호와 Xcode Cloud `CI_BUILD_NUMBER`, 소스 커밋을 대조
- [ ] [Marco] 첫 버전이므로 `What's New` 필드가 요구되지 않는지 실제 화면에서 확인

### App Review Information

- [ ] [Marco] 검토 담당자의 이름·이메일·국제 형식 전화번호 입력(저장소에 복사하지 않음)
- [ ] [Marco] `Sign-in required` 끔; 사용자명·비밀번호 미입력
- [ ] [Marco] `docs/store/review-notes.md`의 iOS 초안을 최종 빌드에서 재현한 뒤 Notes에 복사
- [ ] [Marco] Notes가 Apple의 4,000바이트 제한 안인지 입력 화면에서 확인

### Privacy·규정

- [ ] [의존: MAR-35] 공개 Privacy Policy URL 준비 및 외부 비로그인 환경에서 열림 확인
- [ ] [의존: MAR-35] Firebase를 포함한 제3자 SDK 감사 후 App Privacy 답변 확정·Publish
- [ ] [확인] 로그인·계정·광고·추적·인앱 구매·구독 없음이 최종 코드와 일치
- [ ] [Marco 결정] 수출 규정/암호화 단일 게이트 완료
- [ ] [Marco] App Store Connect에 추가 계약·규정 설문이 표시되면 실제 문구와 근거를 MAR-36에 기록하고 답변

## Marco의 App Store Connect 단계

이 순서는 입력 준비용이며 이 작업에서는 실행하지 않는다.

1. MAR-34·MAR-35 완료와 MAR-52 산출물이 최종 release UI와 일치하는지 확인한다.
2. 제출하려는 release 빌드의 버전, 빌드 번호, 번들 ID, 소스 커밋을 이 체크리스트와 대조한다.
3. App Information에서 기본 언어·카테고리·Content Rights·연령 등급 및 표시되는 지역별 질문을 완료한다.
4. App Privacy에서 MAR-35가 확정한 Privacy Policy URL과 데이터 처리 답변을 입력하고 Publish한다.
5. iOS `1.0.0` 버전에 MAR-34 메타데이터와 MAR-52 스크린샷을 입력한다. iPhone/iPad 슬롯 수락 여부를 확인한다.
6. 빌드를 선택하고 수출 규정 질문을 단일 결정 결과대로 완료한다.
7. App Review Information에 개인 연락처를 직접 입력하고 로그인 불필요로 설정한 뒤 심사 노트 초안을 붙여 넣는다.
8. 앱을 새로 설치한 실제 기기에서 심사 노트 순서대로 권한 허용, 대본 생성, 낭독 시작·완료, 종료 후 마이크 비활성화를 재현한다.
9. 모든 필수 항목과 선택 빌드를 다시 확인한다. `Add for Review`와 `Submit for Review`는 별도 명시적 승인과 최종 제출 작업에서만 수행한다.

## 공식 Apple 출처

모두 2026-11-10에 확인했다.

- [Required, localizable, and editable properties](https://developer.apple.com/help/app-store-connect/reference/app-information/required-localizable-and-editable-properties): 앱·버전별 필수 속성
- [Platform version information](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information/): Description, Keywords, URL, Review Information과 제한
- [Screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications): 필수 기기군, 허용 크기, 장수, 알파 채널 제한
- [Manage app privacy](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/): Privacy Policy URL, 제3자 SDK를 포함한 데이터 처리 답변
- [Set an app age rating](https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating/): 필수 설문, Unrated 제한, iOS 26+ 등급
- [Overview of export compliance](https://developer.apple.com/help/app-store-connect/manage-app-information/overview-of-export-compliance): OS 암호 기능을 포함한 수출 규정 판단
- [Submit an app](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-app): 필수 메타데이터·빌드 선택, Add for Review와 Submit for Review의 구분
- [App Review](https://developer.apple.com/app-store/review/): 권한 purpose string과 특별 설정·재현 정보 제공 원칙
