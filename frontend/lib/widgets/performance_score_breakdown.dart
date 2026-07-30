import 'package:flutter/material.dart';

class PerformanceScoreBreakdown extends StatelessWidget {
  const PerformanceScoreBreakdown({super.key, required this.breakdown});

  final Map<String, dynamic> breakdown;

  @override
  Widget build(BuildContext context) {
    if (breakdown.isEmpty) {
      return const Text('No score breakdown is available.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: breakdown.entries.map((entry) {
        final item = entry.value is Map
            ? Map<String, dynamic>.from(entry.value as Map)
            : <String, dynamic>{};
        final score = _number(item['score']);
        final weight = _number(item['weight']);
        final contribution = _number(item['contribution']);
        final label = entry.key
            .split('_')
            .map(
              (part) => part.isEmpty
                  ? part
                  : '${part[0].toUpperCase()}${part.substring(1)}',
            )
            .join(' ');
        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$label: ${score.toStringAsFixed(2)} × '
                '${(weight * 100).toStringAsFixed(0)}% = '
                '${contribution.toStringAsFixed(2)}',
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(value: (score / 100).clamp(0, 1)),
            ],
          ),
        );
      }).toList(),
    );
  }

  static double _number(dynamic value) => double.tryParse('$value') ?? 0;
}
