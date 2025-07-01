import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:audio_waveforms/src/base/constants.dart';

void main() {
  debugDefaultTargetPlatformOverride = TargetPlatform.android;
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(Constants.methodChannelName);
  const recordChannel = MethodChannel('com.llfbandit.record/messages');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(recordChannel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  test('checkPermission returns true from platform', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == Constants.checkPermission) {
        return true;
      }
      return null;
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(recordChannel, (MethodCall methodCall) async {
      if (methodCall.method == 'hasPermission') {
        return true;
      }
      if (methodCall.method == 'create') {
        return null;
      }
      return null;
    });

    final controller = RecorderController();
    final hasPermission = await controller.checkPermission();
    expect(hasPermission, isTrue);
  });
}
