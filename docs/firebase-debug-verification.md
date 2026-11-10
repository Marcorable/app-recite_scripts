# Firebase Debug 수집 검증

Analytics와 Crashlytics의 실제 수집 경로를 사용자 데이터 없이 확인하는 절차다.

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
  --dart-define=FIREBASE_DEBUG_VERIFICATION=true
```

검증 후 Analytics Debug 모드를 해제한다.

```sh
adb shell setprop debug.firebase.analytics.app .none.
```

## iOS Simulator

```sh
flutter build ios \
  --simulator \
  --debug \
  --dart-define=FIREBASE_DEBUG_VERIFICATION=true
xcrun simctl install <simulator-id> build/ios/iphonesimulator/Runner.app
xcrun simctl launch --terminate-running-process <simulator-id> \
  com.marcorable.maltto \
  -FIRAnalyticsDebugEnabled \
  -FIRDebugEnabled
```

Crashlytics non-fatal 업로드는 세션 처리 뒤 전송될 수 있으므로 앱을 종료하고 다시 실행한 뒤 Firebase Console도 확인한다.

## 기대 결과

- Analytics DebugView에 `debug_verification`이 표시된다.
- Crashlytics에 `firebase_debug_verification` non-fatal이 표시된다.
- 일반 Debug 실행과 Release 실행에서는 synthetic 검증 데이터가 생성되지 않는다.
