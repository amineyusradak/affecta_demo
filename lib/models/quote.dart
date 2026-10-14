import 'dart:convert';

/// Kullanıcının hissine göre söz seçmek için duygu etiketleri.
enum Feeling {
  anxiety('kaygı'),
  sadness('hüzün'),
  tired('yorgunluk'),
  anger('öfke'),
  lonely('yalnızlık'),
  stress('stres'),
  happy('mutluluk'),
  motivation('motivasyon'),
  calm('denge');

  /// Kullanıcıya gösterilen Türkçe adı
  final String label;
  const Feeling(this.label);

  /// JSON'daki "anxiety" gibi adları enum'a çevirir (bilinmeyenler atlanır)
  static Feeling? fromName(String name) {
    for (final f in values) {
      if (f.name == name) return f;
    }
    return null;
  }
}

class Quote {
  final String text;

  /// Sözün sahibi; null ise Affecta'nın kendi sözü
  final String? author;

  /// Bu sözün iyi geldiği duygular
  final Set<Feeling> feelings;

  const Quote({required this.text, this.author, required this.feelings});

  factory Quote.fromJson(Map<String, dynamic> j) => Quote(
        text: j['text'] as String,
        author: j['author'] as String?,
        feelings: (j['feelings'] as List)
            .map((e) => Feeling.fromName(e as String))
            .whereType<Feeling>()
            .toSet(),
      );

  /// {"version":1,"quotes":[…]} biçimindeki JSON metnini listeye çevirir
  static List<Quote> listFromJson(String raw) {
    final data = jsonDecode(raw) as Map<String, dynamic>;
    return (data['quotes'] as List)
        .map((e) => Quote.fromJson(e as Map<String, dynamic>))
        .where((q) => q.text.trim().isNotEmpty && q.feelings.isNotEmpty)
        .toList();
  }
}
