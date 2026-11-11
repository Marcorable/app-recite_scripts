# Firebase Debug 수집 및 App Check 검증

Analytics와 Crashlytics의 실제 수집 경로를 사용자 데이터 없이 확인하는 절차다.

## App Check 구성

- Debug 빌드: Android와 Apple 모두 Debug provider
- Release 빌드: Android는 Play Integrity, Apple은 App Attest
- App Check 활성화 실패는 앱 실행과 Analytics/Crashlytics 초기화를 막지 않는다.
- Debug token은 인증 정보다. 로그나 문서에 붙여 넣거나 저장소에 커밋하지 않는다.

Firebase Console의 **App Check > Apps**에서 Android 앱에는 Play Integrity를,
iOS 앱에는 App Attest를 등록한다. 현재 앱이 사용하는 Analytics와 Crashlytics는
App Check enforcement 지원 대상이 아니다. 향후 Authentication, Firestore, Storage 등
지원 제품을 추가할 때는 검증된 요청 비율을 먼저 관찰한 뒤 enforcement를 켠다.

## 검증 데이터

- Analytics event: `debug_verification`
- Crashlytics non-fatal: `StateError('firebase_debug_verification')`
- 이벤트 파라미터, 사용자 속성, 대본, 음성, 전사문은 전송하지 않는다.
- 앱 오류는 원본 메시지 대신 고정 오류명과 예외 타입, 스택만 전송해 사용자 입력이 오류 문구에 섞이지 않게 한다.
- 검증 데이터는 Debug 빌드에 `FIREBASE_DEBUG_VERIFICATION=true`를 명시한 경우에만 생성된다.

## Android

```sh
adb shell setprop debug.firebase.analytics.app com.marcorable.maltto
flutter run -d <device-id> \
  --debug \
  --dart-define=FIREBASE_DEBUG_VERIFICATION=true \
  --dart-define=FIREBASE_APP_CHECK_DEBUG_VERIFICATION=true
```

첫 실행의 Logcat에서 `DebugAppCheckProvider`가 출력한 debug token을 복사해
Firebase Console의 Android 앱 **Manage debug tokens**에 등록한 뒤 앱을 다시 실행한다.
토큰 원문은 터미널 기록이나 Issue/PR에 남기지 않는다. 등록 후 로그에서
`Firebase App Check debug verification succeeded.`를 확인한다.

검증 후 Analytics Debug 모드를 해제한다.

```sh
adb shell setprop debug.firebase.analytics.app .none.
```

## iOS Simulator

```sh
flutter build ios \
  --simulator \
  --debug \
  --dart-define=FIREBASE_DEBUG_VERIFICATION=true \
  --dart-define=FIREBASE_APP_CHECK_DEBUG_VERIFICATION=true
xcrun simctl install <simulator-id> build/ios/iphonesimulator/Runner.app
xcrun simctl launch --terminate-running-process <simulator-id> \
  com.marcorable.maltto \
  -FIRAnalyticsDebugEnabled \
  -FIRDebugEnabled
```

첫 실행의 Xcode/Simulator 로그에서 App Check debug token을 복사해 Firebase
Console의 iOS 앱 **Manage debug tokens**에 등록한 뒤 앱을 다시 실행한다. 토큰
원문은 저장소와 PR에 남기지 않는다. 등록 후 로그에서
`Firebase App Check debug verification succeeded.`를 확인한다.

Crashlytics non-fatal 업로드는 세션 처리 뒤 전송될 수 있으므로 앱을 종료하고 다시 실행한 뒤 Firebase Console도 확인한다.

## iOS 기기 및 Archive

Crashlytics dSYM 업로드 단계는 FlutterFire CLI를 사용한다. 로컬에서 iOS 기기 빌드나 Archive를 만들기 전에 다음 버전을 설치한다. Xcode Cloud에서는 post-clone 스크립트가 같은 버전을 설치한다.

```sh
dart pub global activate flutterfire_cli 1.5.0
```

## 기대 결과

- Analytics DebugView에 `debug_verification`이 표시된다.
- Crashlytics에 `firebase_debug_verification` non-fatal이 표시된다.
- 양 플랫폼 로그에 App Check debug verification 성공 메시지가 표시된다.
- 일반 Debug 실행과 Release 실행에서는 synthetic 검증 데이터가 생성되지 않는다.

## 운영 전 체크리스트

- Firebase Console에 Android Play Integrity provider가 등록되어 있다.
- Google Play Console에 앱이 등록되고 Firebase 프로젝트와 연결되어 있다.
- Play Console에서 사용하는 앱 서명 인증서 지문이 Firebase Android 앱에 등록되어 있다.
- Firebase Console에 iOS App Attest provider가 등록되어 있다.
- Runner의 App Attest entitlement가 `production`으로 설정되어 있다.
- App Store 배포 빌드의 bundle ID가 `com.marcorable.maltto`와 일치한다.
- Debug token은 개발 장비별로 이름을 구분해 등록하고, 노출된 토큰은 즉시 폐기한다.
- 지원 Firebase 제품을 추가하기 전에는 enforcement를 켜지 않는다.
