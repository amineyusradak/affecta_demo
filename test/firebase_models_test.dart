import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:affecta_demo/data/auth_store.dart' show authErrorMessage;
import 'package:affecta_demo/data/mood_store.dart' show statsDayId;
import 'package:affecta_demo/logic/stats_summary.dart';
import 'package:affecta_demo/models/app_user.dart';
import 'package:affecta_demo/models/mood_entry.dart';
import 'package:affecta_demo/models/quote.dart';

void main() {
  group('AppUser', () {
    test('rol ve görünen ad doğru okunur', () {
      final u = AppUser.fromMap('u1', {
        'email': 'ayse@ornek.com',
        'name': '',
        'role': 'admin',
        'createdAt': Timestamp.fromDate(DateTime(2026, 10, 20)),
      });
      expect(u.isAdmin, isTrue);
      expect(u.displayName, 'ayse'); // ad yoksa e-postanın başı
      expect(u.createdAt, DateTime(2026, 10, 20));
    });

    test('rol yoksa normal kullanıcıdır', () {
      expect(AppUser.fromMap('u2', {'email': 'a@b.c'}).isAdmin, isFalse);
    });
  });

  test('MoodEntry Firestore dönüşümü veriyi korur', () {
    final e = MoodEntry(id: 'x', date: DateTime(2026, 10, 20, 9), mood: 2, note: 'yorgun', selectedCardIds: ['breath']);
    final back = MoodEntry.fromFirestore('x', e.toFirestore());
    expect(back.date, e.date);
    expect(back.mood, 2);
    expect(back.note, 'yorgun');
    expect(back.selectedCardIds, ['breath']);
  });

  test('Quote toJson → fromJson aynı sözü verir', () {
    const q = Quote(text: 'Ya tutarsa!', author: 'Nasreddin Hoca', feelings: {Feeling.motivation});
    final back = Quote.fromJson(q.toJson(), id: 'abc');
    expect(back.id, 'abc');
    expect(back.text, q.text);
    expect(back.author, q.author);
    expect(back.feelings, q.feelings);
  });

  test('istatistik gün kimliği sıfırlı ve sıralanabilir', () {
    expect(statsDayId(DateTime(2026, 3, 7)), '2026-03-07');
  });

  group('StatsSummary', () {
    final days = ['2026-10-18', '2026-10-19', '2026-10-20'];

    test('eksik günler 0 sayılır, toplamlar doğru', () {
      final s = StatsSummary.from(days, {
        '2026-10-18': {'entries': 2, 'moodSum': 7, 'm3': 1, 'm4': 1},
        '2026-10-20': {'entries': 1, 'moodSum': 5, 'm5': 1},
      });
      expect(s.daily.map((d) => d.entries), [2, 0, 1]);
      expect(s.totalEntries, 3);
      expect(s.todayEntries, 1);
      expect(s.average, 4.0);
      expect(s.moodCounts, {1: 0, 2: 0, 3: 1, 4: 1, 5: 1});
    });

    test('eksiye düşmüş sayılar 0 gösterilir', () {
      final s = StatsSummary.from(days, {'2026-10-19': {'entries': -1, 'moodSum': -3, 'm3': -1}});
      expect(s.totalEntries, 0);
      expect(s.average, 0);
      expect(s.moodCounts[3], 0);
    });
  });

  test('Firebase hata kodları Türkçeye çevrilir', () {
    expect(authErrorMessage('invalid-credential'), 'E-posta veya şifre hatalı.');
    expect(authErrorMessage('email-already-in-use'), contains('zaten bir hesap'));
    expect(authErrorMessage('bilinmeyen'), contains('bilinmeyen'));
  });
}
