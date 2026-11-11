# 빌드 검증과 배포 서명

## 시크릿 없는 검증

Pull Request와 `develop` CI는 배포 자격 증명을 사용하지 않는다.

- `flutter analyze`, 순수 Dart 테스트, Flutter 테스트
- Android Debug APK 빌드
- iOS Simulator Debug 앱 빌드(`--no-codesign`)
- 커밋 금지 파일, 대표적인 시크릿 패턴, 제품 경로의 제3자 콘텐츠 표지 검사

이 단계는 같은 커밋이 양 플랫폼에서 컴파일되고 테스트되는지 확인한다. 시뮬레이터 앱은 서명이 필요 없고 실제 기기에 배포하지 않는다.

## 실제 배포

TestFlight와 스토어 배포는 `release` 브랜치와 보호된 배포 workflow에서만 수행한다. iOS는 Xcode Cloud가 TestFlight 내부 테스트 빌드를 업로드하고, Android는 GitHub Actions가 Google Play 내부 테스트 트랙에 AAB를 업로드한다. 저장소에는 인증서, provisioning profile, App Store Connect API 키, Android keystore를 넣지 않는다. 필요한 값은 Xcode Cloud 또는 GitHub Actions의 보호된 시크릿 저장소에서 주입하며 로그에 출력하지 않는다.

배포 단계는 다음 조건을 모두 확인한 뒤 추가한다.

1. Marco가 배포 실행과 대상 버전을 승인한다.
2. 보호된 environment와 최소 권한을 설정한다.
3. iOS 배포 서명과 Android release signing을 실행 시점에만 구성한다.
4. 서명 전과 동일한 소스 커밋에서 release artifact를 만든다.
5. 업로드 결과와 artifact 식별자만 기록하고 자격 증명은 즉시 정리한다.

## Xcode Cloud 버전 관리

앱 버전과 빌드 번호는 서로 다른 원본에서 관리한다.

| 값 | 단일 원본 | 예시 |
|---|---|---|
| 앱 버전 | `pubspec.yaml`의 `version`에서 `+` 앞부분 | `0.1.0` |
| 로컬 빌드 번호 | `pubspec.yaml`의 `version`에서 `+` 뒷부분 | `1` |
| Xcode Cloud 빌드 번호 | Xcode Cloud의 `CI_BUILD_NUMBER` | `42` |

`ios/ci_scripts/ci_post_clone.sh`는 Flutter 3.47.7을 설치하고 iOS 빌드 설정을 생성한다. Xcode Cloud에서는 자동 증가하는 `CI_BUILD_NUMBER`를 Flutter의 `--build-number`에 전달하므로 TestFlight의 빌드 번호와 Xcode Cloud 빌드를 같은 숫자로 추적할 수 있다. 로컬에서 실행할 때는 `pubspec.yaml`의 빌드 번호를 사용한다.

사용자에게 보이는 앱 버전을 올릴 때만 `pubspec.yaml`의 `version`을 변경한다. Xcode Cloud의 빌드 번호를 소스에 커밋하거나 수동으로 증가시키지 않는다.

Xcode Cloud 워크플로의 시작 조건은 `release` 브랜치 변경으로 제한한다. 워크플로에는 Archive 액션과 TestFlight 내부 테스트 배포 후처리를 설정한다. `develop` 병합은 GitHub Actions CI만 실행하며 App Store Connect 빌드 업로드를 시작하지 않는다.

## Android CI/CD

Pull Request와 `develop` push에서는 기존 `Flutter CI`가 정책 검사, 정적 분석, 테스트와 Android Debug APK 빌드만 수행한다. `release` push에서는 같은 검증을 다시 수행하고 성공하면 `Google Play Internal deployment` 작업이 이어서 실행된다.

```text
작업 브랜치 → develop: CI만 실행
develop → release: CI 통과 후 Play Internal CD 실행
release → main: 테스트 완료 뒤 정식 출시 후보 확정
```

배포 작업은 다음 순서로 진행한다.

1. `google-play-internal` GitHub Environment에서 배포 시크릿을 주입한다.
2. 임시 upload keystore와 `android/key.properties`를 생성한다.
3. 서명된 release AAB를 빌드한다.
4. Fastlane `supply`로 Google Play `internal` 트랙에 업로드한다.
5. 성공 여부와 관계없이 임시 서명 파일을 삭제한다.

### Android 버전 관리

| 값 | 단일 원본 | 예시 |
|---|---|---|
| 앱 버전(`versionName`) | `pubspec.yaml`의 `version`에서 `+` 앞부분 | `0.1.0` |
| 로컬 빌드 번호 | `pubspec.yaml`의 `version`에서 `+` 뒷부분 | `1` |
| Play 빌드 번호(`versionCode`) | `100000 + GITHUB_RUN_NUMBER × 10 + GITHUB_RUN_ATTEMPT` | `100421` |

재실행에도 이미 사용한 `versionCode`와 충돌하지 않도록 실행 번호와 재시도 번호를 함께 사용한다. GitHub Actions에서 계산한 빌드 번호는 `flutter build appbundle --build-number`로 전달하며 소스에는 커밋하지 않는다.

### GitHub Environment와 시크릿

Repository Settings의 Environments에 `google-play-internal`을 만들고 배포 브랜치를 `release`로 제한한다. 다음 Environment secret을 등록한다.

| 이름 | 값 |
|---|---|
| `ANDROID_UPLOAD_KEYSTORE_BASE64` | Android upload keystore를 Base64로 인코딩한 문자열 |
| `ANDROID_UPLOAD_STORE_PASSWORD` | keystore 비밀번호 |
| `ANDROID_UPLOAD_KEY_ALIAS` | upload key alias |
| `ANDROID_UPLOAD_KEY_PASSWORD` | upload key 비밀번호 |
| `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` | Play Console 권한을 부여한 서비스 계정 JSON 전체 내용 |

서비스 계정에는 대상 앱의 내부 테스트 릴리스를 생성하는 데 필요한 최소 권한만 부여한다. Play Developer API와 앱 등록이 완료되고 최초 AAB가 Play Console에 등록된 뒤 자동 배포를 활성화한다.
