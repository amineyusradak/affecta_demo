class MoodEntry {
  final String id;
  final DateTime date;
  final int mood; // 1–5
  final String note;

  /// Seçilen farkındalık kartlarının ID’leri
  final List<String> selectedCardIds;

  MoodEntry({
    required this.id,
    required this.date,
    required this.mood,
    required this.note,
    this.selectedCardIds = const [],
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
