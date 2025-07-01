import 'dart:io';
import 'package:test/test.dart';

void main() {
  test('android build.gradle uses Java 21 and Kotlin 2', () {
    final gradleFile = File('android/build.gradle').readAsStringSync();
    expect(gradleFile.contains("jvmTarget = '21'"), isTrue);
    expect(gradleFile.contains('VERSION_21'), isTrue);
    expect(gradleFile.contains("ext.kotlin_version = '2"), isTrue);
  });
}
