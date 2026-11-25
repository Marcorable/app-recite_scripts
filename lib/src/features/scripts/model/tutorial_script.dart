import 'package:maltto/src/features/scripts/model/script.dart';

/// 첫 낭독 흐름에서만 사용하는 비저장 중립 대본입니다.
Script createTutorialScript() {
  final timestamp = DateTime.utc(2026);
  return Script(
    id: -1,
    title: '첫 낭독 연습',
    body:
        '숨을 고르고 천천히 첫 문장을 읽어 봅니다. '
        '화면에 표시된 낱말을 따라 또박또박 말합니다. '
        '끝까지 읽은 뒤 다음 연습을 시작합니다.',
    createdAt: timestamp,
    updatedAt: timestamp,
  );
}
