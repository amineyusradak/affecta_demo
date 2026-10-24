import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Günlük söz bildirimlerini kurar ve iptal eder.
class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  /// Bildirim görünümü. Kanal adını kullanıcı telefon ayarlarında görür.
  /// BigText stili: bildirim açılınca sözün tamamı ve yazarı görünür.
  static NotificationDetails _details(String body) => NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_quote',
          'Günün sözü',
          channelDescription: 'Her gün seçtiğin saatte sana özel bir söz',
          icon: 'ic_stat_moon',
          color: const Color(0xFF8E7AE0),
          styleInformation: BigTextStyleInformation(body),
          // Kilit ekranında sözün tamamı görünsün
          visibility: NotificationVisibility.public,
        ),
        iOS: const DarwinNotificationDetails(),
      );

  static Future<void> init() async {
    // Saat dilimini öğren: bildirim telefonun yerel saatinde gelsin
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
    }

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_moon'),
        // İzin uygulama açılınca değil, kullanıcı bildirimi açınca istensin
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestSoundPermission: false,
          requestBadgePermission: false,
        ),
      ),
    );
  }

  /// Bildirim izni ister (Android 13+ ve iOS). İzin verilirse true.
  static Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(alert: true, sound: true) ?? false;
    }
    return false;
  }

  /// Önümüzdeki günler için her güne kendi sözüyle bir bildirim kurar.
  /// [days]: (gün, söz metni, yazar) listesi
  static Future<void> scheduleDays(
    List<({DateTime day, String text, String? author})> days,
    TimeOfDay time,
  ) async {
    await cancelAll();
    final now = tz.TZDateTime.now(tz.local);

    for (var i = 0; i < days.length; i++) {
      final d = days[i];
      final when = tz.TZDateTime(tz.local, d.day.year, d.day.month, d.day.day, time.hour, time.minute);
      if (when.isBefore(now)) continue; // bugünün saati geçtiyse atla

      final body = d.author == null ? d.text : "${d.text}\n— ${d.author}";
      await _plugin.zonedSchedule(
        id: i,
        title: 'Günün sözü ✦',
        body: body,
        scheduledDate: when,
        notificationDetails: _details(body),
        // Tam saat izni istemeden: Android birkaç dakika oynatabilir
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  static Future<void> cancelAll() => _plugin.cancelAll();

  /// Ayarlar'daki "Deneme bildirimi gönder" için: hemen bir bildirim gösterir
  static Future<void> showNow(String text, String? author) {
    final body = author == null ? text : "$text\n— $author";
    return _plugin.show(
      id: 99,
      title: 'Günün sözü ✦',
      body: body,
      notificationDetails: _details(body),
    );
  }
}
