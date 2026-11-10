part of 'reading_view.dart';

String _failureMessage(ReadingSessionFailure failure) => switch (failure) {
  ReadingSessionFailure.permissionDenied =>
    '마이크 또는 음성 인식 권한이 꺼졌습니다. 설정에서 권한을 확인해 주세요.',
  ReadingSessionFailure.modelUnavailable =>
    '온디바이스 한국어 음성 모델을 사용할 수 없습니다. 준비 상태를 다시 확인해 주세요.',
  ReadingSessionFailure.unsupported => '이 기기에서 온디바이스 한국어 음성 인식을 사용할 수 없습니다.',
  ReadingSessionFailure.audioUnavailable =>
    '음성 인식에 필요한 오디오 입력을 사용할 수 없습니다. 목록으로 돌아가 마이크와 기기 지원 상태를 확인해 주세요.',
  ReadingSessionFailure.interrupted =>
    '전화나 다른 오디오 작업으로 음성 인식이 중단되었습니다. 방해가 끝난 뒤 다시 시도해 주세요.',
  ReadingSessionFailure.unknown => '일시적인 음성 인식 오류가 발생했습니다. 잠시 후 다시 시도해 주세요.',
};

String _formatElapsed(Duration elapsed) {
  final hours = elapsed.inHours;
  final minutes = (elapsed.inMinutes % 60).toString().padLeft(2, '0');
  final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
  return hours > 0
      ? '${hours.toString().padLeft(2, '0')}:$minutes:$seconds'
      : '$minutes:$seconds';
}

String _elapsedSemantics(Duration elapsed) {
  final parts = <String>[];
  if (elapsed.inHours > 0) parts.add('${elapsed.inHours}시간');
  final minutes = elapsed.inMinutes % 60;
  if (minutes > 0) parts.add('$minutes분');
  parts.add('${elapsed.inSeconds % 60}초');
  return '경과 시간, ${parts.join(' ')}';
}
