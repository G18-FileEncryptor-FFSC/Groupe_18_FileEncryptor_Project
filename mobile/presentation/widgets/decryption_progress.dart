import 'package:flutter/material.dart';

class DecryptionProgress extends StatelessWidget {
  final double progress;

  const DecryptionProgress({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[300],
          color: Colors.blueAccent,
          minHeight: 10,
        ),
        const SizedBox(height: 8),
        Text(
          "${(progress * 100).toInt()}%",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
