fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

### screenshots_all

```sh
[bundle exec] fastlane screenshots_all
```

iOS와 Android 스토어 스크린샷을 모두 생성하고 검증합니다.

### validate_store_assets

```sh
[bundle exec] fastlane validate_store_assets
```

생성된 양 플랫폼 스토어 에셋 규격만 검증합니다.

### compose_store_promotional

```sh
[bundle exec] fastlane compose_store_promotional
```

원본 캡처에서 홍보용 스크린샷과 contact sheet를 재생성합니다.

----


## iOS

### ios screenshots

```sh
[bundle exec] fastlane ios screenshots
```

iPhone 6.9형과 iPad 13형 기본·큰 글씨 스크린샷을 생성합니다.

----


## Android

### android internal

```sh
[bundle exec] fastlane android internal
```

서명된 AAB를 Google Play 내부 테스트 트랙에 배포합니다.

### android screenshots

```sh
[bundle exec] fastlane android screenshots
```

Android phone 기본·큰 글씨 스크린샷을 생성합니다.

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
