import 'package:flutter/material.dart';
import '../data/mood_store.dart';
import '../theme/app_theme.dart';
import '../widgets/mood_card.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return ListenableBuilder(
      listenable: moodStore,
      builder: (context, _) {
        final items = moodStore.items;

        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('☾', style: AppTheme.symbol(56, p.primary)),
                  const SizedBox(height: 16),
                  Text("Henüz kayıt yok",
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 6),
                  Text(
                    "İlk kaydını “Ekle” sekmesinden oluşturabilirsin.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: p.textSecondary),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final e = items[i];
            return MoodCard(
              entry: e,
              onDelete: () {
                moodStore.remove(e.id);
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: const Text("Kayıt silindi"),
                      action: SnackBarAction(
                        label: "Geri al",
                        onPressed: () => moodStore.restore(e),
                      ),
                    ),
                  );
              },
            );
          },
        );
      },
    );
  }
}
