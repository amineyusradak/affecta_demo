import 'package:flutter/material.dart';

import '../data/daily_store.dart';
import '../data/mood_store.dart';
import '../data/quote_store.dart';
import '../logic/quote_engine.dart';
import '../theme/app_theme.dart';
import '../widgets/flip_card.dart';
import '../widgets/premium.dart';

class TodayScreen extends StatelessWidget {
  /// "Bugünü kaydet" butonu: Kayıt sekmesine geçirir
  final VoidCallback onWriteEntry;

  const TodayScreen({super.key, required this.onWriteEntry});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 6) return "İyi geceler";
    if (h < 12) return "Günaydın";
    if (h < 18) return "İyi günler";
    return "İyi akşamlar";
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    return ListenableBuilder(
      // Yeni kayıt eklenince söz, kart çekilince ekran güncellenir
      listenable: Listenable.merge([moodStore, dailyStore, quoteStore]),
      builder: (context, _) {
        final quote = QuoteEngine.pick(moodStore.items, quoteStore.quotes);
        final card = dailyStore.todayCard;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(_greeting(), style: TextStyle(color: p.textSecondary, letterSpacing: 0.5)),
            const SizedBox(height: 4),
            Text("Bugün sana ne iyi gelir?", style: text.headlineMedium),
            const SizedBox(height: 20),

            // ---- Günün sözü ----
            if (quote.needsSupport) const _SupportCard() else _QuoteCard(quote: quote),
            const SizedBox(height: 32),

            // ---- Günün kartı ----
            SectionTitle(
              "Günün kartı",
              subtitle: card == null
                  ? "Gözlerini kapat, bir nefes al ve kartına dokun."
                  : "Yarın seni yeni bir kart bekliyor.",
            ),
            const SizedBox(height: 22),
            Center(
              child: DailyCardFlip(
                card: card,
                onDraw: () => dailyStore.draw(lastMood: moodStore.latest?.mood),
              ),
            ),
            const SizedBox(height: 24),

            // Kart açıldıysa mesajı yumuşakça belirir
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: card == null
                  ? const SizedBox.shrink()
                  : Container(
                      key: ValueKey(card.id),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: card.accent.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        children: [
                          Text("Kartının mesajı",
                              style: AppTheme.serif(20, p.textPrimary, FontWeight.w700)),
                          const SizedBox(height: 8),
                          Text(
                            card.prompt,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 15, height: 1.5, color: p.textPrimary),
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 24),
            GradientButton(
              label: "Bugünü kaydet",
              icon: Icons.edit_note_rounded,
              onPressed: onWriteEntry,
            ),
          ],
        );
      },
    );
  }
}

class _QuoteCard extends StatelessWidget {
  final DailyQuote quote;
  const _QuoteCard({required this.quote});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            p.glowA.withValues(alpha: 0.45),
            p.surface.withValues(alpha: 0.9),
            p.glowB.withValues(alpha: 0.45),
          ],
        ),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('✦', style: AppTheme.symbol(14, p.primary)),
              const SizedBox(width: 8),
              Text(
                "GÜNÜN SÖZÜ",
                style: TextStyle(
                  color: p.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            "“${quote.text}”",
            style: AppTheme.serif(26, p.textPrimary, FontWeight.w600)
                .copyWith(fontStyle: FontStyle.italic, height: 1.25),
          ),
          if (quote.author != null) ...[
            const SizedBox(height: 10),
            Text(
              "— ${quote.author}",
              style: TextStyle(
                color: p.textPrimary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Text(quote.reason, style: TextStyle(color: p.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}

/// Riskli ifadeler görüldüğünde söz yerine gösterilir.
class _SupportCard extends StatelessWidget {
  const _SupportCard();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Yanındayız ♡", style: AppTheme.serif(26, p.textPrimary, FontWeight.w700)),
          const SizedBox(height: 10),
          Text(
            "Son notların zor bir dönemden geçiyor olabileceğini düşündürüyor. "
            "Bu duyguları tek başına taşımak zorunda değilsin.\n\n"
            "• Güvendiğin biriyle bugün konuşmayı dene.\n"
            "• Bir psikolog ya da psikiyatriste başvurabilirsin.\n"
            "• Kendini güvende hissetmiyorsan hemen 112'yi ara.",
            style: TextStyle(height: 1.5, color: p.textPrimary),
          ),
        ],
      ),
    );
  }
}
