import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

class AudioService {
  AudioService() {
    player = AudioPlayer()
      ..setAudioContext(
        const AudioContext(
          android: AudioContextAndroid(
            audioMode: AndroidAudioMode.inCommunication,
            usageType: AndroidUsageType.voiceCommunication,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playAndRecord,
          ),
        ),
      );
  }
  late AudioPlayer player;

  Future<void> play() async {
    String outputPath = '${(await getTemporaryDirectory()).path}/output.wav';
    final wavFile = File(outputPath);
    print(wavFile.statSync());
    await player.play(DeviceFileSource(outputPath));
  }
}
