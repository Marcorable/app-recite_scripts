import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:maltto/src/features/reading/domain/reading_session.dart';

const _diagnosticsRequested = bool.fromEnvironment('READING_DIAGNOSTICS');

enum ReadingDiagnosticKind {
  sessionStarted,
  recognitionReady,
  cursorAdvanced,
  recognitionRestarted,
  recognitionFailed,
  movedBack,
  nextRepetitionStarted,
  repetitionCompleted,
  sessionCompleted,
  sessionLeft,
  heartbeat,
}

final class ReadingDiagnosticEvent {
  const ReadingDiagnosticEvent({
    required this.kind,
    required this.sessionId,
    required this.generation,
    required this.repetition,
    required this.totalRepetitions,
    required this.cursor,
    required this.totalWords,
    required this.elapsedMillis,
    this.reason,
  });

  factory ReadingDiagnosticEvent.fromState({
    required ReadingDiagnosticKind kind,
    required ReadingSessionState state,
    String? reason,
  }) => ReadingDiagnosticEvent(
    kind: kind,
    sessionId: state.sessionId,
    generation: state.generation,
    repetition: state.currentRepetition,
    totalRepetitions: state.totalRepetitions,
    cursor: state.currentWordIndex,
    totalWords: state.totalWords,
    elapsedMillis: state.elapsed.inMilliseconds,
    reason: reason,
  );

  final ReadingDiagnosticKind kind;
  final String sessionId;
  final int generation;
  final int repetition;
  final int totalRepetitions;
  final int? cursor;
  final int totalWords;
  final int elapsedMillis;
  final String? reason;

  Map<String, Object?> toJson() => {
    'event': kind.name,
    'sessionId': sessionId,
    'generation': generation,
    'repetition': repetition,
    'totalRepetitions': totalRepetitions,
    'cursor': cursor,
    'totalWords': totalWords,
    'elapsedMillis': elapsedMillis,
    if (reason != null) 'reason': reason,
  };
}

abstract interface class ReadingSessionDiagnostics {
  void record(ReadingDiagnosticEvent event);
}

final class NoopReadingSessionDiagnostics implements ReadingSessionDiagnostics {
  const NoopReadingSessionDiagnostics();

  @override
  void record(ReadingDiagnosticEvent event) {}
}

final class DebugReadingSessionDiagnostics
    implements ReadingSessionDiagnostics {
  const DebugReadingSessionDiagnostics();

  @override
  void record(ReadingDiagnosticEvent event) {
    debugPrint('MalttoReadingDiagnostics ${jsonEncode(event.toJson())}');
  }
}

ReadingSessionDiagnostics createReadingSessionDiagnostics() =>
    kDebugMode && _diagnosticsRequested
    ? const DebugReadingSessionDiagnostics()
    : const NoopReadingSessionDiagnostics();
