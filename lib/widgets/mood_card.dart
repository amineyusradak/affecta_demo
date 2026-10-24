import 'package:flutter/material.dart';
import '../data/link_store.dart';
import '../data/mood_store.dart';
import '../data/reflection_cards.dart';
import '../models/mood_entry.dart';
import '../models/reflection_card.dart';
import '../theme/app_theme.dart';
import 'reflection_pick_card.dart';

class MoodCard extends StatelessWidget {
  final MoodEntry entry;
  final VoidCallback onDelete;

  const MoodCard({
    super.key,
    required this.entry,
    required this.onDelete,
  });

  String _dateText(DateTime d) {
    String two(int x) => x.toString().padLeft(2, '0');
    return "${two(d.day)}.${two(d.month)}.${d.year} · ${two(d.hour)}:${two(d.minute)}";
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final moodColor = AppColors.mood(entry.mood);

    // Kayıttaki ID'lere karşılık gelen kartları bul
    final cards = entry.selectedCardIds.map(cardById).whereType<ReflectionCard>().toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: p.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: p.border),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sol kenarda mood renginde şerit
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: moodColor,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(24)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: moodColor.withValues(alpha: 0.5),
                          ),
                          child: Text(entry.moodEmoji, style: const TextStyle(fontSize: 22)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(entry.moodLabel,
                                  style: AppTheme.serif(22, p.textPrimary, FontWeight.w700)),
                              Text(_dateText(entry.date),
                                  style: TextStyle(color: p.textSecondary, fontSize: 12)),
                            ],
                          ),
                        ),
                        // Notu danışmanla paylaş / gizle (sadece danışmana bağlıysa)
                        if (entry.note.isNotEmpty && linkStore.links.any((l) => l.shareMood))
                          IconButton(
                            tooltip: entry.shareNote ? "Not paylaşılıyor · gizle" : "Not gizli · danışmanımla paylaş",
                            icon: Icon(
                              entry.shareNote ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                              color: entry.shareNote ? p.primary : p.textSecondary,
                            ),
                            onPressed: () {
                              moodStore.setShareNote(entry, !entry.shareNote);
                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(SnackBar(
                                  content: Text(entry.shareNote
                                      ? "Not artık gizli 🔒"
                                      : "Not danışmanınla paylaşıldı"),
                                ));
                            },
                          ),
                        IconButton(
                          tooltip: "Sil",
                          icon: Icon(Icons.delete_outline_rounded, color: p.textSecondary),
                          onPressed: onDelete,
                        ),
                      ],
                    ),
                    if (entry.note.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(entry.note, style: TextStyle(height: 1.4, color: p.textPrimary)),
                    ],
                    if (cards.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final c in cards)
                            InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => showCardPrompt(context, c),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: c.accent.withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(c.symbol,
                                        style: AppTheme.symbol(14, context.ink(c.accent))),
                                    const SizedBox(width: 6),
                                    Text(c.title,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: p.textPrimary,
                                        )),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
