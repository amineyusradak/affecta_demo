import 'dart:math';

import 'package:flutter/material.dart';

import '../models/reflection_card.dart';
import '../theme/app_theme.dart';

/// Ters duran kart; dokununca 3D dönerek açılır.
class DailyCardFlip extends StatefulWidget {
  /// Bugün zaten çekilmiş kart (varsa açık başlar)
  final ReflectionCard? card;

  /// Dokununca çağrılır, çekilen kartı döndürür
  final ReflectionCard Function() onDraw;

  const DailyCardFlip({super.key, required this.card, required this.onDraw});

  @override
  State<DailyCardFlip> createState() => _DailyCardFlipState();
}

class _DailyCardFlipState extends State<DailyCardFlip> with TickerProviderStateMixin {
  late final AnimationController _flip = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    value: widget.card != null ? 1 : 0, // çekildiyse açık başla
  );

  // Kart kapalıyken hafifçe süzülür ("beni çek" hissi)
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  ReflectionCard? _card;

  @override
  void initState() {
    super.initState();
    _card = widget.card;
  }

  @override
  void dispose() {
    _flip.dispose();
    _float.dispose();
    super.dispose();
  }

  void _onTap() {
    if (_flip.value > 0) return; // zaten açıldı
    setState(() => _card = widget.onDraw());
    _float.stop();
    _flip.forward();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_flip, _float]),
        builder: (context, _) {
          final t = Curves.easeInOutCubic.transform(_flip.value);
          final angle = t * pi; // 0 → 180 derece
          final showFront = angle > pi / 2;
          final lift = _flip.value == 0 ? (_float.value - 0.5) * 8 : 0.0;

          return Transform.translate(
            offset: Offset(0, lift),
            child: Transform(
              alignment: Alignment.center,
              // setEntry(3, 2, …) perspektif verir: kart gerçekten dönüyormuş gibi
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0012)
                ..rotateY(angle),
              child: SizedBox(
                width: 230,
                height: 350,
                child: showFront
                    // Ön yüz ters görünmesin diye 180 derece geri çevrilir
                    ? Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.rotationY(pi),
                        child: TarotFace(card: _card!),
                      )
                    : const TarotBack(),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Kartın arka yüzü: pastel gradyan, ay ve yıldız süslemesi.
class TarotBack extends StatelessWidget {
  const TarotBack({super.key});

  @override
  Widget build(BuildContext context) {
    const ink = AppColors.onButton;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFC9B8FF), Color(0xFFF9C6D3), Color(0xFFFFD9C2)],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC9B8FF).withValues(alpha: 0.6),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: ink.withValues(alpha: 0.35), width: 1.2),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Köşelerdeki yıldızlar
            for (final a in const [
              Alignment(-0.8, -0.88),
              Alignment(0.8, -0.88),
              Alignment(-0.8, 0.88),
              Alignment(0.8, 0.88),
            ])
              Align(
                alignment: a,
                child: Text('✦', style: AppTheme.symbol(16, ink.withValues(alpha: 0.6))),
              ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 110,
                  height: 110,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: ink.withValues(alpha: 0.4)),
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                  child: Text('☾', style: AppTheme.symbol(56, ink)),
                ),
                const SizedBox(height: 18),
                Text(
                  'AFFECTA',
                  style: AppTheme.serif(20, ink, FontWeight.w700).copyWith(letterSpacing: 6),
                ),
                const SizedBox(height: 6),
                Text(
                  'Dokun ve kartını çek',
                  style: TextStyle(color: ink.withValues(alpha: 0.7), fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Kartın ön yüzü (büyük boy).
class TarotFace extends StatelessWidget {
  final ReflectionCard card;
  const TarotFace({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final ink = context.ink(card.accent);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [card.accent, card.accent.withValues(alpha: 0.45)],
        ),
        boxShadow: [
          BoxShadow(
            color: card.accent.withValues(alpha: 0.6),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: p.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: ink.withValues(alpha: 0.35), width: 1.2),
        ),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
        child: Column(
          children: [
            Text(card.numeral,
                style: AppTheme.serif(22, ink, FontWeight.w700).copyWith(letterSpacing: 3)),
            const Spacer(),
            Container(
              width: 120,
              height: 120,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: card.accent.withValues(alpha: 0.4),
                border: Border.all(color: ink.withValues(alpha: 0.45)),
              ),
              child: Text(card.symbol, style: AppTheme.symbol(60, ink)),
            ),
            const Spacer(),
            Text(card.title,
                textAlign: TextAlign.center,
                style: AppTheme.serif(30, p.textPrimary, FontWeight.w700)),
            const SizedBox(height: 6),
            Text(card.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: p.textSecondary, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
