import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'app.dart';
import 'providers/recorder.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();
  await container.read(recoderProvider).init();
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const App(),
    ),
  );
}
