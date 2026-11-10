# MAR-36 iOS 심사 준비 기록

## 기준

- 작업일: 2026-11-10
- 기준 커밋: `origin/develop` `c31669e68613eb317fcffce4fad39a1d21996f01`
- 범위: App Store 심사 준비 문서와 코드·정책 교차 감사
- 제외: App Store Connect 조작, 빌드 업로드, TestFlight 배포, 심사 제출, MAR-34·35·52 산출물의 대체 구현

## 사용한 도구

- Orca Linear CLI로 MAR-36, MAR-34, MAR-35, MAR-52의 상태·설명·연결 PR 확인
- Git과 `rg`로 현재 앱의 권한, STT, 저장, 네트워크·SDK, 버전, 번들 ID, 로그인·광고·결제 구현 감사
- Apple Developer의 App Store Connect Help와 App Review 공식 문서로 2026년 제출 요구사항 확인
- `sips`로 현재 iPhone·iPad 스크린샷 픽셀 크기 확인

## 확인된 것

- HEAD와 최신 `origin/develop`이 일치했다.
- 앱은 iOS 26+, iPhone·iPad를 지원하고 표시 이름 `말또`, 번들 ID `com.marcorable.maltto`, 버전 `1.0.0+1`을 사용한다.
- 마이크·음성 인식 purpose string, 권한 확인, `ko-KR`와 온디바이스 Speech asset 준비, 세션 정리 구현이 있다.
- 음성 파일 저장, 기본 탑재 대본, 로그인·계정, 광고·ATT, 결제·구독 구현은 제품 코드에서 찾지 못했다.
- MAR-52 PR #95가 `develop`에 병합됐고, 제출용 홍보 자산은 iPhone 1320×2868, iPad 2064×2752이며 재생성·검증 자동화가 있다.

## 안 된 것과 블로커

- MAR-34와 MAR-35는 Backlog다. 제출 문구·Support URL·Privacy Policy URL·App Privacy 답변은 아직 준비되지 않았다.
- Firebase Core가 앱 시작 시 초기화되고 Firebase iOS SDK가 포함된다. 데이터 미수집 선언과 수출 규정 답변은 MAR-35의 최종 SDK·네트워크 감사 전 확정할 수 없다.
- release/App Store 빌드가 아직 선택되지 않아 실제 기기 재현, 업로드 빌드 대조, 최종 UI와 홍보 자산 일치, App Store Connect 필드·스크린샷 슬롯 검증을 수행하지 않았다.
- Apple 스크린샷 문서의 필수 크기 요약과 허용·축소 규격 설명은 실제 App Store Connect 슬롯에서 최종 확인해야 한다.

## 교차 모델 리뷰

- Claude 리뷰: P0 0건, P1 1건, P2 2건.
- P1 재현 순서는 실제 권한 요청·asset 설치·준비 상태 UI를 모두 구분하도록 수정했다.
- P2는 MAR-52 병합 상태와 기준 커밋을 최신화하고, 오프라인 재현에 asset 사전 설치 조건을 명시했다.

## 검증 결과

- `git diff --check`: 통과
- `dart format --output=none --set-exit-if-changed .`: 통과, 변경 0개
- `flutter analyze`: 통과, 이슈 0개
- `flutter test`: 117개 통과
- `scripts/check_public_repo.sh`: 통과
- `bundle exec fastlane validate_store_assets`: 원본·홍보용 스크린샷 규격, 순서, 픽스처, 민감정보 검사 통과
- `flutter build apk --debug`: 통과
- `flutter build ios --simulator --debug --no-codesign`: 통과
- 문서 전용 변경이라 새 UI·큰 글씨 스크린샷은 만들지 않고 MAR-52의 검증된 자산과 contact sheet를 감사했다.

## Marco 개입 지점

- 현재까지 없음.
- 향후 한 가지 결정: MAR-35 감사 후 수출 규정 질문에서 면제되는 표준/OS 암호화 경로와 별도 문서 경로 중 실제 빌드에 맞는 경로 선택.
