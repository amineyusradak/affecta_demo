import 'package:flutter/material.dart';
import '../data/mood_store.dart';
import '../data/reflection_cards.dart';
import '../models/mood_entry.dart';
import '../theme/app_theme.dart';
import '../widgets/premium.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return ListenableBuilder(
      listenable: moodStore,
      builder: (context, _) {
        final avg = moodStore.weeklyAverage();
        final counts = moodStore.weeklyCount();
        final maxVal = counts.values.fold<int>(1, (a, b) => b > a ? b : a);
        final avgMood = avg == 0 ? 0 : avg.round();

        // En çok seçilen 3 kart
        final usage = moodStore.cardUsageCount().entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final topCards = usage.take(3).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            // ---- Haftalık ortalama ----
            SoftCard(
              child: Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: avgMood == 0
                          ? p.surfaceHigh
                          : AppColors.mood(avgMood).withValues(alpha: 0.6),
                    ),
                    child: Text(
                      avgMood == 0 ? '–' : MoodEntry.emojiOf(avgMood),
                      style: const TextStyle(fontSize: 34),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Son 7 gün", style: TextStyle(color: p.textSecondary)),
                        Text(
                          avg == 0 ? "Veri yok" : "${avg.toStringAsFixed(1)} / 5",
                          style: AppTheme.serif(36, p.textPrimary, FontWeight.w700),
                        ),
                        if (avgMood != 0)
                          Text("Genel olarak “${MoodEntry.labelOf(avgMood)}”",
                              style: TextStyle(color: p.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ---- Dağılım ----
            const SectionTitle("Duygu dağılımı", subtitle: "Son 7 günde kaç kez hangi duygu"),
            const SizedBox(height: 12),
            SoftCard(
              child: Column(
                children: [
                  for (int m = 5; m >= 1; m--)
                    _BarRow(mood: m, value: counts[m] ?? 0, max: maxVal),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ---- En çok seçilen kartlar ----
            const SectionTitle("Sana eşlik eden kartlar", subtitle: "En sık seçtiğin kartlar"),
            const SizedBox(height: 12),
            if (topCards.isEmpty)
              SoftCard(
                child: Text("Henüz kart seçmedin.", style: TextStyle(color: p.textSecondary)),
              )
            else
              for (final e in topCards)
                if (cardById(e.key) case final c?)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SoftCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: c.accent.withValues(alpha: 0.45),
                            ),
                            child: Text(c.symbol,
                                style: AppTheme.symbol(22, context.ink(c.accent))),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(c.title,
                                style: AppTheme.serif(20, p.textPrimary, FontWeight.w700)),
                          ),
                          Text("${e.value}×",
                              style: TextStyle(
                                  fontWeight: FontWeight.w800, color: p.textSecondary)),
                        ],
                      ),
                    ),
                  ),
          ],
        );
      },
    );
  }
}

class _BarRow extends StatelessWidget {
  final int mood;
  final int value;
  final int max;

  const _BarRow({required this.mood, required this.value, required this.max});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = AppColors.mood(mood);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Text(MoodEntry.emojiOf(mood), style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  Container(height: 14, color: color.withValues(alpha: 0.2)),
                  // Animasyonlu dolum çubuğu
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: value / max),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, _) => FractionallySizedBox(
                      widthFactor: v,
                      child: Container(height: 14, color: color),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 22,
            child: Text("$value",
                textAlign: TextAlign.end,
                style: TextStyle(fontWeight: FontWeight.w700, color: p.textSecondary)),
          ),
        ],
      ),
    );
  }
}
