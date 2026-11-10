# Store assets

App Store와 Google Play 제출물을 재생성하기 위한 디렉터리다.

스토어 문구의 Fastlane 호환 구조는 `fastlane/metadata/ios/ko`와
`fastlane/metadata/android/ko-KR`에 정의한다. 문구 자체는 MAR-34에서 Marco가
확정한 뒤 추가하며, 이 작업에는 업로드 lane이나 계정 정보가 없다.

최초 한 번 PNG 무결성·RGB 변환 도구와 Fastlane을 설치한다.

```bash
python3 -m pip install -r tool/store_assets/requirements.txt
bundle install
```

## 캡처

```bash
bundle exec fastlane ios screenshots
bundle exec fastlane android screenshots
bundle exec fastlane screenshots_all
```

기본 iOS 기기는 설치된 최신 `iPhone 18 Pro Max`와 `iPad Pro 13-inch (M5)`,
Android AVD는 `Medium_Phone_API_36`이다. 다른 기기를 사용할 때는
`IOS_IPHONE_DEVICE_ID`, `IOS_IPAD_DEVICE_ID`, `ANDROID_DEVICE_ID`를 지정한다.
기존 `IOS_DEVICE_ID`는 iPhone 기기 지정값으로 계속 사용할 수 있다. 캡처는 임시
디렉터리에서 완성된 PNG 네 장을 검증한 뒤 기존 파일을 교체하므로, 중간 실패가
기존 산출물을 지우지 않는다.

Android는 실기기가 연결돼 있어도 기본적으로 실행 중인 에뮬레이터를 선택하며,
없으면 지정한 AVD를 시작한다. 실기기를 사용하려는 경우에만 `ANDROID_DEVICE_ID`를
명시한다.

전용 캡처 AVD의 데이터 파티션을 초기화해야 할 때만 `ANDROID_WIPE_DATA=true`를
지정한다. 이 옵션은 자동으로 시작하는 `ANDROID_AVD`에만 적용되며 기본값은
`false`다.

## 검증

```bash
bundle exec fastlane validate_store_assets
```

검증은 네 개 시나리오의 존재, Pillow 전체 디코드 기반 PNG 무결성, iPhone
6.9형·iPad 13형 허용 크기, Android 1080×1920, 알파 채널 부재, Fastlane
메타데이터 구조, 고정 픽스처 해시와 개인정보·시크릿 패턴 부재를 확인한다.

## 홍보용 스크린샷

Marco가 승인한 사용 순서 중심 방향은 `store_assets/promotional/template.json`에
카피·색·대상 규격과 함께 정의한다. 원본 화면을 다시 캡처한 뒤 다음 명령으로
세 플랫폼 결과물 12장, 홍보용 contact sheet 3장과 기본/200% 큰 글씨 비교용 QA
contact sheet 3장을 재생성한다.

```bash
bundle exec fastlane compose_store_promotional
```

4장 순서는 대본 목록 → 직접 입력 → 반복 설정 → 낭독 진행이다. 결과물은 원본과
동일한 iPhone 6.9형 `1320×2868`, iPad 13형 `2064×2752`, Android phone
`1080×1920`의 24-bit RGB PNG다. 카피 영역은 짧은 단계 안내만 제공하며 실제 앱
화면을 중심으로 유지한다. Google Play 권고에 맞게 카피는 전체 높이의 20% 안에
배치한다.

현재 Apple 문서에서 iPhone 제출 필수 대표 크기는 Dynamic Island medium display로
표현된다. 이 작업의 6.9형 출력은 공식 허용 규격이지만 실제 제출 직전에는
App Store Connect에서 medium display 세트 필요 여부를 다시 확인한다.

큰 글씨 원본은 `qa-large-text`에 계속 보관하고 홍보 기본 세트와 분리한다. 기본
세트의 네 기능 화면과 큰 글씨의 동일 화면을 검토해 핵심 정보·조작이 유지되는지
확인하며, 큰 글씨 화면을 기본 앱 모습처럼 홍보하지 않는다.

공식 규격 근거:

- Apple App Store Connect Screenshot specifications:
  https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/
- Google Play Console preview assets:
  https://support.google.com/googleplay/android-developer/answer/9866151

## 원칙

- 모든 문구는 이 프로젝트를 위해 직접 작성한 더미 문장이다.
- 실제 사용자 대본, 개인정보, 제3자 저작물과 계정 시크릿을 넣지 않는다.
- `qa-large-text`는 접근성 검증용이며 기본 스토어 업로드 세트와 분리한다.
- 실제 업로드는 이 자동화에 포함하지 않는다.

## 제출 전 확인

- Xcode 타깃은 iPhone과 iPad를 함께 지원하며, App Store 제출용 iPad 13형
  기본 화면과 접근성 검토용 200% 큰 글씨 화면을 함께 생성한다.
- 스토어 문구와 지원·개인정보처리방침 URL은 MAR-34에서 확정한다.
- 실제 App Store Connect·Google Play Console 업로드는 별도 출시 작업에서만 한다.
