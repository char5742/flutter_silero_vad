import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

class AudioService {
  AudioService() {
    player = AudioPlayer()
      ..setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
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
    final outputPath =
        '${(await getApplicationDocumentsDirectory()).path}/output.wav';
    await player.play(DeviceFileSource(outputPath));
  }
}
