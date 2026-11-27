import 'package:maltto/src/features/reading/data/reading_session_diagnostics.dart';
import 'package:maltto/src/features/reading/domain/reading_session.dart';
import 'package:test/test.dart';

void main() {
  test('진단 JSON은 상태 식별자만 포함하고 대본 필드를 제공하지 않는다', () {
    const event = ReadingDiagnosticEvent(
      kind: ReadingDiagnosticKind.heartbeat,
      sessionId: 'reading-1',
      generation: 2,
      repetition: 3,
      totalRepetitions: 10,
      cursor: 25,
      totalWords: 120,
      elapsedMillis: 300000,
      reason: 'ended',
    );

    expect(event.toJson(), {
      'event': 'heartbeat',
      'sessionId': 'reading-1',
      'generation': 2,
      'repetition': 3,
      'totalRepetitions': 10,
      'cursor': 25,
      'totalWords': 120,
      'elapsedMillis': 300000,
      'reason': 'ended',
    });
    expect(
      event.toJson().keys,
      isNot(containsAll(['scriptTitle', 'currentWord', 'words', 'transcript'])),
    );
  });

  test('상태 변환도 대본 제목과 어절을 진단 JSON에 넣지 않는다', () {
    const state = ReadingSessionState(
      sessionId: 'reading-7',
      scriptTitle: '민감한 제목',
      status: ReadingSessionStatus.running,
      currentRepetition: 1,
      totalRepetitions: 2,
      currentWordIndex: 4,
      currentWord: '민감한어절',
      words: ['민감한어절'],
      totalWords: 20,
      elapsed: Duration(seconds: 12),
      generation: 3,
      recognitionStatus: ReadingRecognitionStatus.listening,
    );

    final json = ReadingDiagnosticEvent.fromState(
      kind: ReadingDiagnosticKind.cursorAdvanced,
      state: state,
    ).toJson();

    expect(json.values, isNot(contains('민감한 제목')));
    expect(json.values, isNot(contains('민감한어절')));
    expect(json.values, isNot(contains(state.words)));
  });
}
