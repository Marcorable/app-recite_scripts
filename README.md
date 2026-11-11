# 말또

사용자가 직접 입력한 대본을 반복해서 낭독하도록 돕는 Flutter 앱이다. 사용자 텍스트와 음성은 기기 밖으로 보내지 않는다.

## 공개 범위와 저작권

이 저장소는 개발 과정과 결과를 보여주기 위한 공개 포트폴리오다. 별도의
오픈소스 라이선스를 제공하지 않으며, 프로젝트 고유 코드·문서·디자인에는
기본 저작권법에 따른 **All Rights Reserved** 정책이 적용된다.

GitHub 이용약관이 공개 저장소에 허용하는 열람과 포크 범위를 제외하면,
권리자의 별도 허락 없이 프로젝트 고유 저작물을 복제·수정·재배포하거나
제품 또는 서비스에 사용할 수 없다. 저장소에 `LICENSE` 파일을 추가하지
않은 것은 이러한 정책을 유지하기 위한 의도적인 결정이다.

Flutter와 Dart 패키지 등 제3자 구성 요소에는 각 저작권자의 원 라이선스가
별도로 적용된다. 앱의 **정보 → 오픈소스 라이선스** 화면과 Android·iOS
빌드 산출물의 `NOTICES.Z`에서 해당 고지를 확인할 수 있다.

`cupertino_icons`는 앱의 삭제·뒤로 이동·정보 등 Cupertino 아이콘 글꼴을
제공하므로 런타임 의존성으로 유지한다.

## 로컬 검증

Flutter 3.47.7과 Dart 3.13.5를 기준으로 한다.

```bash
flutter pub get
./scripts/check_public_repo.sh
./scripts/test.sh
./scripts/build.sh
```

실행 중인 Android Emulator와 iOS Simulator에서 화면을 확인하고 스크린샷을 저장한다.

```bash
./scripts/screenshot.sh android
./scripts/screenshot.sh ios
```

서명 없는 검증과 실제 배포 절차는 [`docs/deployment.md`](docs/deployment.md)에 분리해 두었다.
