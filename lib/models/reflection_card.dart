import 'package:flutter/material.dart';

@immutable
class ReflectionCard {
  final String id;
  final String title;
  final String subtitle;

  // ✅ kart “şekilli” dursun diye
  final IconData icon;
  final Color accent;

  // ✅ kartın açılınca göstereceğin mini yönlendirme metni
  final String prompt;

  const ReflectionCard({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.prompt,
  });
}
