import 'dart:async';

import 'package:maltto/src/features/reading/data/local_reading_session_repository.dart';
import 'package:maltto/src/features/reading/data/reading_session_repository.dart';
import 'package:maltto/src/features/reading/data/reading_session_timer.dart';
import 'package:maltto/src/features/reading/domain/reading_session.dart';
import 'package:maltto/src/features/scripts/model/script.dart';
import 'package:maltto/src/infrastructure/stt/stt_models.dart';
import 'package:maltto/src/infrastructure/stt/stt_service.dart';
import 'package:test/test.dart';

void main() {
  late _FakeSttService sttService;
  late _FakeTimerFactory timerFactory;
  late DateTime now;
  late LocalReadingSessionRepository repository;

  setUp(() {
    sttService = _FakeSttService();
    timerFactory = _FakeTimerFactory();
    now = DateTime.utc(2026, 11, 2, 9);
    repository = LocalReadingSessionRepository(
      sttService,
      timerFactory: timerFactory.create,
      clock: () => now,
    );
  });

  tearDown(() async {
    await repository.dispose();
    await sttService.close();
  });

  test('최종 완료는 STT 작업, 구독, timer를 정확히 한 번 정리한다', () async {
    await repository.start(script: _script, repetitions: 1);
    now = now.add(const Duration(seconds: 3));
    timerFactory.timer.fire();
    expect(repository.state?.elapsed, const Duration(seconds: 3));

    sttService.emit(
      const SttEvent(
        sessionId: 'reading-1',
        generation: 1,
        sequence: 1,
        kind: SttEventKind.partial,
        text: _body,
      ),
    );
    sttService.emit(
      const SttEvent(
        sessionId: 'reading-1',
        generation: 1,
        sequence: 2,
        kind: SttEventKind.finalResult,
        text: _body,
      ),
    );
    await pumpEventQueue(times: 10);

    expect(repository.state?.status, ReadingSessionStatus.completed);
    expect(sttService.cancelledSessionIds, ['reading-1']);
    expect(sttService.subscriptionCancelCount, 1);
    expect(timerFactory.timer.isActive, isFalse);

    now = now.add(const Duration(seconds: 4));
    timerFactory.timer.fire();
    expect(repository.state?.elapsed, const Duration(seconds: 3));
  });

  test('회차 경계에서 이전 작업을 취소하고 이어하기 전까지 새 generation을 대기한다', () async {
    await repository.start(script: _script, repetitions: 2);

    sttService.emit(
      const SttEvent(
        sessionId: 'reading-1',
        generation: 1,
        sequence: 1,
        kind: SttEventKind.finalResult,
        text: _body,
      ),
    );
    await pumpEventQueue(times: 10);

    expect(repository.state?.currentRepetition, 2);
    expect(repository.state?.currentWord, '아침에는');
    expect(repository.state?.generation, 2);
    expect(
      repository.state?.status,
      ReadingSessionStatus.awaitingNextRepetition,
    );
    expect(sttService.startedGenerations, [1]);
    expect(sttService.cancelledSessionIds, ['reading-1']);

    sttService.emit(
      const SttEvent(
        sessionId: 'reading-1',
        generation: 1,
        sequence: 2,
        kind: SttEventKind.finalResult,
        text: _body,
      ),
    );
    expect(repository.state?.currentWordIndex, 0);

    sttService.emit(
      const SttEvent(
        sessionId: 'reading-1',
        generation: 2,
        sequence: 1,
        kind: SttEventKind.partial,
        text: _body,
      ),
    );
    expect(repository.state?.currentWordIndex, 0);

    await repository.continueNextRepetition();
    await pumpEventQueue(times: 10);

    expect(repository.state?.status, ReadingSessionStatus.running);
    expect(sttService.startedGenerations, [1, 2]);

    sttService.emit(
      const SttEvent(
        sessionId: 'reading-1',
        generation: 2,
        sequence: 2,
        kind: SttEventKind.partial,
        text: _body,
      ),
    );
    await pumpEventQueue(times: 10);

    expect(repository.state?.status, ReadingSessionStatus.completed);
    expect(sttService.startedGenerations, [1, 2]);
    expect(sttService.cancelledSessionIds, ['reading-1', 'reading-1']);
    expect(sttService.subscriptionCancelCount, 1);
  });

  test('3회 낭독은 회차마다 한 번만 대기하고 새 generation에서 첫 어절로 시작한다', () async {
    await repository.start(script: _script, repetitions: 3);

    sttService.emit(_transcript(generation: 1, sequence: 1, text: _body));
    await pumpEventQueue(times: 10);

    expect(
      repository.state?.status,
      ReadingSessionStatus.awaitingNextRepetition,
    );
    expect(repository.state?.currentRepetition, 2);
    expect(repository.state?.currentWordIndex, 0);
    expect(repository.state?.generation, 2);
    expect(sttService.cancelledSessionIds, ['reading-1']);

    sttService.emit(_transcript(generation: 1, sequence: 2, text: _body));
    sttService.emit(
      const SttEvent(
        sessionId: 'reading-1',
        generation: 1,
        sequence: 3,
        kind: SttEventKind.failure,
        failureCode: SttFailureCode.audio,
        retryable: false,
      ),
    );
    await repository.continueNextRepetition();
    await repository.continueNextRepetition();
    await pumpEventQueue(times: 10);

    expect(repository.state?.status, ReadingSessionStatus.running);
    expect(repository.state?.currentWordIndex, 0);
    expect(sttService.startedGenerations, [1, 2]);

    sttService.emit(_transcript(generation: 2, sequence: 1, text: _body));
    await pumpEventQueue(times: 10);

    expect(
      repository.state?.status,
      ReadingSessionStatus.awaitingNextRepetition,
    );
    expect(repository.state?.currentRepetition, 3);
    expect(repository.state?.currentWordIndex, 0);
    expect(repository.state?.generation, 3);
    expect(sttService.cancelledSessionIds, ['reading-1', 'reading-1']);

    await repository.continueNextRepetition();
    await pumpEventQueue(times: 10);
    sttService.emit(_transcript(generation: 3, sequence: 1, text: _body));
    await pumpEventQueue(times: 10);

    expect(repository.state?.status, ReadingSessionStatus.completed);
    expect(sttService.startedGenerations, [1, 2, 3]);
    expect(sttService.subscriptionCancelCount, 1);
    expect(timerFactory.timers.single.isActive, isFalse);
  });

  test('회차 대기 중 그만하기는 새 STT를 시작하지 않고 자원을 정리한다', () async {
    await repository.start(script: _script, repetitions: 2);
    sttService.emit(
      const SttEvent(
        sessionId: 'reading-1',
        generation: 1,
        sequence: 1,
        kind: SttEventKind.finalResult,
        text: _body,
      ),
    );
    await pumpEventQueue(times: 10);

    await repository.leave();

    expect(repository.state?.status, ReadingSessionStatus.exited);
    expect(sttService.startedGenerations, [1]);
    expect(sttService.subscriptionCancelCount, 1);
    expect(timerFactory.timer.isActive, isFalse);
  });

  test('한 어절 뒤로는 이전 STT를 취소하고 새 generation에서 재시작한다', () async {
    await repository.start(script: _script, repetitions: 1);
    sttService.emit(
      const SttEvent(
        sessionId: 'reading-1',
        generation: 1,
        sequence: 1,
        kind: SttEventKind.finalResult,
        text: '아침에는 창문을 열고',
      ),
    );
    expect(repository.state?.currentWordIndex, 3);

    await repository.moveBackOneWord();
    expect(repository.state?.currentWordIndex, 2);
    expect(repository.state?.generation, 2);
    await pumpEventQueue(times: 10);

    expect(sttService.cancelledSessionIds, ['reading-1']);
    expect(sttService.startedGenerations, [1, 2]);

    sttService.emit(
      const SttEvent(
        sessionId: 'reading-1',
        generation: 1,
        sequence: 2,
        kind: SttEventKind.finalResult,
        text: _body,
      ),
    );
    expect(repository.state?.currentWordIndex, 2);
  });

  test('한 어절 뒤로 직후 이전 전사와 timer는 커서를 다시 전진시키지 않는다', () async {
    await repository.start(script: _script, repetitions: 1);
    sttService.emit(
      _transcript(generation: 1, sequence: 1, text: '아침에는 창문을 열고'),
    );
    expect(repository.state?.currentWordIndex, 3);

    await repository.moveBackOneWord();
    now = now.add(const Duration(seconds: 8));
    timerFactory.timer.fire();
    sttService.emit(_transcript(generation: 1, sequence: 2, text: _body));
    await pumpEventQueue(times: 10);

    expect(repository.state?.currentWordIndex, 2);
    expect(repository.state?.generation, 2);
    expect(repository.state?.elapsed, const Duration(seconds: 8));
  });

  test('첫 어절에서 뒤로는 STT를 재시작하지 않고 후속 전사를 반영한다', () async {
    await repository.start(script: _script, repetitions: 1);

    await repository.moveBackOneWord();
    await pumpEventQueue(times: 10);

    expect(repository.state?.currentWordIndex, 0);
    expect(repository.state?.generation, 1);
    expect(sttService.cancelledSessionIds, isEmpty);
    expect(sttService.startedGenerations, [1]);

    sttService.emit(
      const SttEvent(
        sessionId: 'reading-1',
        generation: 1,
        sequence: 1,
        kind: SttEventKind.finalResult,
        text: _body,
      ),
    );
    await pumpEventQueue(times: 10);

    expect(repository.state?.status, ReadingSessionStatus.completed);
  });

  test('회차 도중 ended 이벤트는 진행 상태를 유지하고 인식을 재시작한다', () async {
    await repository.start(script: _script, repetitions: 2);
    sttService.emit(
      const SttEvent(
        sessionId: 'reading-1',
        generation: 1,
        sequence: 1,
        kind: SttEventKind.finalResult,
        text: '아침에는 창문을',
      ),
    );
    final wordIndex = repository.state?.currentWordIndex;

    sttService.emit(
      const SttEvent(
        sessionId: 'reading-1',
        generation: 1,
        sequence: 2,
        kind: SttEventKind.ended,
      ),
    );
    await pumpEventQueue(times: 10);

    expect(repository.state?.status, ReadingSessionStatus.running);
    expect(repository.state?.currentRepetition, 1);
    expect(repository.state?.currentWordIndex, wordIndex);
    expect(repository.state?.generation, 2);
    expect(sttService.startedGenerations, [1, 2]);
    expect(sttService.cancelledSessionIds, isEmpty);

    sttService.emit(
      const SttEvent(
        sessionId: 'reading-1',
        generation: 1,
        sequence: 3,
        kind: SttEventKind.ended,
      ),
    );
    await pumpEventQueue(times: 10);
    expect(sttService.startedGenerations, [1, 2]);
  });

  test('retryable failure는 진행 상태를 유지하고 인식을 재시작한다', () async {
    await repository.start(script: _script, repetitions: 1);
    sttService.emit(
      const SttEvent(
        sessionId: 'reading-1',
        generation: 1,
        sequence: 1,
        kind: SttEventKind.failure,
        failureCode: SttFailureCode.noMatch,
        retryable: true,
      ),
    );
    await pumpEventQueue(times: 10);

    expect(repository.state?.status, ReadingSessionStatus.running);
    expect(repository.state?.currentWordIndex, 0);
    expect(repository.state?.generation, 2);
    expect(sttService.startedGenerations, [1, 2]);
  });

  test('복구 불가 failure는 세션을 종료하고 모든 자원을 정리한다', () async {
    await repository.start(script: _script, repetitions: 1);
    sttService.emit(
      const SttEvent(
        sessionId: 'reading-1',
        generation: 1,
        sequence: 1,
        kind: SttEventKind.failure,
        failureCode: SttFailureCode.permissionDenied,
        retryable: false,
      ),
    );
    await pumpEventQueue(times: 10);

    expect(repository.state?.status, ReadingSessionStatus.exited);
    expect(repository.state?.failure, ReadingSessionFailure.permissionDenied);
    expect(sttService.cancelledSessionIds, ['reading-1']);
    expect(sttService.subscriptionCancelCount, 1);
    expect(timerFactory.timer.isActive, isFalse);
  });

  test('dispose는 시작 중인 STT 작업을 무효화하고 timer를 만들지 않는다', () async {
    final startBarrier = Completer<void>();
    sttService.startBarrier = startBarrier;
    final startFuture = repository.start(script: _script, repetitions: 1);
    await pumpEventQueue(times: 10);
    expect(sttService.startedGenerations, [1]);

    final disposeFuture = repository.dispose();
    await pumpEventQueue(times: 10);
    startBarrier.complete();

    await expectLater(startFuture, throwsA(isA<StateError>()));
    await disposeFuture;
    expect(timerFactory.createCount, 0);
    expect(sttService.disposeCount, 1);
  });

  test('준비 중 나가기는 시작 요청을 무효화하고 STT를 시작하지 않는다', () async {
    final prepareBarrier = Completer<void>();
    sttService.prepareBarrier = prepareBarrier;
    final startFuture = repository.start(script: _script, repetitions: 1);
    await pumpEventQueue(times: 10);
    expect(sttService.prepareCallCount, 1);

    await repository.leave();
    prepareBarrier.complete();

    await expectLater(startFuture, throwsA(isA<StateError>()));
    expect(repository.state, isNull);
    expect(sttService.startedGenerations, isEmpty);
    expect(timerFactory.createCount, 0);
  });

  test('나가기는 네이티브 취소 오류에도 종료 상태와 구독 정리를 유지한다', () async {
    await repository.start(script: _script, repetitions: 1);
    sttService.cancelError = StateError('취소 실패');

    await repository.leave();

    expect(repository.state?.status, ReadingSessionStatus.exited);
    expect(sttService.subscriptionCancelCount, 1);
    expect(timerFactory.timer.isActive, isFalse);
  });

  test('나가기는 취소 완료 전 상태와 generation부터 무효화한다', () async {
    await repository.start(script: _script, repetitions: 3);
    final cancelBarrier = Completer<void>();
    sttService.cancelBarrier = cancelBarrier;

    final leaveFuture = repository.leave();

    expect(repository.state?.status, ReadingSessionStatus.exited);
    expect(repository.state?.generation, 2);
    expect(timerFactory.timer.isActive, isFalse);
    sttService.emit(
      const SttEvent(
        sessionId: 'reading-1',
        generation: 1,
        sequence: 1,
        kind: SttEventKind.finalResult,
        text: _body,
      ),
    );
    expect(repository.state?.currentRepetition, 1);

    cancelBarrier.complete();
    await leaveFuture;

    expect(sttService.cancelledSessionIds, ['reading-1']);
    expect(sttService.subscriptionCancelCount, 1);
  });

  test('종료 후 늦은 partial final error는 세션 상태를 변경하지 않는다', () async {
    await repository.start(script: _script, repetitions: 2);
    sttService.emit(_transcript(generation: 1, sequence: 1, text: '아침에는 창문을'));

    await repository.leave();
    final exitedState = repository.state;
    sttService.emit(_transcript(generation: 1, sequence: 2, text: _body));
    sttService.emit(
      _transcript(
        generation: 1,
        sequence: 3,
        text: _body,
        kind: SttEventKind.partial,
      ),
    );
    sttService.emit(
      const SttEvent(
        sessionId: 'reading-1',
        generation: 1,
        sequence: 4,
        kind: SttEventKind.failure,
        failureCode: SttFailureCode.audio,
        retryable: false,
      ),
    );
    await pumpEventQueue(times: 10);

    expect(repository.state?.status, ReadingSessionStatus.exited);
    expect(repository.state?.generation, exitedState?.generation);
    expect(repository.state?.currentWordIndex, exitedState?.currentWordIndex);
    expect(repository.state?.failure, isNull);
  });

  test('시작 뒤로 나가기를 반복해도 STT 구독 timer 마이크 세션이 중복되지 않는다', () async {
    for (var session = 1; session <= 3; session++) {
      await repository.start(script: _script, repetitions: 2);
      final sessionId = 'reading-$session';
      sttService.emit(
        SttEvent(
          sessionId: sessionId,
          generation: 1,
          sequence: 1,
          kind: SttEventKind.finalResult,
          text: '아침에는 창문을 열고',
        ),
      );
      await repository.moveBackOneWord();
      await pumpEventQueue(times: 10);
      await repository.leave();

      expect(repository.state?.status, ReadingSessionStatus.exited);
      expect(sttService.activeSubscriptionCount, 0);
      expect(sttService.activeRecognitionCount, 0);
      expect(timerFactory.timers.where((timer) => timer.isActive), isEmpty);
    }

    expect(sttService.maxActiveSubscriptionCount, 1);
    expect(sttService.maxActiveRecognitionCount, 1);
    expect(sttService.subscriptionCancelCount, 3);
    expect(timerFactory.createCount, 3);
  });

  test('모델 설치가 필요하면 다운로드를 요청한 뒤 ready 상태에서 시작한다', () async {
    sttService.preparation = const SttPreparation(
      status: SttPreparationStatus.modelDownloadRequired,
      failureCode: SttFailureCode.modelMissing,
    );
    sttService.modelDownloadPreparation = const SttPreparation(
      status: SttPreparationStatus.ready,
    );

    final state = await repository.start(script: _script, repetitions: 1);

    expect(sttService.modelDownloadRequestCount, 1);
    expect(state.status, ReadingSessionStatus.running);
    expect(sttService.startedGenerations, [1]);
  });

  test('모델 준비 중에는 세션과 STT 작업을 시작하지 않는다', () async {
    sttService.preparation = const SttPreparation(
      status: SttPreparationStatus.modelDownloadRequired,
      failureCode: SttFailureCode.modelMissing,
    );
    sttService.modelDownloadPreparation = const SttPreparation(
      status: SttPreparationStatus.modelDownloading,
    );

    await expectLater(
      repository.start(script: _script, repetitions: 1),
      throwsA(
        isA<ReadingSessionStartException>().having(
          (error) => error.preparation.status,
          'status',
          SttPreparationStatus.modelDownloading,
        ),
      ),
    );

    expect(repository.state, isNull);
    expect(sttService.modelDownloadRequestCount, 1);
    expect(sttService.startedGenerations, isEmpty);
  });

  test('오디오 시작 오류는 복구 UI가 구분할 수 있는 준비 오류로 변환한다', () async {
    sttService.startError = const SttStartException(SttFailureCode.audio);

    await expectLater(
      repository.start(script: _script, repetitions: 1),
      throwsA(
        isA<ReadingSessionStartException>()
            .having(
              (error) => error.preparation.status,
              'status',
              SttPreparationStatus.ready,
            )
            .having(
              (error) => error.preparation.failureCode,
              'failureCode',
              SttFailureCode.audio,
            ),
      ),
    );

    expect(repository.state?.status, ReadingSessionStatus.exited);
    expect(sttService.cancelledSessionIds, ['reading-1']);
  });

  test('앱 설정 열기를 STT 서비스에 위임한다', () async {
    sttService.openAppSettingsResult = true;

    expect(await repository.openAppSettings(), isTrue);
    expect(sttService.openAppSettingsCallCount, 1);
  });
}

const _body = '아침에는 창문을 열고 문장을 읽는다';

SttEvent _transcript({
  required int generation,
  required int sequence,
  required String text,
  SttEventKind kind = SttEventKind.finalResult,
}) => SttEvent(
  sessionId: 'reading-1',
  generation: generation,
  sequence: sequence,
  kind: kind,
  text: text,
);

final _script = Script(
  id: 1,
  title: '아침 낭독',
  body: _body,
  createdAt: DateTime.utc(2026, 11, 2),
  updatedAt: DateTime.utc(2026, 11, 2),
);

final class _FakeTimerFactory {
  late _FakeTimer timer;
  final List<_FakeTimer> timers = [];
  int createCount = 0;

  ReadingSessionTimer create(void Function() onTick) {
    createCount++;
    timer = _FakeTimer(onTick);
    timers.add(timer);
    return timer;
  }
}

final class _FakeTimer implements ReadingSessionTimer {
  _FakeTimer(this._onTick);

  final void Function() _onTick;

  @override
  bool isActive = true;

  void fire() {
    if (isActive) _onTick();
  }

  @override
  void cancel() => isActive = false;
}

final class _FakeSttService implements SttService {
  _FakeSttService() {
    _events = StreamController<SttEvent>.broadcast(
      sync: true,
      onListen: () {
        activeSubscriptionCount++;
        if (activeSubscriptionCount > maxActiveSubscriptionCount) {
          maxActiveSubscriptionCount = activeSubscriptionCount;
        }
      },
      onCancel: () {
        subscriptionCancelCount++;
        activeSubscriptionCount--;
      },
    );
  }

  late final StreamController<SttEvent> _events;
  final List<int> startedGenerations = [];
  final List<String> cancelledSessionIds = [];
  int subscriptionCancelCount = 0;
  int activeSubscriptionCount = 0;
  int maxActiveSubscriptionCount = 0;
  int activeRecognitionCount = 0;
  int maxActiveRecognitionCount = 0;
  Completer<void>? cancelBarrier;
  SttPreparation preparation = const SttPreparation(
    status: SttPreparationStatus.ready,
  );
  SttPreparation modelDownloadPreparation = const SttPreparation(
    status: SttPreparationStatus.modelDownloading,
  );
  int modelDownloadRequestCount = 0;
  int disposeCount = 0;
  int prepareCallCount = 0;
  Completer<void>? startBarrier;
  Completer<void>? prepareBarrier;
  Object? cancelError;
  Object? startError;
  bool openAppSettingsResult = false;
  int openAppSettingsCallCount = 0;

  void emit(SttEvent event) => _events.add(event);

  Future<void> close() => _events.close();

  @override
  Future<SttAvailability> checkAvailability({required String locale}) =>
      throw UnimplementedError();

  @override
  Future<SttPreparation> prepare({required String locale}) async {
    prepareCallCount++;
    await prepareBarrier?.future;
    return preparation;
  }

  @override
  Future<SttPreparation> requestModelDownload({required String locale}) async {
    modelDownloadRequestCount++;
    return modelDownloadPreparation;
  }

  @override
  Future<bool> openAppSettings() async {
    openAppSettingsCallCount++;
    return openAppSettingsResult;
  }

  @override
  Stream<SttEvent> events(String sessionId) => _events.stream;

  @override
  Future<void> start(SttStartRequest request) async {
    startedGenerations.add(request.generation);
    activeRecognitionCount++;
    if (activeRecognitionCount > maxActiveRecognitionCount) {
      maxActiveRecognitionCount = activeRecognitionCount;
    }
    await startBarrier?.future;
    final startError = this.startError;
    if (startError != null) throw startError;
  }

  @override
  Future<void> cancel(String sessionId) async {
    cancelledSessionIds.add(sessionId);
    if (activeRecognitionCount > 0) activeRecognitionCount--;
    await cancelBarrier?.future;
    final cancelError = this.cancelError;
    if (cancelError != null) throw cancelError;
  }

  @override
  Future<void> dispose() async => disposeCount++;
}
