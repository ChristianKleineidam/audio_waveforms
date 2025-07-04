import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('example windows runner declares microphone capability', () {
    final manifest = File('example/windows/runner/runner.exe.manifest');
    expect(manifest.existsSync(), isTrue);
    final contents = manifest.readAsStringSync();
    expect(contents.contains('<DeviceCapability Name="microphone"/>'), isTrue);
  });

  test('example windows runner does not include app_icon.ico', () {
    final icon = File('example/windows/runner/resources/app_icon.ico');
    expect(icon.existsSync(), isFalse);
  });
}
