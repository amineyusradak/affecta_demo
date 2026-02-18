import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../data/reflection_cards.dart';
import '../widgets/reflection_pick_card.dart';

class AddMoodScreen extends StatefulWidget {
  const AddMoodScreen({super.key});

  @override
  State<AddMoodScreen> createState() => _AddMoodScreenState();
}

class _AddMoodScreenState extends State<AddMoodScreen> {
  double _mood = 3;
  final _note = TextEditingController();

  final Set<String> _selectedCards = {}; // max 3
  final ScrollController _cardsCtrl = ScrollController(); // ✅ Scrollbar fix

  @override
  void dispose() {
    _note.dispose();
    _cardsCtrl.dispose();
    super.dispose();
  }

  String get _emoji {
    final m = _mood.round();
    return switch (m) {
      1 => "😣",
      2 => "☹️",
      3 => "😐",
      4 => "🙂",
      5 => "😄",
      _ => "❓",
    };
  }

  String get _label {
    final m = _mood.round();
    return switch (m) {
      1 => "Çok Kötü",
      2 => "Kötü",
      3 => "Orta",
      4 => "İyi",
      5 => "Harika",
      _ => "Bilinmiyor",
    };
  }

  void _save() {
    moodStore.add(
      mood: _mood.round(),
      note: _note.text.trim(),
      selectedCardIds: _selectedCards.toList(),
    );

    _note.clear();
    _selectedCards.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Kaydedildi ✅")),
    );
    setState(() {});
  }

  void _toggleCard(String id) {
    setState(() {
      if (_selectedCards.contains(id)) {
        _selectedCards.remove(id);
        return;
      }
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
    return AnimatedBuilder(
      animation: moodStore,
      builder: (context, _) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            "$_emoji  $_label",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Duygu durumunu seç ve not ekle.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 14),
                          Slider(
                            value: _mood,
                            min: 1,
                            max: 5,
                            divisions: 4,
                            label: _label,
                            onChanged: (v) => setState(() => _mood = v),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _note,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: "Not (opsiyonel)",
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _save,
                            icon: const Icon(Icons.save_outlined),
                            label: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text("Kaydet"),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Toplam kayıt: ${moodStore.items.length}",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            "Farkındalık Kartı Seç (opsiyonel)",
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Bu kayıtla ilişkilendirmek için 0–3 kart seçebilirsin.",
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 10),

                          SizedBox(
                            height: 210,
                            child: Scrollbar(
                              controller: _cardsCtrl,
                              thumbVisibility: true,
                              child: ListView.separated(
                                controller: _cardsCtrl,
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                itemCount: reflectionCards.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 12),
                                itemBuilder: (context, i) {
                                  final c = reflectionCards[i];
                                  final isSel = _selectedCards.contains(c.id);

                                  return SizedBox(
                                    width: 170,
                                    child: ReflectionPickCard(
                                      card: c,
                                      selected: isSel,
                                      onTap: () => _toggleCard(c.id),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),
                          Text(
                            "Seçilen: ${_selectedCards.length}/3",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600),
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
}
