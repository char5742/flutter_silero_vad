import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'generated_bindings.dart';

class FlutterSileroVad {
  final _library = SileroVadLibrary(DynamicLibrary.open('libsilero_vad.so'));
  Pointer<Void>? handle;
  bool isInitialized = false;
  void initialize({
    required String modelPath,
    required int sampleRate,
    required int frameSize,
    required double threshold,
    required int minSilenceDurationMs,
    required int speechPadMs,
  }) {
    final modelPathPtr = modelPath.toNativeUtf8();
    handle = _library.create_vad(
      modelPathPtr.cast<Char>(),
      sampleRate,
      frameSize,
      threshold,
      minSilenceDurationMs,
      speechPadMs,
    );
    malloc.free(modelPathPtr);
    isInitialized = true;
  }

  void dispose() {
    assert(isInitialized);
    _library.destroy_vad(handle!);
    isInitialized = false;
  }

  bool predict(Int16List data) {
    assert(isInitialized);
    final dataPtr = malloc<Float>(data.length);
    for (var i = 0; i < data.length; i++) {
      // 16bit signed int to float
      dataPtr[i] = data[i].toDouble() / 32768.0;
    }
    final res = _library.predict(
      handle!,
      dataPtr,
      data.length,
    );
    malloc.free(dataPtr);
    return res == 1;
  }
}
