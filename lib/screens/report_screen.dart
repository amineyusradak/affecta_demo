import 'package:flutter/material.dart';
import '../data/mock_data.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: moodStore,
      builder: (context, _) {
        final avg = moodStore.weeklyAverage();
        final counts = moodStore.weeklyCount();
        final maxVal = _max(counts);

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.insights_outlined, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Son 7 gün ortalama mood: ${avg == 0 ? "-" : avg.toStringAsFixed(2)} / 5",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            "Son 7 gün dağılımı",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          for (int m = 1; m <= 5; m++)
                            _BarRow(
                              label: "$m",
                              value: counts[m] ?? 0,
                              max: maxVal,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  int _max(Map<int, int> map) {
    final values = map.values.toList();
    if (values.isEmpty) return 1;
    final mx = values.reduce((a, b) => a > b ? a : b);
    return mx == 0 ? 1 : mx;
  }
}

class _BarRow extends StatelessWidget {
  final String label;
  final int value;
  final int max;

  const _BarRow({
    required this.label,
    required this.value,
    required this.max,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = value / max;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 18, child: Text(label, textAlign: TextAlign.center)),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(width: 24, child: Text("$value")),
        ],
      ),
    );
  }
}
