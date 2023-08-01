import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

class AudioService {
  AudioService() {
    player = AudioPlayer()
      ..setAudioContext(
        const AudioContext(
          android: AudioContextAndroid(
            audioMode: AndroidAudioMode.inCommunication,
          ),
        ),
      );
  }
  late AudioPlayer player;

  Future<void> play() async {
    String outputPath = '${(await getTemporaryDirectory()).path}/output.wav';
    await player.setSourceDeviceFile(outputPath);
    await player.resume();
  }
}
