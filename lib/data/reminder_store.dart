import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Günlük söz bildirimi ayarları: açık mı, saat kaçta?
/// Varsayılan KAPALI: kullanıcı isterse Ayarlar'dan açar.
class ReminderStore extends ChangeNotifier {
  static const _enabledKey = 'reminder_enabled';
  static const _timeKey = 'reminder_minutes'; // gece yarısından itibaren dakika

  bool _enabled = false;
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);

  bool get enabled => _enabled;
  TimeOfDay get time => _time;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_enabledKey) ?? false;
    final m = prefs.getInt(_timeKey) ?? 9 * 60;
    _time = TimeOfDay(hour: m ~/ 60, minute: m % 60);
    notifyListeners();
  }

  Future<void> setEnabled(bool v) async {
    _enabled = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, v);
  }

  Future<void> setTime(TimeOfDay t) async {
    _time = t;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_timeKey, t.hour * 60 + t.minute);
  }
}

final reminderStore = ReminderStore();
