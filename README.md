# flutter_silero_vad

Silevo Voice Activity Detector (VAD) plugin wrapper for Flutter.

The flutter_silero_vad plugin is a robust solution for high-precision voice activity detection (VAD) in Flutter applications. Designed for easy integration using Swift and Kotlin, it leverages the Silero VAD model to accurately distinguish between speech and non-speech segments. This plugin is especially beneficial in noisy environments or for applications requiring real-time audio processing

## How it works
This plugin simply calls the Silero VAD onnx model using Swift and Kotlin. 
The `FlutterSileroVad` class has only three methods: `initialize`, `resetState`, and `predict`.

For the `initialize` method, the arguments are as follows:
- `modelPath`: The path to the Silero VAD onnx model.
- `sampleRate`: The sample rate of the audio file you want to detect.
- `frameSize`: The size of the segment to detect (Silero VAD is trained with 30ms).
- `threshold`
- `minSilenceDurationMs`: After it becomes silent, this duration will be included in the detection segment.
- `speechPadMs`: Currently not in use.

About `resetState`: Since Silero VAD is an RNN, the model has a state. Calling `resetState` will reset the model's state.

The `predict` method takes a segment of monaural audio data and determines whether or not the segment contains voice.

**Step 1**
Add `flutter_silero_vad` to your `pubspec.yaml`.
```pubspec.yaml
  flutter_silero_vad:
    git:
      url: https://github.com/char5742/flutter_silero_vad.git
```

**Step 2**
Place the Silero VAD onnx [model](https://github.com/snakers4/silero-vad/tree/master/files) in the assets.

**Step 3**:
```dart
final vad = FlutterSileroVad ();
// In Flutter, assets cannot be operated on directly from native, so if you want to use an asset, you first have to copy it locally.
onnxModelToLocal(modelPath); 
await vad.initialize(
 modelPath: modelPath,
 ...
);
final audioBuffer = Float32List(frameSize * sampleRate  / 1000); // ms
final isActive = await vad.predict(audioBuffer);
```
```dart
  Future<void> onnxModelToLocal(String modelPath) async {
    final data = await rootBundle.load('assets/silero_vad.onnx');
    final bytes =
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    File(await modelPath).writeAsBytesSync(bytes);
  }
```


## License
This project uses the following open-source packages:
- [silero-vad](https://github.com/snakers4/silero-vad) which is licensed under the [MIT License](https://github.com/snakers4/silero-vad/blob/master/LICENSE).
