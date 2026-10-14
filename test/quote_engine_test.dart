import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:affecta_demo/logic/quote_engine.dart';
import 'package:affecta_demo/models/mood_entry.dart';
import 'package:affecta_demo/models/quote.dart';

MoodEntry entry(String note, {int mood = 3, List<String> cards = const []}) => MoodEntry(
      id: note,
      date: DateTime(2026, 10, 14, 10),
      mood: mood,
      note: note,
      selectedCardIds: cards,
    );

final now = DateTime(2026, 10, 14, 12);

/// Uygulamanın gerçek söz dosyası
final library = Quote.listFromJson(File('assets/quotes.json').readAsStringSync());

void main() {
  group('quotes.json', () {
    test('dosya okunur ve boş değildir', () {
      expect(library.length, greaterThan(20));
    });

    test('her duygu için en az iki söz vardır', () {
      for (final f in Feeling.values) {
        final n = library.where((q) => q.feelings.contains(f)).length;
        expect(n, greaterThanOrEqualTo(2), reason: '${f.name} için söz az');
      }
    });

    test('bilinmeyen duygu adları atlanır, bozuk dosya hata verir', () {
      final q = Quote.listFromJson(
          '{"quotes":[{"text":"a","author":null,"feelings":["calm","yok_boyle"]}]}');
      expect(q.single.feelings, {Feeling.calm});
      expect(() => Quote.listFromJson('bozuk'), throwsFormatException);
    });
  });

  group('QuoteEngine', () {
    test('Türkçe karakterler sadeleştirilir', () {
      expect(QuoteEngine.normalize('Bugün KAYGILI ve Yorgunum'), 'bugun kaygili ve yorgunum');
      expect(QuoteEngine.normalize('İçim ŞİŞ'), 'icim sis');
    });

    test('notlardaki kelimeler duyguya dönüşür', () {
      final s = QuoteEngine.analyzeText('Çok yorgunum, sınav stresi var');
      expect(s[Feeling.tired], 1);
      expect(s[Feeling.stress], 2);
    });

    test('"mutlu değilim" hüzün sayılır', () {
      final s = QuoteEngine.analyzeText('Hiç mutlu değilim');
      expect(s[Feeling.happy], isNull);
      expect(s[Feeling.sadness], 1);
    });

    test('kaygılı not, kaygı sözü getirir (yazarıyla)', () {
      final q = QuoteEngine.pick([entry('Bugün çok kaygılıyım, endişeliyim')], library, now: now);
      expect(q.feeling, Feeling.anxiety);
      final match = library.firstWhere((x) => x.text == q.text);
      expect(match.feelings, contains(Feeling.anxiety));
      expect(q.author, match.author);
      expect(q.reason, contains('kaygı'));
    });

    test('kayıt yoksa denge sözü gelir', () {
      final q = QuoteEngine.pick([], library, now: now);
      expect(q.feeling, Feeling.calm);
      expect(q.needsSupport, isFalse);
    });

    test('aynı gün hep aynı söz gelir', () {
      final a = QuoteEngine.pick([entry('yorgunum')], library, now: now);
      final b = QuoteEngine.pick([entry('yorgunum')], library,
          now: now.add(const Duration(hours: 5)));
      expect(a.text, b.text);
    });

    test('riskli ifade destek kartını açar', () {
      final q = QuoteEngine.pick([entry('Artık yaşamak istemiyorum', mood: 1)], library, now: now);
      expect(q.needsSupport, isTrue);
    });

    test('eski kayıtlar (3 günden önce) hesaba katılmaz', () {
      final old = MoodEntry(id: 'x', date: DateTime(2026, 10, 1), mood: 1, note: 'çok kaygılıyım');
      final q = QuoteEngine.pick([old], library, now: now);
      expect(q.feeling, Feeling.calm);
    });

    test('söz listesi boşsa çökmez', () {
      final q = QuoteEngine.pick([entry('kaygılıyım')], const [], now: now);
      expect(q.text, isNotEmpty);
    });
  });
}
