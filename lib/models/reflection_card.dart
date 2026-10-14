import 'package:flutter/material.dart';

@immutable
class ReflectionCard {
  final String id;
  final String numeral; // tarot gibi Roma rakamı: I, II, III…
  final String title;
  final String subtitle;

  /// Kartın ortasındaki mistik sembol (Unicode karakter)
  final String symbol;

  /// Kartın pastel rengi
  final Color accent;

  /// Kart açılınca gösterilen mini yönlendirme metni
  final String prompt;

  const ReflectionCard({
    required this.id,
    required this.numeral,
    required this.title,
    required this.subtitle,
    required this.symbol,
    required this.accent,
    required this.prompt,
  });
}
