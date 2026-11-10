import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../integration_test/support/store_screenshot_fixture.dart';

void main() {
  test('store screenshot fixture matches the reviewed JSON source', () async {
    final json = jsonDecode(
      await File('store_assets/fixtures/ko-KR/scripts.json').readAsString(),
    ) as Map<String, Object?>;
    final provenance = json['provenance']! as Map<String, Object?>;
    final scripts = json['scripts']! as List<Object?>;

    expect(json['locale'], 'ko-KR');
    expect(provenance['type'], 'original');
    expect(provenance['containsPersonalData'], isFalse);
    expect(scripts, hasLength(storeScreenshotScripts.length));

    for (var index = 0; index < scripts.length; index++) {
      final source = scripts[index]! as Map<String, Object?>;
      final fixture = storeScreenshotScripts[index];
      expect(source['id'], fixture.id);
      expect(source['title'], fixture.title);
      expect(source['body'], fixture.body);
    }
  });
}
