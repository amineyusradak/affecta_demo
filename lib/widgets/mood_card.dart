import 'package:flutter/material.dart';
import '../models/mood_entry.dart';

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
    return "${two(d.day)}.${two(d.month)}.${d.year}  ${two(d.hour)}:${two(d.minute)}";
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: ListTile(
        leading: Text(entry.moodEmoji, style: const TextStyle(fontSize: 28)),
        title: Text("${entry.moodLabel} • ${_dateText(entry.date)}"),
        subtitle: Text(entry.note.isEmpty ? "Not yok" : entry.note),
        trailing: IconButton(
          tooltip: "Sil",
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
