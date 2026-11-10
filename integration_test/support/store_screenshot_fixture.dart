import 'dart:async';

import 'package:maltto/src/features/reading/data/reading_session_repository.dart';
import 'package:maltto/src/features/reading/domain/reading_session.dart';
import 'package:maltto/src/features/scripts/data/script_repository.dart';
import 'package:maltto/src/features/scripts/model/script.dart';

const storeScreenshotTitle = '발표 리허설';
const storeScreenshotBody =
    '안녕하세요. 오늘은 작은 습관이 하루를 바꾸는 방법을 소개하겠습니다. '
    '먼저 시작하기 쉬운 목표를 정합니다. 다음으로 매일 같은 시간에 천천히 읽습니다. '
    '마지막으로 끝난 뒤 한 문장으로 느낌을 기록합니다.';
const storeScreenshotSecondTitle = '아침 자기 확언';
const storeScreenshotSecondBody =
    '나는 오늘 해야 할 일을 차분히 시작합니다. 한 번에 한 가지에 집중하고, '
    '작은 진전도 소중하게 받아들입니다.';

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

final storeScreenshotScripts = <Script>[
  storeScreenshotScript,
  storeScreenshotSecondScript,
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
      currentWordIndex: 0,
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
    '안녕하세요.',
    '오늘은',
    '작은',
    '습관이',
    '하루를',
    '바꾸는',
    '방법을',
    '소개하겠습니다.',
    '먼저',
    '시작하기',
    '쉬운',
    '목표를',
    '정합니다.',
    '다음으로',
    '매일',
    '같은',
    '시간에',
    '천천히',
    '읽습니다.',
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
