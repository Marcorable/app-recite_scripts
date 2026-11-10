import 'dart:async';

import 'package:maltto/src/features/reading/data/reading_session_repository.dart';
import 'package:maltto/src/features/reading/domain/reading_session.dart';
import 'package:maltto/src/features/scripts/data/script_repository.dart';
import 'package:maltto/src/features/scripts/model/script.dart';

const storeScreenshotTitle = '말또 사용 가이드';
const storeScreenshotBody =
    '말또 사용법을 함께 익혀보겠습니다. 먼저 추가를 눌러 제목과 본문을 입력합니다. '
    '저장한 대본을 선택하고 읽을 횟수를 정합니다. 낭독 시작을 누른 뒤 강조되는 어절을 '
    '따라 천천히 읽습니다.';
const storeScreenshotSecondTitle = '우리 가족을 위한 기도문';
const storeScreenshotSecondBody =
    '오늘도 우리 가족이 서로를 아끼고 건강하게 지낼 수 있기를 바랍니다. '
    '각자의 자리에서 평안한 하루를 보내고 따뜻한 마음을 나눌 수 있기를 바랍니다.';
const storeScreenshotThirdTitle = '프로젝트 프레젠테이션 소개 문장';
const storeScreenshotThirdBody =
    '안녕하세요. 지금부터 프로젝트의 목표와 진행 상황을 소개하겠습니다. '
    '먼저 해결하려는 문제를 살펴보고 주요 결과와 다음 계획을 차례로 말씀드리겠습니다.';

final storeScreenshotScript = Script(
  id: 1,
  title: storeScreenshotTitle,
  body: storeScreenshotBody,
  createdAt: DateTime.utc(2026, 11, 5),
  updatedAt: DateTime.utc(2026, 11, 5),
);

final storeScreenshotSecondScript = Script(
  id: 2,
  title: storeScreenshotSecondTitle,
  body: storeScreenshotSecondBody,
  createdAt: DateTime.utc(2026, 11, 4),
  updatedAt: DateTime.utc(2026, 11, 4),
);

final storeScreenshotThirdScript = Script(
  id: 3,
  title: storeScreenshotThirdTitle,
  body: storeScreenshotThirdBody,
  createdAt: DateTime.utc(2026, 11, 3),
  updatedAt: DateTime.utc(2026, 11, 3),
);

final storeScreenshotScripts = <Script>[
  storeScreenshotScript,
  storeScreenshotSecondScript,
  storeScreenshotThirdScript,
];

final class StoreScreenshotScriptRepository implements ScriptRepository {
  StoreScreenshotScriptRepository({List<Script>? scripts})
    : _scripts = [...?scripts];

  final StreamController<List<Script>> _controller =
      StreamController<List<Script>>.broadcast();
  final List<Script> _scripts;
  int _nextId = 10;
  bool _disposed = false;

  @override
  Stream<List<Script>> watchAll() async* {
    yield List<Script>.unmodifiable(_scripts);
    yield* _controller.stream;
  }

  @override
  Future<List<Script>> getAll() async => List<Script>.unmodifiable(_scripts);

  @override
  Future<Script> create({required String title, required String body}) async {
    final now = DateTime.utc(2026, 11, 5);
    final script = Script(
      id: _nextId++,
      title: title,
      body: body,
      createdAt: now,
      updatedAt: now,
    );
    _scripts.insert(0, script);
    _controller.add(List<Script>.unmodifiable(_scripts));
    return script;
  }

  @override
  Future<void> delete(int id) async {
    _scripts.removeWhere((script) => script.id == id);
    _controller.add(List<Script>.unmodifiable(_scripts));
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _controller.close();
  }
}

final class StoreScreenshotReadingRepository
    implements ReadingSessionRepository {
  StoreScreenshotReadingRepository({ReadingSessionState? initialState})
    : _state = initialState;

  final StreamController<ReadingSessionState> _controller =
      StreamController<ReadingSessionState>.broadcast(sync: true);
  ReadingSessionState? _state;
  bool _disposed = false;

  @override
  ReadingSessionState? get state => _state;

  @override
  Stream<ReadingSessionState> get states => _controller.stream;

  @override
  Future<ReadingSessionState> start({
    required Script script,
    required int repetitions,
  }) async {
    _state = storeScreenshotReadingState(
      repetitions: repetitions,
      currentWordIndex: 8,
    );
    return _state!;
  }

  @override
  Future<void> moveBackOneWord() async {
    final state = _state;
    final index = state?.currentWordIndex;
    if (state == null || index == null || index == 0) return;
    _state = storeScreenshotReadingState(
      repetitions: state.totalRepetitions,
      currentWordIndex: index - 1,
    );
    _controller.add(_state!);
  }

  @override
  Future<void> continueNextRepetition() async {}

  @override
  Future<bool> openAppSettings() async => false;

  @override
  Future<void> leave() async {}

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _controller.close();
  }
}

ReadingSessionState storeScreenshotReadingState({
  int repetitions = 3,
  int currentWordIndex = 8,
}) {
  const words = <String>[
    '말또',
    '사용법을',
    '함께',
    '익혀보겠습니다.',
    '먼저',
    '추가를',
    '눌러',
    '제목과',
    '본문을',
    '입력합니다.',
    '저장한',
    '대본을',
    '선택하고',
    '읽을',
    '횟수를',
    '정합니다.',
    '낭독',
    '시작을',
    '누릅니다.',
  ];
  return ReadingSessionState(
    sessionId: 'store-screenshot-session',
    scriptTitle: storeScreenshotTitle,
    status: ReadingSessionStatus.running,
    currentRepetition: 1,
    totalRepetitions: repetitions,
    currentWordIndex: currentWordIndex,
    currentWord: words[currentWordIndex],
    words: words,
    totalWords: words.length,
    elapsed: const Duration(seconds: 38),
    generation: 1,
  );
}
