import 'package:flutter/material.dart';
import '../models/reflection_card.dart';
import '../theme/app_theme.dart';

/// Tarot estetiğinde kart: Roma rakamı, çift çerçeve, ortada sembol.
class ReflectionPickCard extends StatelessWidget {
  final ReflectionCard card;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const ReflectionPickCard({
    super.key,
    required this.card,
    required this.selected,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final deep = context.ink(card.accent);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedScale(
        scale: selected ? 1.0 : 0.95,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [card.accent.withValues(alpha: 0.75), card.accent.withValues(alpha: 0.30)],
            ),
            border: Border.all(
              color: selected ? deep : Colors.transparent,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: card.accent.withValues(alpha: selected ? 0.6 : 0.25),
                blurRadius: selected ? 22 : 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          // İç çerçeve: tarot kartlarındaki ince süs çizgisi
          child: Container(
            decoration: BoxDecoration(
              color: p.surface.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: deep.withValues(alpha: 0.35)),
            ),
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
            child: Column(
              children: [
                Text(
                  card.numeral,
                  style: AppTheme.serif(16, deep, FontWeight.w700)
                      .copyWith(letterSpacing: 2),
                ),
                const Spacer(),
                // Sembol: halka içinde
                Container(
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: card.accent.withValues(alpha: 0.35),
                    border: Border.all(color: deep.withValues(alpha: 0.4)),
                  ),
                  child: Text(card.symbol, style: AppTheme.symbol(36, deep)),
                ),
                const Spacer(),
                Text(
                  card.title,
                  textAlign: TextAlign.center,
                  style: AppTheme.serif(20, p.textPrimary, FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  card.subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: p.textSecondary, fontSize: 11, height: 1.3),
                ),
                const SizedBox(height: 6),
                AnimatedOpacity(
                  opacity: selected ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.check_circle_rounded, size: 18, color: deep),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Kartın mesajını alttan açılan pencerede gösterir.
void showCardPrompt(BuildContext context, ReflectionCard card) {
  final p = context.palette;
  final deep = context.ink(card.accent);

  showModalBottomSheet(
    context: context,
    builder: (_) => Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(card.symbol, style: AppTheme.symbol(48, deep)),
          const SizedBox(height: 10),
          Text("${card.numeral} · ${card.title}",
              style: AppTheme.serif(28, p.textPrimary, FontWeight.w700)),
          const SizedBox(height: 4),
          Text(card.subtitle, style: TextStyle(color: p.textSecondary)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: card.accent.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              card.prompt,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, height: 1.5, color: p.textPrimary),
            ),
          ),
        ],
      ),
    ),
  );
}
