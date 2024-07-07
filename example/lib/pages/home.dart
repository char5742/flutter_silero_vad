import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_silero_vad_example/providers/audio.dart';
import 'package:flutter_silero_vad_example/providers/recorder.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'components.dart';

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useStreamController<List<int>>();
    final spots = useState<List<int>>([]);
    useOnAppLifecycleStateChange((beforeState, currState) {
      if (currState == AppLifecycleState.resumed) {
        ref.read(recoderProvider).record(controller);
      } else if (currState == AppLifecycleState.paused) {
        ref.read(recoderProvider).stopRecorder();
      }
    });
    useEffect(
      () {
        ref
            .read(recoderProvider)
            .init()
            .then((value) => ref.read(recoderProvider).record(controller));
        final subscription = controller.stream.listen((event) {
          final buffer = event.toList();
          spots.value = buffer;
        });
        return subscription.cancel;
      },
      [],
    );
    return Scaffold(
      body: Column(
        children: [
          Waveform(audioData: spots.value),
          ElevatedButton(
            onPressed: () async {
              await ref.read(audioServiceProvider).play();
              await ref.read(recoderProvider).vad.resetState();
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }
}
