import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final output = Platform.environment['STORE_SCREENSHOT_OUTPUT'];
  if (output == null || output.isEmpty) {
    throw StateError('STORE_SCREENSHOT_OUTPUT 환경 변수가 필요합니다.');
  }
  final directory = Directory(output)..createSync(recursive: true);

  await integrationDriver(
    onScreenshot: (name, bytes, [args]) async {
      final file = File('${directory.path}/$name.png');
      if (!_isCompletePng(bytes)) {
        throw StateError('Flutter 스크린샷 PNG가 완전하지 않습니다: $name');
      }
      file.writeAsBytesSync(bytes, flush: true);
      return file.lengthSync() > 0;
    },
  );
}

bool _isCompletePng(List<int> bytes) {
  const signature = <int>[137, 80, 78, 71, 13, 10, 26, 10];
  const iend = <int>[0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130];
  if (bytes.length < 10000) return false;
  for (var index = 0; index < signature.length; index++) {
    if (bytes[index] != signature[index]) return false;
  }
  final iendStart = bytes.length - iend.length;
  for (var index = 0; index < iend.length; index++) {
    if (bytes[iendStart + index] != iend[index]) return false;
  }
  return true;
}
