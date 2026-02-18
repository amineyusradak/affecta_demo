import 'package:flutter/foundation.dart';
import '../models/mood_entry.dart';

class MoodStore extends ChangeNotifier {
  final List<MoodEntry> _items = [
    MoodEntry(
      id: "1",
      date: DateTime.now().subtract(const Duration(days: 1)),
      mood: 4,
      note: "Bugün daha sakindim.",
      selectedCardIds: ["kart_001", "kart_003"],
    ),
    MoodEntry(
      id: "2",
      date: DateTime.now().subtract(const Duration(days: 2)),
      mood: 2,
      note: "Biraz kaygılı bir gündü.",
      selectedCardIds: ["kart_005"],
    ),
    MoodEntry(
      id: "3",
      date: DateTime.now().subtract(const Duration(days: 3)),
      mood: 5,
      note: "Kendimi çok motive hissettim.",
      selectedCardIds: ["kart_004", "kart_006"],
    ),
  ];

  /// dışarıdan sadece okunabilir liste
  List<MoodEntry> get items => List.unmodifiable(_items);

  /// yeni mood kaydı ekle
  void add({
    required int mood,
    required String note,
    List<String> selectedCardIds = const [],
  }) {
    _items.insert(
      0,
      MoodEntry(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        date: DateTime.now(),
        mood: mood,
        note: note,
        selectedCardIds: selectedCardIds,
      ),
    );
    notifyListeners();
  }

  /// kayıt sil
  void remove(String id) {
    _items.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  /// son 7 gün için mood dağılımı
  Map<int, int> weeklyCount() {
    final now = DateTime.now();
    final last7 = now.subtract(const Duration(days: 7));
    final filtered = _items.where((e) => e.date.isAfter(last7)).toList();

    final map = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final e in filtered) {
      map[e.mood] = (map[e.mood] ?? 0) + 1;
    }
    return map;
  }

  /// son 7 gün ortalaması
  double weeklyAverage() {
    final now = DateTime.now();
    final last7 = now.subtract(const Duration(days: 7));
    final filtered = _items.where((e) => e.date.isAfter(last7)).toList();

    if (filtered.isEmpty) return 0;
    final sum = filtered.fold<int>(0, (a, b) => a + b.mood);
    return sum / filtered.length;
  }

  /// son eklenen kayıt
  MoodEntry? get latest {
    if (_items.isEmpty) return null;
    return _items.first;
  }

  /// seçilen kartları raporda kullanmak için (opsiyonel)
  Map<String, int> cardUsageCount() {
    final Map<String, int> map = {};
    for (final e in _items) {
      for (final c in e.selectedCardIds) {
        map[c] = (map[c] ?? 0) + 1;
      }
    }
    return map;
  }
}

final moodStore = MoodStore();
