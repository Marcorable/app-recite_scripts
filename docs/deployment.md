# 빌드 검증과 배포 서명

## 시크릿 없는 검증

Pull Request와 `develop` CI는 배포 자격 증명을 사용하지 않는다.

- `flutter analyze`, 순수 Dart 테스트, Flutter 테스트
- Android Debug APK 빌드
- iOS Simulator Debug 앱 빌드(`--no-codesign`)
- 커밋 금지 파일, 대표적인 시크릿 패턴, 제품 경로의 제3자 콘텐츠 표지 검사

이 단계는 같은 커밋이 양 플랫폼에서 컴파일되고 테스트되는지 확인한다. 시뮬레이터 앱은 서명이 필요 없고 실제 기기에 배포하지 않는다.

## 실제 배포

TestFlight와 스토어 배포는 별도의 출시 Issue와 보호된 배포 workflow에서만 수행한다. 저장소에는 인증서, provisioning profile, App Store Connect API 키, Android keystore를 넣지 않는다. 필요한 값은 GitHub Actions Secrets 또는 배포 머신의 레포 밖 keychain/credential store에서 주입하며 로그에 출력하지 않는다.

배포 단계는 다음 조건을 모두 확인한 뒤 추가한다.

1. Marco가 배포 실행과 대상 버전을 승인한다.
2. 보호된 environment와 최소 권한을 설정한다.
3. iOS 배포 서명과 Android release signing을 실행 시점에만 구성한다.
4. 서명 전과 동일한 소스 커밋에서 release artifact를 만든다.
5. 업로드 결과와 artifact 식별자만 기록하고 자격 증명은 즉시 정리한다.

현재 Walking Skeleton에는 실제 배포 workflow를 포함하지 않는다.

## Xcode Cloud 버전 관리

앱 버전과 빌드 번호는 서로 다른 원본에서 관리한다.

| 값 | 단일 원본 | 예시 |
|---|---|---|
| 앱 버전 | `pubspec.yaml`의 `version`에서 `+` 앞부분 | `1.0.0` |
| 로컬 빌드 번호 | `pubspec.yaml`의 `version`에서 `+` 뒷부분 | `1` |
| Xcode Cloud 빌드 번호 | Xcode Cloud의 `CI_BUILD_NUMBER` | `42` |

`ios/ci_scripts/ci_post_clone.sh`는 Flutter 3.47.7을 설치하고 iOS 빌드 설정을 생성한다. Xcode Cloud에서는 자동 증가하는 `CI_BUILD_NUMBER`를 Flutter의 `--build-number`에 전달하므로 TestFlight의 빌드 번호와 Xcode Cloud 빌드를 같은 숫자로 추적할 수 있다. 로컬에서 실행할 때는 `pubspec.yaml`의 빌드 번호를 사용한다.

사용자에게 보이는 앱 버전을 올릴 때만 `pubspec.yaml`의 `version`을 변경한다. Xcode Cloud의 빌드 번호를 소스에 커밋하거나 수동으로 증가시키지 않는다.
