import 'package:flutter/material.dart';

class WaveformPainter extends CustomPainter {
  WaveformPainter({required this.audioData, this.color = Colors.blue});
  final List<int> audioData;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (audioData.isEmpty) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    final stepSize = audioData.length / size.width;

    for (var i = 0; i < size.width; ++i) {
      final sampleIndex = (i * stepSize).toInt();
      final sample = audioData[sampleIndex];

      // Scale the vertical coordinate by the sample value.
      final normSample = sample / (1 << 16);
      final y = (1 - normSample) * size.height / 2;

      if (i == 0) {
        path.moveTo(i.toDouble(), y);
      } else {
        path.lineTo(i.toDouble(), y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.audioData != audioData;
  }
}

class Waveform extends StatelessWidget {
  const Waveform({
    super.key,
    required this.audioData,
    this.color = Colors.blue,
  });
  final List<int> audioData;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: WaveformPainter(audioData: audioData, color: color),
      size: const Size(1000, 500),
    );
  }
}
