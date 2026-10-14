import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/mood_entry.dart';

/// Mood kayıtlarını tutar ve telefonda kalıcı olarak saklar.
class MoodStore extends ChangeNotifier {
  static const _key = 'mood_entries';

  final List<MoodEntry> _items = [];

  /// dışarıdan sadece okunabilir liste (en yeni en başta)
  List<MoodEntry> get items => List.unmodifiable(_items);

  /// Uygulama açılırken kayıtları telefondan okur
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;

    final list = jsonDecode(raw) as List;
    _items
      ..clear()
      ..addAll(list.map((e) => MoodEntry.fromJson(e as Map<String, dynamic>)));
    _sort();
    notifyListeners();
  }

  /// Her değişiklikten sonra listeyi JSON olarak kaydeder
  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_items.map((e) => e.toJson()).toList()));
  }

  void _sort() => _items.sort((a, b) => b.date.compareTo(a.date));

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
    _save();
  }

  /// kayıt sil
  void remove(String id) {
    _items.removeWhere((e) => e.id == id);
    notifyListeners();
    _save();
  }

  /// silinen kaydı geri getir ("Geri al" butonu için)
  void restore(MoodEntry entry) {
    _items.add(entry);
    _sort();
    notifyListeners();
    _save();
  }

  List<MoodEntry> _lastDays(int days) {
    final from = DateTime.now().subtract(Duration(days: days));
    return _items.where((e) => e.date.isAfter(from)).toList();
  }

  /// son 7 gün için mood dağılımı
  Map<int, int> weeklyCount() {
    final map = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final e in _lastDays(7)) {
      map[e.mood] = (map[e.mood] ?? 0) + 1;
    }
    return map;
  }

  /// son 7 gün ortalaması
  double weeklyAverage() {
    final filtered = _lastDays(7);
    if (filtered.isEmpty) return 0;
    final sum = filtered.fold<int>(0, (a, b) => a + b.mood);
    return sum / filtered.length;
  }

  /// son eklenen kayıt
  MoodEntry? get latest => _items.isEmpty ? null : _items.first;

  /// her kartın kaç kez seçildiği
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
