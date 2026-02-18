import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../widgets/mood_card.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: moodStore,
      builder: (context, _) {
        final items = moodStore.items;

        if (items.isEmpty) {
          return const Center(child: Text("Henüz kayıt yok."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final e = items[i];
            return MoodCard(
              entry: e,
              onDelete: () {
                moodStore.remove(e.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Silindi 🗑️")),
                );
              },
            );
          },
        );
      },
    );
  }
}
