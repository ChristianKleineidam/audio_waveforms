import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:audio_waveforms/src/base/constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(Constants.methodChannelName);
  const recordChannel = MethodChannel('com.llfbandit.record/messages');

  tearDown(() {
    final messenger = TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, null);
    messenger.setMockMethodCallHandler(recordChannel, null);
  });

  test('checkPermission returns true from platform', () async {
    final messenger = TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == Constants.checkPermission) {
        return true;
      }
      return null;
    });
    messenger.setMockMethodCallHandler(recordChannel, (MethodCall methodCall) async {
      if (methodCall.method == 'create') {
        return null;
      }
      if (methodCall.method == 'hasPermission') {
        return true;
      }
      return null;
    });

    final controller = RecorderController();
    final hasPermission = await controller.checkPermission();
    expect(hasPermission, isTrue);
  });
}
