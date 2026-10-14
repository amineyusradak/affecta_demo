import 'package:flutter/material.dart';
import '../models/reflection_card.dart';

/// Farkındalık / refleksiyon kartları
/// Not: Tarot değil; tarot estetiğinde psikolojik farkındalık yönlendirmeleri.
const List<ReflectionCard> reflectionCards = [
  ReflectionCard(
    id: 'breath',
    numeral: 'I',
    title: 'Nefes Alanı',
    subtitle: 'Dur · Nefes al · Yeniden başla',
    symbol: '❋',
    accent: Color(0xFFA8DCC8), // nane
    prompt:
    '30 saniye sadece nefesine odaklan. Omuzlarını gevşet. Nefesin doğal akışını izle.',
  ),
  ReflectionCard(
    id: 'boundary',
    numeral: 'II',
    title: 'Sınır Koyma',
    subtitle: 'Hayır demek de özdeğerdir',
    symbol: '◈',
    accent: Color(0xFFBFB3F2), // lavanta
    prompt:
    'Bugün “hayır” demen gereken küçük bir yer var mı? Tek cümlelik nazik bir sınır yaz.',
  ),
  ReflectionCard(
    id: 'self_compassion',
    numeral: 'III',
    title: 'Şefkat',
    subtitle: 'Kendine nazik ol',
    symbol: '♡',
    accent: Color(0xFFF5B5C6), // pembe
    prompt:
    'Şu an en yakın arkadaşın sen olsaydın ona ne söylerdin? Aynısını kendine söyle.',
  ),
  ReflectionCard(
    id: 'focus',
    numeral: 'IV',
    title: 'Odak',
    subtitle: 'Tek şey seç · Bitir',
    symbol: '◎',
    accent: Color(0xFFF7C59F), // şeftali
    prompt:
    'Şu an kontrol edebildiğin tek bir şey seç. 10 dakika sadece ona odaklan.',
  ),
  ReflectionCard(
    id: 'reality_check',
    numeral: 'V',
    title: 'Gerçeklik',
    subtitle: 'Kanıt ne? Alternatif ne?',
    symbol: '☍',
    accent: Color(0xFFA9CCEF), // gök mavisi
    prompt:
    'Zihnindeki düşünceyi yaz. Sonra: Bu düşüncenin kanıtı ne? Alternatif bir açıklama ne olabilir?',
  ),
  ReflectionCard(
    id: 'gratitude',
    numeral: 'VI',
    title: 'Şükür',
    subtitle: 'Küçük olan da büyük',
    symbol: '☼',
    accent: Color(0xFFF3DC8E), // tereyağı
    prompt:
    'Bugünden 3 küçük şey yaz: “Bugün şuna teşekkür edebilirim…”',
  ),
  ReflectionCard(
    id: 'body_scan',
    numeral: 'VII',
    title: 'Beden',
    subtitle: 'Bedenin mesaj veriyor',
    symbol: '♁',
    accent: Color(0xFFD3B5EE), // leylak
    prompt:
    'Başından ayağına tarama yap: Nerede gerginlik var? 3 derin nefesle o bölgeyi yumuşat.',
  ),
  ReflectionCard(
    id: 'release',
    numeral: 'VIII',
    title: 'Bırakma',
    subtitle: 'Taşıdığını indir',
    symbol: '☄',
    accent: Color(0xFFA6DDE0), // su yeşili
    prompt:
    'Bugün taşıdığın yükü tek cümleyle yaz. “Bunu şu an bırakmayı seçiyorum…” diye bitir.',
  ),
  ReflectionCard(
    id: 'tiny_step',
    numeral: 'IX',
    title: 'Minik Adım',
    subtitle: 'Küçük hareket büyük fark',
    symbol: '✧',
    accent: Color(0xFFC3DDA4), // adaçayı
    prompt:
    'Şu anki hedefin için 2 dakikalık minik bir adım seç. Hemen şimdi yap.',
  ),
  ReflectionCard(
    id: 'acceptance',
    numeral: 'X',
    title: 'Kabullenme',
    subtitle: 'Direnç yoruyor',
    symbol: '☾',
    accent: Color(0xFFB3C3F0), // çiçek mavisi
    prompt:
    'Değiştiremediğin şeyi yaz. Sonra: “Bunu şu an olduğu haliyle kabul ediyorum.” cümlesini kur.',
  ),
];

/// ID'den kart bul (bulunamazsa null)
ReflectionCard? cardById(String id) {
  for (final c in reflectionCards) {
    if (c.id == id) return c;
  }
  return null;
}
