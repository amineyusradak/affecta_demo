import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/reflection_card.dart';
import 'reflection_cards.dart';

/// Günün kartını tutar: günde bir kez çekilir, gün boyu aynı kalır.
class DailyStore extends ChangeNotifier {
  static const _cardKey = 'daily_card_id';
  static const _dateKey = 'daily_card_date';

  String? _cardId;
  String? _date;

  static String _today() {
    final n = DateTime.now();
    return "${n.year}-${n.month}-${n.day}";
  }

  /// Bugün kart çekildiyse o kart, çekilmediyse null
  ReflectionCard? get todayCard =>
      (_date == _today() && _cardId != null) ? cardById(_cardId!) : null;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _cardId = prefs.getString(_cardKey);
    _date = prefs.getString(_dateKey);
    notifyListeners();
  }

  /// Kart çeker. Son mood'a göre deste değişir:
  /// zor günlerde şefkatli kartlar, iyi günlerde harekete geçiren kartlar.
  ReflectionCard draw({int? lastMood}) {
    final existing = todayCard;
    if (existing != null) return existing;

    const gentle = ['breath', 'self_compassion', 'acceptance', 'release', 'body_scan'];
    const active = ['gratitude', 'tiny_step', 'focus', 'boundary'];

    final pool = switch (lastMood) {
      1 || 2 => reflectionCards.where((c) => gentle.contains(c.id)).toList(),
      4 || 5 => reflectionCards.where((c) => active.contains(c.id)).toList(),
      _ => reflectionCards,
    };

    final card = pool[Random().nextInt(pool.length)];
    _cardId = card.id;
    _date = _today();
    notifyListeners();
    _save();
    return card;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cardKey, _cardId!);
    await prefs.setString(_dateKey, _date!);
  }
}

final dailyStore = DailyStore();
