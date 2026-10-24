import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:affecta_demo/data/link_store.dart';
import 'package:affecta_demo/logic/client_status.dart';
import 'package:affecta_demo/models/app_user.dart';
import 'package:affecta_demo/models/counselor_link.dart';
import 'package:affecta_demo/models/mood_entry.dart';
import 'package:affecta_demo/models/quote.dart';

FeedItem item(int daysAgo, int mood, {String? note, DateTime? now}) => FeedItem(
      id: '$daysAgo-$mood',
      date: (now ?? DateTime(2026, 10, 23, 12)).subtract(Duration(days: daysAgo)),
      mood: mood,
      note: note,
    );

final now = DateTime(2026, 10, 23, 12);

void main() {
  group('Gizlilik: danışmana giden kopya', () {
    final base = MoodEntry(
      id: '1',
      date: DateTime(2026, 10, 23, 9),
      mood: 2,
      note: 'Bugün çok yorgunum',
      selectedCardIds: ['breath'],
    );

    test('not varsayılan olarak GİTMEZ', () {
      final data = LinkStore.feedData(base);
      expect(data.containsKey('note'), isFalse);
      expect(data['mood'], 2);
      expect(data['cards'], ['breath']);
    });

    test('danışan paylaş derse not gider', () {
      final shared = MoodEntry(
        id: '1', date: base.date, mood: 2, note: base.note, selectedCardIds: const [], shareNote: true,
      );
      expect(LinkStore.feedData(shared)['note'], 'Bugün çok yorgunum');
    });

    test('boş not paylaşılsa bile gönderilmez', () {
      final empty = MoodEntry(id: '2', date: base.date, mood: 3, note: '  ', shareNote: true);
      expect(LinkStore.feedData(empty).containsKey('note'), isFalse);
    });

    test('kayıt paylaşım tercihi Firestore dönüşümünde korunur', () {
      final e = MoodEntry(id: 'x', date: base.date, mood: 4, note: 'a', shareNote: true);
      expect(MoodEntry.fromFirestore('x', e.toFirestore()).shareNote, isTrue);
      // Eski kayıtlarda alan yoksa gizli sayılır
      final old = e.toFirestore()..remove('shareNote');
      expect(MoodEntry.fromFirestore('x', old).shareNote, isFalse);
    });
  });

  group('Davet kodu ve bağlantı', () {
    test('kod 6 karakter ve karışan harf içermez', () {
      for (var i = 0; i < 200; i++) {
        final c = newInviteCode(Random(i));
        expect(c.length, 6);
        expect(c, isNot(matches(RegExp('[01OI]'))));
      }
    });

    test('kullanıcının yazdığı kod temizlenir', () {
      expect(normalizeInviteCode(' k7m p3q '), 'K7MP3Q');
    });

    test('bağlantı kimliği danışman_danışan biçimindedir', () {
      expect(CounselorLink.idFor('anne', 'ayse'), 'anne_ayse');
    });
  });

  group('Danışan durumu ve uyarılar', () {
    test('kayıt yoksa bilgi notu', () {
      final s = ClientStatus.compute([], now: now);
      expect(s.last, isNull);
      expect(s.alerts.single.level, AlertLevel.info);
    });

    test('son 3 kayıt düşükse uyarı', () {
      final s = ClientStatus.compute([item(0, 2), item(1, 1), item(2, 2)], now: now);
      expect(s.topLevel, AlertLevel.warning);
    });

    test('paylaşılan notta risk ifadesi acil uyarı verir', () {
      final s = ClientStatus.compute([item(1, 1, note: 'Artık yaşamak istemiyorum')], now: now);
      expect(s.topLevel, AlertLevel.urgent);
    });

    test('3+ gündür kayıt yoksa bilgi verir', () {
      final s = ClientStatus.compute([item(4, 4)], now: now);
      expect(s.alerts.map((a) => a.message), contains('4 gündür kayıt yok'));
    });

    test('iyi giden danışanda uyarı yok, ortalama doğru', () {
      final s = ClientStatus.compute([item(0, 5), item(1, 4), item(2, 3)], now: now);
      expect(s.alerts, isEmpty);
      expect(s.recentAverage, 4.0);
    });
  });

  test('roller ve etiketleri', () {
    expect(AppUser.fromMap('a', {'role': 'counselor'}).isCounselor, isTrue);
    expect(AppUser.roleLabel('user'), 'Danışan');
    expect(AppUser.roleLabel('counselor'), 'Danışman');
  });

  test('danışman sözü kimliğiyle birlikte saklanır', () {
    const q = Quote(text: 'a', feelings: {Feeling.calm}, counselorId: 'anne');
    expect(Quote.fromJson(q.toJson()).counselorId, 'anne');
    // Admin sözünde alan hiç yazılmaz (kurallar bunu bekliyor)
    expect(const Quote(text: 'b', feelings: {Feeling.calm}).toJson().containsKey('counselorId'), isFalse);
  });
}
