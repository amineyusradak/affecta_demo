import 'package:flutter_test/flutter_test.dart';

import 'package:affecta_demo/models/mood_entry.dart';

void main() {
  test('MoodEntry JSON dönüşümü veriyi korur', () {
    final e = MoodEntry(
      id: '1',
      date: DateTime(2026, 10, 14, 9, 30),
      mood: 4,
      note: 'Sakin bir gün',
      selectedCardIds: ['breath', 'gratitude'],
    );

    final back = MoodEntry.fromJson(e.toJson());

    expect(back.id, e.id);
    expect(back.date, e.date);
    expect(back.mood, 4);
    expect(back.note, 'Sakin bir gün');
    expect(back.selectedCardIds, ['breath', 'gratitude']);
  });
}
