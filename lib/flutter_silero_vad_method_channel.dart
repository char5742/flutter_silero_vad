import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_silero_vad_platform_interface.dart';

/// An implementation of [FlutterSileroVadPlatform] that uses method channels.
class MethodChannelFlutterSileroVad extends FlutterSileroVadPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_silero_vad');

  @override
  Future<String?> initialize({
    required String modelPath,
    required int sampleRate,
    required int frameSize,
    required double threshold,
    required int minSilenceDurationMs,
    required int speechPadMs,
  }) async {
    final res = await methodChannel.invokeMethod<String>('initialize', {
      'modelPath': modelPath,
      'sampleRate': sampleRate,
      'frameSize': frameSize,
      'threshold': threshold,
      'minSilenceDurationMs': minSilenceDurationMs,
      'speechPadMs': speechPadMs,
    });
    return res;
  }

  @override
  Future<void> resetState() async {
    await methodChannel.invokeMethod<void>('resetState');
  }

  @override
  Future<bool?> predict(Float32List data) async {
    final res = await methodChannel.invokeMethod<bool>(
      'predict',
      {'data': data},
    );
    return res;
  }
}
