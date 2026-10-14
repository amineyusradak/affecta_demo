import '../models/mood_entry.dart';
import '../models/quote.dart';

/// Günün sözü + neden seçildiği.
class DailyQuote {
  final String text;
  final String? author;
  final Feeling feeling;
  final String reason;

  /// Notlarda kendine zarar verme ifadesi bulunduysa true:
  /// arayüz söz yerine destek bilgisi göstermeli.
  final bool needsSupport;

  const DailyQuote({
    required this.text,
    this.author,
    required this.feeling,
    required this.reason,
    this.needsSupport = false,
  });
}

/// Basit, kurallara dayalı Türkçe duygu analizi (internetsiz çalışır).
///
/// 1) Notları normalleştirir (küçük harf, Türkçe karakterleri sadeleştirir)
/// 2) Kelime köklerini duygu sözlüğüyle eşleştirir
/// 3) Mood puanı ve seçilen kartlardan ek puan verir
/// 4) En yüksek puanlı duygunun havuzundan günün sözünü seçer
class QuoteEngine {
  /// Duygu sözlüğü: kelime kökü → duygu (kökler sadeleştirilmiş yazılır)
  static const Map<Feeling, List<String>> lexicon = {
    Feeling.anxiety: ['kayg', 'endise', 'kork', 'panik', 'gergin', 'tedirgin', 'huzursuz'],
    Feeling.sadness: ['uzgun', 'uzul', 'mutsuz', 'agla', 'kirgin', 'huzun', 'moral', 'kotu'],
    Feeling.tired: ['yorgun', 'yorul', 'bitkin', 'uykusuz', 'tuken', 'halsiz'],
    Feeling.anger: ['sinir', 'ofke', 'kizgin', 'kizdim', 'nefret'],
    Feeling.lonely: ['yalniz', 'kimse', 'dislan'],
    Feeling.stress: ['stres', 'sinav', 'yetis', 'baski', 'yogun', 'deadline', 'proje'],
    Feeling.happy: ['mutlu', 'harika', 'guzel', 'sevinc', 'keyif', 'huzurlu', 'hafif', 'iyi'],
    Feeling.motivation: ['hedef', 'basar', 'motive', 'calis', 'plan'],
  };

  /// Kendine zarar verme işaretleri (sadeleştirilmiş metinde aranır)
  static const List<String> supportPhrases = [
    'intihar',
    'kendimi oldur',
    'olmek istiyorum',
    'yasamak istemiyorum',
    'kendime zarar',
    'canima kiy',
    'yasamanin anlami yok',
  ];

  /// Kartların hangi duyguya iyi geldiği
  static const Map<String, Feeling> cardFeelings = {
    'breath': Feeling.calm,
    'boundary': Feeling.stress,
    'self_compassion': Feeling.sadness,
    'focus': Feeling.motivation,
    'reality_check': Feeling.anxiety,
    'gratitude': Feeling.happy,
    'body_scan': Feeling.tired,
    'release': Feeling.anger,
    'tiny_step': Feeling.motivation,
    'acceptance': Feeling.sadness,
  };

  /// "Bugün KAYGILI hissettim" → "bugun kaygili hissettim"
  static String normalize(String s) {
    const map = {'ç': 'c', 'ğ': 'g', 'ı': 'i', 'ö': 'o', 'ş': 's', 'ü': 'u', '̇': ''};
    final lower = s.replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase();
    final buf = StringBuffer();
    for (final ch in lower.split('')) {
      buf.write(map[ch] ?? ch);
    }
    return buf.toString();
  }

  /// Bir metindeki duyguları sayar. "mutlu degilim" gibi
  /// olumsuzlamalarda mutluluk yerine hüzün sayılır.
  static Map<Feeling, int> analyzeText(String text) {
    final words = normalize(text)
        .split(RegExp(r'[^a-z]+'))
        .where((w) => w.isNotEmpty)
        .toList();
    final scores = <Feeling, int>{};

    for (var i = 0; i < words.length; i++) {
      final w = words[i];
      final negated = i + 1 < words.length && words[i + 1].startsWith('degil');

      for (final entry in lexicon.entries) {
        if (entry.value.any(w.startsWith)) {
          var f = entry.key;
          if (negated && f == Feeling.happy) f = Feeling.sadness;
          scores[f] = (scores[f] ?? 0) + 1;
        }
      }
    }
    return scores;
  }

  static bool needsSupport(String text) {
    final t = normalize(text);
    return supportPhrases.any(t.contains);
  }

  /// Son 3 günün kayıtlarına bakarak [library] içinden günün sözünü seçer.
  static DailyQuote pick(List<MoodEntry> entries, List<Quote> library, {DateTime? now}) {
    now ??= DateTime.now();
    final from = now.subtract(const Duration(days: 3));
    final recent = entries.where((e) => e.date.isAfter(from)).take(5).toList();

    // Güvenlik: riskli ifade varsa önce destek
    if (recent.any((e) => needsSupport(e.note))) {
      return const DailyQuote(
        text: 'Bu duyguları tek başına taşımak zorunda değilsin.',
        feeling: Feeling.sadness,
        reason: 'Son notların zor bir dönemden geçtiğini düşündürüyor.',
        needsSupport: true,
      );
    }

    final scores = <Feeling, int>{};
    void add(Feeling f, int p) => scores[f] = (scores[f] ?? 0) + p;

    for (final e in recent) {
      // Notlardaki kelimeler en güçlü sinyal: her eşleşme 2 puan
      analyzeText(e.note).forEach((f, n) => add(f, n * 2));
      // Mood puanı
      if (e.mood <= 2) add(Feeling.sadness, 1);
      if (e.mood >= 4) add(Feeling.happy, 1);
      // Seçilen kartlar
      for (final id in e.selectedCardIds) {
        final f = cardFeelings[id];
        if (f != null) add(f, 1);
      }
    }

    Feeling feeling = Feeling.calm;
    var best = 0;
    // Eşitlikte enum sırası kazanır: zor duygular önce gelir
    for (final f in Feeling.values) {
      final s = scores[f] ?? 0;
      if (s > best) {
        best = s;
        feeling = f;
      }
    }

    // Bu duyguya uygun sözler; yoksa denge sözleri, o da yoksa hepsi
    var pool = library.where((q) => q.feelings.contains(feeling)).toList();
    if (pool.isEmpty) {
      feeling = Feeling.calm;
      best = 0;
      pool = library.where((q) => q.feelings.contains(Feeling.calm)).toList();
    }
    if (pool.isEmpty) pool = library;
    if (pool.isEmpty) {
      return const DailyQuote(
        text: 'Şu an buradasın ve bu yeterli.',
        feeling: Feeling.calm,
        reason: 'Bugün sana iyi gelsin diye seçildi.',
      );
    }

    // Aynı gün içinde aynı söz gelsin: günü sayıya çevirip havuzdan seç
    final dayKey = now.year * 400 + now.difference(DateTime(now.year)).inDays;
    final quote = pool[dayKey % pool.length];

    final reason = best == 0
        ? 'Bugün sana iyi gelsin diye seçildi.'
        : 'Son kayıtlarındaki ${feeling.label} hissine göre seçildi.';

    return DailyQuote(text: quote.text, author: quote.author, feeling: feeling, reason: reason);
  }
}
