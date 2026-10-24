import 'package:cloud_firestore/cloud_firestore.dart';

class MoodEntry {
  final String id;
  final DateTime date;
  final int mood; // 1–5
  final String note;

  /// Seçilen farkındalık kartlarının ID’leri
  final List<String> selectedCardIds;

  /// Not danışmanla paylaşılsın mı? Varsayılan: hayır (gizli)
  final bool shareNote;

  MoodEntry({
    required this.id,
    required this.date,
    required this.mood,
    required this.note,
    this.selectedCardIds = const [],
    this.shareNote = false,
  });

  // ---- Kalıcı kayıt için JSON dönüşümü ----

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'mood': mood,
        'note': note,
        'cards': selectedCardIds,
      };

  factory MoodEntry.fromJson(Map<String, dynamic> j) => MoodEntry(
        id: j['id'] as String,
        date: DateTime.parse(j['date'] as String),
        mood: j['mood'] as int,
        note: j['note'] as String? ?? '',
        selectedCardIds: List<String>.from(j['cards'] as List? ?? const []),
      );

  // ---- Firestore dönüşümü (tarih Timestamp olarak: sıralama ve sorgu için) ----

  Map<String, dynamic> toFirestore() => {
        'date': Timestamp.fromDate(date),
        'mood': mood,
        'note': note,
        'cards': selectedCardIds,
        'shareNote': shareNote,
      };

  factory MoodEntry.fromFirestore(String id, Map<String, dynamic> m) => MoodEntry(
        id: id,
        date: (m['date'] as Timestamp).toDate(),
        mood: m['mood'] as int,
        note: m['note'] as String? ?? '',
        selectedCardIds: List<String>.from(m['cards'] as List? ?? const []),
        shareNote: m['shareNote'] as bool? ?? false,
      );

  // ---- UI yardımcıları ----

  static String labelOf(int mood) => switch (mood) {
        1 => "Çok Kötü",
        2 => "Kötü",
        3 => "Orta",
        4 => "İyi",
        5 => "Harika",
        _ => "Bilinmiyor",
      };

  static String emojiOf(int mood) => switch (mood) {
        1 => "😣",
        2 => "☹️",
        3 => "😐",
        4 => "🙂",
        5 => "😄",
        _ => "❓",
      };

  String get moodLabel => labelOf(mood);
  String get moodEmoji => emojiOf(mood);

  bool get hasCards => selectedCardIds.isNotEmpty;
}
