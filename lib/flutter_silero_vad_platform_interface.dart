import 'dart:typed_data';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_silero_vad_method_channel.dart';

abstract class FlutterSileroVadPlatform extends PlatformInterface {
  /// Constructs a FlutterSileroVadPlatform.
  FlutterSileroVadPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterSileroVadPlatform _instance = MethodChannelFlutterSileroVad();

  /// The default instance of [FlutterSileroVadPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterSileroVad].
  static FlutterSileroVadPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterSileroVadPlatform] when
  /// they register themselves.
  static set instance(FlutterSileroVadPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> initialize({
    required String modelPath,
    required int sampleRate,
    required int frameSize,
    required double threshold,
    required int minSilenceDurationMs,
    required int speechPadMs,
  }) {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  Future<void> resetState() {
    throw UnimplementedError('resetState() has not been implemented.');
  }

  Future<bool?> predict(Float32List data) {
    throw UnimplementedError('predict() has not been implemented.');
  }
}
