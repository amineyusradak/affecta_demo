import 'package:flutter/material.dart';
import '../models/reflection_card.dart';

/// Farkındalık / refleksiyon kartları (mock)
/// Not: Tarot değil; psikolojik farkındalık temalı mini yönlendirmeler.
const List<ReflectionCard> reflectionCards = [
  ReflectionCard(
    id: 'breath',
    title: 'Nefes Alanı',
    subtitle: 'Dur · Nefes al · Yeniden başla',
    icon: Icons.spa_outlined,
    accent: Color(0xFF6CBF7D),
    prompt:
    '30 saniye sadece nefesine odaklan. Omuzlarını gevşet. Nefesin doğal akışını izle.',
  ),
  ReflectionCard(
    id: 'boundary',
    title: 'Sınır Koyma',
    subtitle: 'Hayır demek de özdeğerdir',
    icon: Icons.shield_outlined,
    accent: Color(0xFF6F7AE0),
    prompt:
    'Bugün “hayır” demen gereken küçük bir yer var mı? Tek cümlelik nazik bir sınır yaz.',
  ),
  ReflectionCard(
    id: 'self_compassion',
    title: 'Şefkat',
    subtitle: 'Kendine nazik ol',
    icon: Icons.favorite_border,
    accent: Color(0xFFE07A8B),
    prompt:
    'Şu an en yakın arkadaşın sen olsaydın ona ne söylerdin? Aynısını kendine söyle.',
  ),
  ReflectionCard(
    id: 'focus',
    title: 'Odak',
    subtitle: 'Tek şey seç · Bitir',
    icon: Icons.gps_fixed,
    accent: Color(0xFFB35D60),
    prompt:
    'Şu an kontrol edebildiğin tek bir şey seç. 10 dakika sadece ona odaklan.',
  ),
  ReflectionCard(
    id: 'reality_check',
    title: 'Gerçeklik Kontrolü',
    subtitle: 'Kanıt ne? Alternatif ne?',
    icon: Icons.search,
    accent: Color(0xFF4FA3B8),
    prompt:
    'Zihnindeki düşünceyi yaz. Sonra: Bu düşüncenin kanıtı ne? Alternatif bir açıklama ne olabilir?',
  ),
  ReflectionCard(
    id: 'gratitude',
    title: 'Şükür',
    subtitle: 'Küçük olan da büyük',
    icon: Icons.wb_sunny_outlined,
    accent: Color(0xFFE0B84E),
    prompt:
    'Bugünden 3 küçük şey yaz: “Bugün şuna teşekkür edebilirim…”',
  ),
  ReflectionCard(
    id: 'body_scan',
    title: 'Beden Taraması',
    subtitle: 'Bedenin mesaj veriyor',
    icon: Icons.accessibility_new,
    accent: Color(0xFF7A6FE0),
    prompt:
    'Başından ayağına tarama yap: Nerede gerginlik var? 3 derin nefesle o bölgeyi yumuşat.',
  ),
  ReflectionCard(
    id: 'release',
    title: 'Bırakma',
    subtitle: 'Taşıdığını indir',
    icon: Icons.backpack_outlined,
    accent: Color(0xFF6FB8A2),
    prompt:
    'Bugün taşıdığın yükü tek cümleyle yaz. “Bunu şu an bırakmayı seçiyorum…” diye bitir.',
  ),
  ReflectionCard(
    id: 'tiny_step',
    title: 'Minik Adım',
    subtitle: 'Küçük hareket büyük fark',
    icon: Icons.directions_walk,
    accent: Color(0xFF8AAE5A),
    prompt:
    'Şu anki hedefin için 2 dakikalık minik bir adım seç. Hemen şimdi yap.',
  ),
  ReflectionCard(
    id: 'acceptance',
    title: 'Kabullenme',
    subtitle: 'Direnç yoruyor',
    icon: Icons.waves_outlined,
    accent: Color(0xFF5B8BBF),
    prompt:
    'Değiştiremediğin şeyi yaz. Sonra: “Bunu şu an olduğu haliyle kabul ediyorum.” cümlesini kur.',
  ),
];
