/// stats/{gün} belgelerinden admin paneli için özet çıkarır.
/// Belgeler anonimdir: sadece sayı içerir (kimin yazdığı, notlar yok).
class StatsSummary {
  /// Günler eskiden yeniye: ("2026-10-14", kayıt sayısı)
  final List<({String day, int entries})> daily;

  /// Toplam mood dağılımı: 1..5 → kaç kayıt
  final Map<int, int> moodCounts;

  final int totalEntries;
  final int moodSum;

  const StatsSummary({
    required this.daily,
    required this.moodCounts,
    required this.totalEntries,
    required this.moodSum,
  });

  double get average => totalEntries == 0 ? 0 : moodSum / totalEntries;

  int get todayEntries => daily.isEmpty ? 0 : daily.last.entries;

  /// [days]: istenen gün kimlikleri (eskiden yeniye)
  /// [docs]: Firestore'dan gelenler; olmayan gün = 0 kayıt
  factory StatsSummary.from(List<String> days, Map<String, Map<String, dynamic>> docs) {
    int asInt(Object? v) => (v as num?)?.toInt() ?? 0;

    final daily = <({String day, int entries})>[];
    final moods = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    var total = 0;
    var sum = 0;

    for (final d in days) {
      final m = docs[d] ?? const {};
      // Silme/geri alma yüzünden eksiye düşmüş olabilir: 0'ın altını gösterme
      final n = asInt(m['entries']).clamp(0, 1 << 30);
      daily.add((day: d, entries: n));
      total += n;
      sum += asInt(m['moodSum']).clamp(0, 1 << 30);
      for (var k = 1; k <= 5; k++) {
        moods[k] = moods[k]! + asInt(m['m$k']).clamp(0, 1 << 30);
      }
    }

    return StatsSummary(daily: daily, moodCounts: moods, totalEntries: total, moodSum: sum);
  }
}
