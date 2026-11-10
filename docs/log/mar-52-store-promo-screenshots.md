# MAR-52 스토어 홍보용 스크린샷

## 결정

- Marketing 소유: 스토어 카피, 크리에이티브, 재생성 자동화
- Marco 승인 방향: 사용 순서 중심(A)
- 화면 순서: 대본 목록 → 직접 입력 → 반복 설정 → 낭독 진행
- 승인 이유: 앱 안에 상세 튜토리얼이 없으므로 스토어의 네 장이 기본 사용 흐름을
  설명하도록 한다.

## Product & Design 협업 검토

- Product는 첫 장에서 핵심 사용 결과를 보여주는 안을 권고했지만, 사용 순서 안은
  처음 접하는 사용자가 별도 튜토리얼 없이 전체 흐름을 이해하기 쉽다고 평가했다.
- Design은 중립 배경, 짧은 카피, 실제 UI를 결합한 절제된 체계를 권고했다. 승인된
  안에서는 장식과 기기 프레임을 배제하고 실제 화면을 중심으로 이 원칙을 적용했다.
- 기본 세트에는 기본 글씨 화면을 사용한다. 200% 큰 글씨 화면은 기본 앱 모습으로
  오해되지 않도록 홍보 세트와 분리하고 QA contact sheet에서 같은 시나리오끼리
  비교한다.

## 공식 규격 검증

2026-11-10에 아래 공식 문서를 확인했다.

- Apple App Store Connect Screenshot specifications
  - 기기 크기별 1~10장, JPEG/JPG/PNG, 알파·투명도 금지
  - iPhone Dynamic Island large display 허용 세로 크기 중 `1320×2868` 사용
  - iPad 13형 허용 세로 크기 중 `2064×2752` 사용
  - 현재 필수 iPhone 대표 크기는 Dynamic Island medium display로 표현되므로 실제
    제출 직전에 App Store Connect에서 추가 세트 필요 여부를 다시 확인한다.
  - https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/
- Google Play Console preview assets
  - JPEG 또는 24-bit PNG, 알파 없음, 각 변 320~3840px, 긴 변은 짧은 변의 2배 이하
  - 앱 추천 노출에는 4장 이상, 세로 9:16 최소 `1080×1920` 권고
  - 실제 앱 경험 중심, 필요한 경우에만 태그라인 사용, 카피는 이미지의 20% 이하 권고
  - https://support.google.com/googleplay/android-developer/answer/9866151

## 개인정보·저작권

- PR #81의 고정 픽스처 구조를 기반으로 이 작업에서 직접 작성한 고정 더미 데이터만
  사용했다.
- 대본은 `말또 사용 가이드`, `우리 가족을 위한 기도문`,
  `프로젝트 프레젠테이션 소개 문장`이며 모두 이 프로젝트를 위해 직접 작성했다.
  manifest에는 원본 작성·개인정보 없음이 기록되어 있다.
- 제3자 기도문·경전·가사·시, 실제 사용자 데이터, 계정 정보, 기기 식별자 및
  로컬 사용자 경로를 사용하지 않는다.
- 실제 App Store Connect·Google Play Console 업로드는 수행하지 않는다.

## 재생성과 검증

```bash
bundle exec fastlane compose_store_promotional
bundle exec fastlane validate_store_assets
```

자동 검증은 4장 순서, 대상별 개수와 정확한 픽셀 크기, 24-bit RGB PNG와 알파
부재, 템플릿·픽스처 민감정보 패턴, contact sheet 존재를 확인한다. 최종 시각 검토는
플랫폼별 홍보 contact sheet와 기본/200% QA contact sheet로 수행한다.

200% 큰 글씨의 낭독 설정 화면은 기존 고정 높이 시트에서 선택값이 첫 화면 아래로
이동하지만 스크롤로 접근 가능하다. 이번 작업은 앱 UI를 변경하지 않으며, 기본 홍보
세트와 큰 글씨 QA 세트를 분리해 이를 대표 화면으로 오인하지 않도록 했다.

교차 모델 리뷰에서 iPhone 기본 캡처가 시뮬레이터의 Accessibility XXXL 설정을
상속한 문제가 발견됐다. 기본 모드는 text scale `1.0`, 큰 글씨 모드는 `2.0`으로
통합 테스트에서 명시하도록 수정하고 원본·홍보 결과를 다시 생성했다. 카피 하단이
전체 높이의 20%를 넘으면 합성을 실패시키고, 실제 UI 하단을 자르던 오프셋도
제거했다.

Marco의 PR 리뷰에 따라 홍보 카피는 Apple SD Gothic Neo SemiBold로 정리하고
불필요한 페이지 번호를 제거했다. 기기 외곽 곡률도 공통값 대신 iPhone·iPad·
Android별 비율로 분리해 iPhone이 Android 카드처럼 보이지 않도록 조정했다.
