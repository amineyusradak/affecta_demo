import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/mood_entry.dart';
import 'link_store.dart';

/// Mood kayıtlarını tutar ve buluta (Firestore) yedekler.
///
/// Kayıtlar users/{uid}/entries altında durur; yalnızca sahibi okuyabilir.
/// İnternet yokken de çalışır: Firestore yazılanları telefonda saklar,
/// bağlantı gelince kendiliğinden gönderir.
class MoodStore extends ChangeNotifier {
  /// Firebase öncesi telefonda tutulan eski kayıtlar (ilk girişte buluta taşınır)
  static const _legacyKey = 'mood_entries';

  final _db = FirebaseFirestore.instance;
  final List<MoodEntry> _items = [];
  StreamSubscription? _sub;
  String? _uid;

  /// dışarıdan sadece okunabilir liste (en yeni en başta)
  List<MoodEntry> get items => List.unmodifiable(_items);

  CollectionReference<Map<String, dynamic>> _entries(String uid) =>
      _db.collection('users/$uid/entries');

  /// Giriş yapan kullanıcıya bağlanır; null verilirse (çıkış) listeyi boşaltır.
  Future<void> bindUser(String? uid) async {
    if (uid == _uid) return;
    await _sub?.cancel();
    _uid = uid;
    _items.clear();
    notifyListeners();
    if (uid == null) return;

    await _migrateLegacy(uid);

    // Canlı dinle: başka telefondan eklenen kayıt da anında görünür
    _sub = _entries(uid).orderBy('date', descending: true).snapshots().listen(
      (snap) {
        _items
          ..clear()
          ..addAll(snap.docs.map((d) => MoodEntry.fromFirestore(d.id, d.data())));
        notifyListeners();
      },
      onError: (e) => debugPrint('Kayıtlar okunamadı: $e'),
    );
  }

  /// Telefonda kalan eski kayıtları bir kez buluta taşır
  Future<void> _migrateLegacy(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_legacyKey);
    if (raw == null) return;
    try {
      final batch = _db.batch();
      for (final e in jsonDecode(raw) as List) {
        final entry = MoodEntry.fromJson(e as Map<String, dynamic>);
        batch.set(_entries(uid).doc(entry.id), entry.toFirestore());
      }
      await batch.commit();
      await prefs.remove(_legacyKey);
    } catch (e) {
      debugPrint('Eski kayıtlar taşınamadı: $e');
    }
  }

  /// Anonim günlük istatistik (admin paneli için). Not veya kimlik içermez,
  /// sadece "o gün kaç kayıt, mood toplamı kaç" bilgisi.
  void _bumpStats(MoodEntry e, int delta) {
    _db.doc('stats/${statsDayId(e.date)}').set({
      'entries': FieldValue.increment(delta),
      'moodSum': FieldValue.increment(e.mood * delta),
      'm${e.mood}': FieldValue.increment(delta),
    }, SetOptions(merge: true)).catchError((e) => debugPrint('İstatistik yazılamadı: $e'));
  }

  /// yeni mood kaydı ekle
  void add({
    required int mood,
    required String note,
    List<String> selectedCardIds = const [],
    bool shareNote = false,
  }) {
    final uid = _uid;
    if (uid == null) return;
    final entry = MoodEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      date: DateTime.now(),
      mood: mood,
      note: note,
      selectedCardIds: selectedCardIds,
      shareNote: shareNote,
    );
    // await yok: Firestore yazıyı önce telefona işler, liste anında güncellenir
    _entries(uid).doc(entry.id).set(entry.toFirestore());
    _bumpStats(entry, 1);
    linkStore.syncEntry(entry); // danışmanla paylaşılıyorsa kopyasını gönder
  }

  /// Var olan bir kaydın notunu paylaş / gizle
  void setShareNote(MoodEntry e, bool share) {
    final uid = _uid;
    if (uid == null) return;
    _entries(uid).doc(e.id).update({'shareNote': share});
    linkStore.syncEntry(MoodEntry(
      id: e.id,
      date: e.date,
      mood: e.mood,
      note: e.note,
      selectedCardIds: e.selectedCardIds,
      shareNote: share,
    ));
  }

  /// kayıt sil
  void remove(String id) {
    final uid = _uid;
    if (uid == null) return;
    final entry = _items.where((e) => e.id == id).firstOrNull;
    _entries(uid).doc(id).delete();
    if (entry != null) _bumpStats(entry, -1);
    linkStore.removeEntry(id);
  }

  /// silinen kaydı geri getir ("Geri al" butonu için)
  void restore(MoodEntry entry) {
    final uid = _uid;
    if (uid == null) return;
    _entries(uid).doc(entry.id).set(entry.toFirestore());
    _bumpStats(entry, 1);
    linkStore.syncEntry(entry);
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

/// İstatistik belgesinin adı: "2026-10-20" (sıralanabilir olsun diye sıfırlı)
String statsDayId(DateTime d) =>
    "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

final moodStore = MoodStore();
