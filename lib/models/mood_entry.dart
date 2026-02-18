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

  // ---- UI yardımcıları ----

  String get moodLabel {
    switch (mood) {
      case 1:
        return "Çok Kötü";
      case 2:
        return "Kötü";
      case 3:
        return "Orta";
      case 4:
        return "İyi";
      case 5:
        return "Harika";
      default:
        return "Bilinmiyor";
    }
  }

  String get moodEmoji {
    switch (mood) {
      case 1:
        return "😣";
      case 2:
        return "☹️";
      case 3:
        return "😐";
      case 4:
        return "🙂";
      case 5:
        return "😄";
      default:
        return "❓";
    }
  }

  bool get hasCards => selectedCardIds.isNotEmpty;
}
