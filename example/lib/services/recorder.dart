import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:audio_session/audio_session.dart';
import 'package:audio_streamer/audio_streamer.dart';
import 'package:flutter/services.dart';
import 'package:flutter_silero_vad/flutter_silero_vad.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class RecorderService {
  final recorder = AudioStreamer.instance;
  final vad = FlutterSileroVad();
  Future<String> get modelPath async =>
      '${(await getApplicationSupportDirectory()).path}/silero_vad.v5.onnx';
  final sampleRate = 16000;
  final frameSize = 40; // 80ms

  /// サンプルあたりのビット数
  final int bitsPerSample = 16;

  /// チャンネル数
  final int numChannels = 1;

  bool isInited = false;

  /// 直前の音声データを保存するための変数
  final lastAudioData = <int>[];

  /// 発声が止まってから数秒後に音声データを保存するための変数
  DateTime? lastActiveTime;
  final processedAudioStreamController =
      StreamController<List<int>>.broadcast();
  StreamSubscription<List<int>>? recordingDataSubscription;
  StreamSubscription<List<int>>? processedAudioSubscription;

  final frameBuffer = <int>[];

  Future<void> init() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw Exception('Microphone permission not granted');
    }
    final session = await AudioSession.instance;
    await session.configure(
      AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.allowBluetooth |
                AVAudioSessionCategoryOptions.defaultToSpeaker,
        // iOSは voiceChat にすることで、エコーキャンセリングが有効になる
        avAudioSessionMode: AVAudioSessionMode.voiceChat,
        avAudioSessionRouteSharingPolicy:
            AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          usage: AndroidAudioUsage.voiceCommunication,
        ),
        androidWillPauseWhenDucked: true,
      ),
    );
    isInited = true;
  }

  Future<void> record(StreamController<List<int>> controller) async {
    assert(isInited);

    await recorder.startRecording();
    await onnxModelToLocal();
    await vad.initialize(
      modelPath: await modelPath,
      sampleRate: sampleRate,
      frameSize: frameSize,
      threshold: 0.7,
      minSilenceDurationMs: 100,
      speechPadMs: 0,
    );
    recordingDataSubscription = recorder.audioStream.listen((buffer) async {
      final data = _transformBuffer(buffer);
      if (data.isEmpty) return;
      frameBuffer.addAll(buffer);
      while (frameBuffer.length >= frameSize * 2 * sampleRate ~/ 1000) {
        final b = frameBuffer.take(frameSize * 2 * sampleRate ~/ 1000).toList();
        frameBuffer.removeRange(0, frameSize * 2 * sampleRate ~/ 1000);
        await _handleProcessedAudio(b);
      }
      controller.add(data);
    });

    processedAudioSubscription =
        processedAudioStreamController.stream.listen((buffer) async {
      final outputPath =
          '${(await getApplicationDocumentsDirectory()).path}/output.wav';
      saveAsWav(buffer, outputPath);
      print('saved');
    });
  }

  Future<void> stopRecorder() async {
    await recorder.startRecording();
    if (recordingDataSubscription != null) {
      await recordingDataSubscription?.cancel();
      recordingDataSubscription = null;
      await processedAudioSubscription?.cancel();
      processedAudioSubscription = null;
    }
  }

  Int16List _transformBuffer(List<int> buffer) {
    final bytes = Uint8List.fromList(buffer);
    return Int16List.view(bytes.buffer);
  }

  void printVolume(List<int> data) {
    // PCMデータは16ビット（2バイト）なので、2バイト単位で処理します。
    var sum = 0.0;
    for (var i = 0; i < data.length; i += 2) {
      final int16 = data[i] + (data[i + 1] << 8); // PCM 16ビットデータ
      final sample = int16 / (1 << 15); // -1から1までの範囲に正規化
      sum += sample * sample; // 二乗和を計算
    }

    final rms = sqrt(sum / (data.length / 2)); // RMSを計算
    final volume = 20 * log(rms) / ln10; // デシベルに変換

    print('Volume: $volume dB');
  }

  static const threshold = 900; // このしきい値は音声レベルにより調整が必要
  static const bufferTimeInMilliseconds = 700;
  final audioDataBuffer = <int>[];

  Future<void> _handleProcessedAudio(List<int> buffer) async {
    final transformedBuffer = _transformBuffer(buffer);
    final transformedBufferFloat =
        transformedBuffer.map((e) => e / 32768).toList();

    final isActivated =
        await vad.predict(Float32List.fromList(transformedBufferFloat));
    print(isActivated);
    if (isActivated == true) {
      lastActiveTime = DateTime.now();
      audioDataBuffer.addAll(lastAudioData);
      lastAudioData.clear();
      audioDataBuffer.addAll(buffer);
    } else if (lastActiveTime != null) {
      audioDataBuffer.addAll(buffer);
      print(DateTime.now().difference(lastActiveTime!));
      // 一定時間経過したら音声データを保存する
      if (DateTime.now().difference(lastActiveTime!) >
          const Duration(milliseconds: bufferTimeInMilliseconds)) {
        processedAudioStreamController.add([...audioDataBuffer]);
        audioDataBuffer.clear();
        lastActiveTime = null;
      }
    } else {
      lastAudioData.addAll(buffer);
      // 5秒分のデータを保存しておく
      final threshold = sampleRate * 500 ~/ 1000;
      if (lastAudioData.length > threshold) {
        lastAudioData.removeRange(0, lastAudioData.length - threshold);
      }
    }
  }

  void saveAsWav(List<int> buffer, String filePath) {
    // PCMデータの変換
    final bytes = Uint8List.fromList(buffer);
    final pcmData = Int16List.view(bytes.buffer);
    final byteBuffer = ByteData(pcmData.length * 2);

    for (var i = 0; i < pcmData.length; i++) {
      byteBuffer.setInt16(i * 2, pcmData[i], Endian.little);
    }

    final wavHeader = ByteData(44);
    final pcmBytes = byteBuffer.buffer.asUint8List();

    // RIFFチャンク
    wavHeader
      ..setUint8(0x00, 0x52) // 'R'
      ..setUint8(0x01, 0x49) // 'I'
      ..setUint8(0x02, 0x46) // 'F'
      ..setUint8(0x03, 0x46) // 'F'
      ..setUint32(4, 36 + pcmBytes.length, Endian.little) // ChunkSize
      ..setUint8(0x08, 0x57) // 'W'
      ..setUint8(0x09, 0x41) // 'A'
      ..setUint8(0x0A, 0x56) // 'V'
      ..setUint8(0x0B, 0x45) // 'E'
      ..setUint8(0x0C, 0x66) // 'f'
      ..setUint8(0x0D, 0x6D) // 'm'
      ..setUint8(0x0E, 0x74) // 't'
      ..setUint8(0x0F, 0x20) // ' '
      ..setUint32(16, 16, Endian.little) // Subchunk1Size
      ..setUint16(20, 1, Endian.little) // AudioFormat
      ..setUint16(22, numChannels, Endian.little) // NumChannels
      ..setUint32(24, sampleRate, Endian.little) // SampleRate
      ..setUint32(
        28,
        sampleRate * numChannels * bitsPerSample ~/ 8,
        Endian.little,
      ) // ByteRate
      ..setUint16(
        32,
        numChannels * bitsPerSample ~/ 8,
        Endian.little,
      ) // BlockAlign
      ..setUint16(34, bitsPerSample, Endian.little) // BitsPerSample

      // dataチャンク
      ..setUint8(0x24, 0x64) // 'd'
      ..setUint8(0x25, 0x61) // 'a'
      ..setUint8(0x26, 0x74) // 't'
      ..setUint8(0x27, 0x61) // 'a'
      ..setUint32(40, pcmBytes.length, Endian.little); // Subchunk2Size

    File(filePath).writeAsBytesSync(wavHeader.buffer.asUint8List() + pcmBytes);
  }

  /// アセットからアプリケーションディレクトリにファイルをコピーする
  Future<void> onnxModelToLocal() async {
    final data = await rootBundle.load('assets/silero_vad.v5.onnx');
    final bytes =
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    File(await modelPath).writeAsBytesSync(bytes);
  }
}
