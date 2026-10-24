import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../data/mood_store.dart';
import '../data/quote_store.dart';
import '../data/reminder_store.dart';
import '../logic/quote_engine.dart';
import 'notification_service.dart';

/// Önümüzdeki 7 günün sözünü hesaplar; widget'a yazar ve bildirimleri kurar.
///
/// Yeni kayıt eklenince, sözler internetten güncellenince veya bildirim
/// ayarı değişince kendiliğinden yeniden çalışır.
class DailySync {
  static const _days = 7;
  static Timer? _debounce;

  /// Widget ve bildirimler sadece telefonlarda var
  static bool get supported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static Future<void> start() async {
    if (!supported) return;
    await NotificationService.init();
    Listenable.merge([moodStore, quoteStore, reminderStore]).addListener(schedule);
    await run();
  }

  /// Arka arkaya gelen değişiklikleri tek seferde işle (yarım saniye bekle)
  static void schedule() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), run);
  }

  /// Widget anahtarı: Android tarafındaki ile aynı biçim ("2026-10-14")
  static String dayKey(DateTime d) => "${d.year}-${d.month}-${d.day}";

  static Future<void> run() async {
    if (!supported) return;

    final now = DateTime.now();
    final days = [
      for (var i = 0; i < _days; i++)
        () {
          // Her günün öğlesine göre seç: o günün sözü
          final day = DateTime(now.year, now.month, now.day + i, 12);
          final q = QuoteEngine.pick(moodStore.items, quoteStore.quotes, now: day);
          return (day: day, text: q.text, author: q.author);
        }(),
    ];

    // ---- Widget ----
    try {
      for (final d in days) {
        await HomeWidget.saveWidgetData('quote_${dayKey(d.day)}', d.text);
        await HomeWidget.saveWidgetData('author_${dayKey(d.day)}', d.author ?? '');
      }
      await HomeWidget.saveWidgetData('quote_latest', days.first.text);
      await HomeWidget.saveWidgetData('author_latest', days.first.author ?? '');
      await HomeWidget.updateWidget(androidName: 'QuoteWidgetProvider');
    } catch (e) {
      debugPrint('Widget güncellenemedi: $e');
    }

    // ---- Bildirimler ----
    try {
      if (reminderStore.enabled) {
        await NotificationService.scheduleDays(days, reminderStore.time);
      } else {
        await NotificationService.cancelAll();
      }
    } catch (e) {
      debugPrint('Bildirimler kurulamadı: $e');
    }
  }
}
