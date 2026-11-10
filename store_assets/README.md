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

기본 iOS 기기는 설치된 최신 `iPhone 18 Pro Max`, Android AVD는
`Medium_Phone_API_36`이다. 다른 기기를 사용할 때는 각각 `IOS_DEVICE_ID`,
`ANDROID_DEVICE_ID`를 지정한다. 캡처는 임시 디렉터리에서 완성된 PNG 네 장을
검증한 뒤 기존 파일을 교체하므로, 중간 실패가 기존 산출물을 지우지 않는다.

## 검증

```bash
bundle exec fastlane validate_store_assets
```

검증은 네 개 시나리오의 존재, Pillow 전체 디코드 기반 PNG 무결성, iOS 6.9형 허용 크기, Android
1080×1920, 알파 채널 부재, Fastlane 메타데이터 구조, 고정 픽스처 해시와
개인정보·시크릿 패턴 부재를 확인한다.

## 원칙

- 모든 문구는 이 프로젝트를 위해 직접 작성한 더미 문장이다.
- 실제 사용자 대본, 개인정보, 제3자 저작물과 계정 시크릿을 넣지 않는다.
- `qa-large-text`는 접근성 검증용이며 기본 스토어 업로드 세트와 분리한다.
- 실제 업로드는 이 자동화에 포함하지 않는다.

## 제출 전 확인

- 현재 Xcode 타깃은 iPhone과 iPad를 함께 지원한다. iPad 지원을 유지하면 App
  Store 제출 전에 13형 iPad 스크린샷도 필요하다. MAR-33의 확정 범위는 iPhone
  필수 크기이므로 이 자동화는 iPad 산출물을 만들지 않는다.
- 스토어 문구와 지원·개인정보처리방침 URL은 MAR-34에서 확정한다.
- 실제 App Store Connect·Google Play Console 업로드는 별도 출시 작업에서만 한다.
