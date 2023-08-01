import 'dart:typed_data';

import 'flutter_silero_vad_platform_interface.dart';

class FlutterSileroVad {
  Future<String?> initialize(
      {required Uint8List modelBytes,
      required int sampleRate,
      required int frameSize,
      required double threshold,
      required int minSilenceDurationMs,
      required int speechPadMs}) {
    return FlutterSileroVadPlatform.instance.initialize(
      modelBytes: modelBytes,
      sampleRate: sampleRate,
      frameSize: frameSize,
      threshold: threshold,
      minSilenceDurationMs: minSilenceDurationMs,
      speechPadMs: speechPadMs,
    );
  }

  Future<void> resetState() {
    return FlutterSileroVadPlatform.instance.resetState();
  }

  Future<bool?> predict(Float32List data) {
    return FlutterSileroVadPlatform.instance.predict(data);
  }
}
