import 'package:flutter/material.dart';

import '../data/mood_store.dart';
import '../data/reflection_cards.dart';
import '../models/mood_entry.dart';
import '../theme/app_theme.dart';
import '../widgets/premium.dart';
import '../widgets/reflection_pick_card.dart';

const _months = [
  'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
  'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
];
const _weekdays = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];

class AddMoodScreen extends StatefulWidget {
  const AddMoodScreen({super.key});

  @override
  State<AddMoodScreen> createState() => _AddMoodScreenState();
}

class _AddMoodScreenState extends State<AddMoodScreen> {
  int _mood = 3;
  final _note = TextEditingController();
  final Set<String> _selectedCards = {}; // max 3

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _save() {
    moodStore.add(
      mood: _mood,
      note: _note.text.trim(),
      selectedCardIds: _selectedCards.toList(),
    );

    _note.clear();
    FocusScope.of(context).unfocus();
    setState(() {
      _selectedCards.clear();
      _mood = 3;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Kaydedildi ✨ Kendine zaman ayırdığın için teşekkürler.")),
    );
  }

  void _toggleCard(String id) {
    setState(() {
      if (_selectedCards.remove(id)) return; // zaten seçiliyse kaldır
      if (_selectedCards.length >= 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("En fazla 3 kart seçebilirsin.")),
        );
        return;
      }
      _selectedCards.add(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final now = DateTime.now();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        // ---- Karşılama ----
        Text(
          "${now.day} ${_months[now.month - 1]}, ${_weekdays[now.weekday - 1]}",
          style: TextStyle(color: p.textSecondary, letterSpacing: 0.5),
        ),
        const SizedBox(height: 4),
        Text("Bugün nasılsın?", style: text.headlineMedium),
        const SizedBox(height: 20),

        // ---- Mood seçimi ----
        SoftCard(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (int m = 1; m <= 5; m++)
                    _MoodBubble(
                      mood: m,
                      selected: _mood == m,
                      onTap: () => setState(() => _mood = m),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  MoodEntry.labelOf(_mood),
                  key: ValueKey(_mood),
                  style: AppTheme.serif(26, context.ink(AppColors.mood(_mood)), FontWeight.w700),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _note,
                maxLines: 3,
                minLines: 2,
                decoration: const InputDecoration(
                  hintText: "Aklından geçenleri yaz… (opsiyonel)",
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // ---- Kart seçimi ----
        const SectionTitle(
          "Kartını seç",
          subtitle: "0–3 kart seçebilirsin · Mesajını okumak için karta uzun bas",
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 260,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: reflectionCards.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final c = reflectionCards[i];
              return SizedBox(
                width: 165,
                child: ReflectionPickCard(
                  card: c,
                  selected: _selectedCards.contains(c.id),
                  onTap: () => _toggleCard(c.id),
                  onLongPress: () => showCardPrompt(context, c),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            "Seçilen: ${_selectedCards.length}/3",
            style: TextStyle(color: p.textSecondary),
          ),
        ),
        const SizedBox(height: 24),

        GradientButton(
          label: "Kaydet",
          icon: Icons.auto_awesome,
          onPressed: _save,
        ),
      ],
    );
  }
}

/// Pastel daire içinde mood emojisi; seçilince büyür ve renklenir.
class _MoodBubble extends StatelessWidget {
  final int mood;
  final bool selected;
  final VoidCallback onTap;

  const _MoodBubble({required this.mood, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.mood(mood);
    return GestureDetector(
      onTap: onTap,
      // Yaylanan büyüme sadece ölçekte: ölçeğin hedefi aşması zararsız
      child: AnimatedScale(
        scale: selected ? 1.0 : 0.8,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutBack,
        // Renk ve gölge yaylanmadan değişir; aksi halde gölge
        // bulanıklığı eksiye düşüp hata verir
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          width: 60,
          height: 60,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? color : color.withValues(alpha: 0.3),
            border: Border.all(
              color: selected ? context.ink(color) : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: selected ? 0.7 : 0),
                blurRadius: 18,
              ),
            ],
          ),
          child: Text(
            MoodEntry.emojiOf(mood),
            style: const TextStyle(fontSize: 30),
          ),
        ),
      ),
    );
  }
}
