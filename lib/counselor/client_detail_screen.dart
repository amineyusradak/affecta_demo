import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../data/counselor_store.dart';
import '../data/reflection_cards.dart';
import '../logic/client_status.dart';
import '../logic/quote_engine.dart';
import '../models/counselor_link.dart';
import '../models/mood_entry.dart';
import '../models/reflection_card.dart';
import '../theme/app_theme.dart';
import '../widgets/premium.dart';

/// Danışman: tek danışanın paylaştıkları + danışmanın özel seans notları.
class ClientDetailScreen extends StatelessWidget {
  final CounselorLink link;
  const ClientDetailScreen({super.key, required this.link});

  String _date(DateTime d) {
    String two(int x) => x.toString().padLeft(2, '0');
    return "${two(d.day)}.${two(d.month)} · ${two(d.hour)}:${two(d.minute)}";
  }

  Future<void> _remove(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Danışan listeden çıkarılsın mı?"),
        content: Text(
            "${link.clientName} ile bağlantın sonlanır. Paylaştığı kayıtlar ve bu danışan için aldığın seans notları silinir."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("Vazgeç")),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text("Çıkar")),
        ],
      ),
    );
    if (ok != true) return;
    await CounselorRepo.removeClient(link.id);
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(link.clientName.isEmpty ? "Danışan" : link.clientName),
        actions: [
          PopupMenuButton<String>(
            onSelected: (_) => _remove(context),
            itemBuilder: (_) => const [PopupMenuItem(value: 'remove', child: Text("Listeden çıkar"))],
          ),
        ],
      ),
      body: AuraBackground(
        child: SafeArea(
          child: StreamBuilder(
            stream: CounselorRepo.feed(link.id),
            builder: (context, snap) {
              if (snap.hasError) return Center(child: Text("Yüklenemedi: ${snap.error}"));
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());

              final items = snap.data!.docs.map((d) => FeedItem.fromMap(d.id, d.data())).toList();
              final status = ClientStatus.compute(items);

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  if (!link.shareMood)
                    SoftCard(
                      child: Text(
                        "${link.clientName} şu an paylaşımı kapatmış. Açtığında kayıtları burada görünür.",
                        style: TextStyle(color: p.textSecondary),
                      ),
                    ),

                  // ---- Uyarılar ----
                  for (final a in status.alerts.where((a) => a.level != AlertLevel.info))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _AlertBanner(alert: a),
                    ),

                  // ---- Mood grafiği (son 30 kayıt) ----
                  if (items.isNotEmpty) ...[
                    SectionTitle("Mood seyri",
                        subtitle: "Son ${items.length.clamp(0, 30)} kayıt · ort. ${status.recentAverage!.toStringAsFixed(1)} / 5"),
                    const SizedBox(height: 12),
                    SoftCard(
                      child: SizedBox(
                        height: 110,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            for (final e in items.take(30).toList().reversed)
                              Expanded(
                                child: Container(
                                  height: 18.0 * e.mood,
                                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                  decoration: BoxDecoration(
                                    color: AppColors.mood(e.mood),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ---- Seans notları (özel) ----
                  _SessionNotes(linkId: link.id),
                  const SizedBox(height: 24),

                  // ---- Paylaşılan kayıtlar ----
                  const SectionTitle("Paylaşılan kayıtlar",
                      subtitle: "Notlar sadece danışan paylaşmayı seçtiyse görünür"),
                  const SizedBox(height: 12),
                  if (items.isEmpty)
                    SoftCard(child: Text("Henüz kayıt yok.", style: TextStyle(color: p.textSecondary))),
                  for (final e in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SoftCard(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(MoodEntry.emojiOf(e.mood), style: const TextStyle(fontSize: 22)),
                                const SizedBox(width: 10),
                                Text(MoodEntry.labelOf(e.mood),
                                    style: AppTheme.serif(19, p.textPrimary, FontWeight.w700)),
                                const Spacer(),
                                Text(_date(e.date), style: TextStyle(color: p.textSecondary, fontSize: 12)),
                              ],
                            ),
                            if (e.note != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                e.note!,
                                style: TextStyle(
                                  height: 1.4,
                                  color: QuoteEngine.needsSupport(e.note!)
                                      ? const Color(0xFFE0566B)
                                      : p.textPrimary,
                                ),
                              ),
                            ],
                            if (e.cards.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                children: [
                                  for (final c in e.cards.map(cardById).whereType<ReflectionCard>())
                                    Chip(
                                      visualDensity: VisualDensity.compact,
                                      side: BorderSide.none,
                                      backgroundColor: c.accent.withValues(alpha: 0.35),
                                      label: Text("${c.symbol}  ${c.title}", style: const TextStyle(fontSize: 12)),
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  final ClientAlert alert;
  const _AlertBanner({required this.alert});

  @override
  Widget build(BuildContext context) {
    final urgent = alert.level == AlertLevel.urgent;
    final color = urgent ? const Color(0xFFE0566B) : const Color(0xFFE99A7C);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              urgent
                  ? "${alert.message}. Danışanınla en kısa sürede iletişime geç; gerekirse 112'ye yönlendir."
                  : alert.message,
              style: TextStyle(fontWeight: FontWeight.w700, color: context.palette.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Danışmanın bu danışan için aldığı özel notlar
class _SessionNotes extends StatelessWidget {
  final String linkId;
  const _SessionNotes({required this.linkId});

  Future<void> _add(BuildContext context) async {
    final ctrl = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Seans notu"),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: 6,
          minLines: 3,
          decoration: const InputDecoration(hintText: "Bu görüşmede neler konuşuldu?"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("Vazgeç")),
          FilledButton(onPressed: () => Navigator.pop(c, ctrl.text.trim()), child: const Text("Kaydet")),
        ],
      ),
    );
    ctrl.dispose();
    if (text == null || text.isEmpty) return;
    await CounselorRepo.notes(linkId).add({'text': text, 'createdAt': FieldValue.serverTimestamp()});
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: SectionTitle("Seans notlarım", subtitle: "🔒 Sadece sen görürsün"),
            ),
            IconButton.filledTonal(
              tooltip: "Not ekle",
              onPressed: () => _add(context),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder(
          stream: CounselorRepo.notes(linkId).orderBy('createdAt', descending: true).snapshots(),
          builder: (context, snap) {
            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) {
              return SoftCard(
                child: Text("Henüz not yok. Görüşmelerinden sonra buraya not alabilirsin.",
                    style: TextStyle(color: p.textSecondary)),
              );
            }
            return Column(
              children: [
                for (final d in docs)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SoftCard(
                      padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if ((d.data()['createdAt'] as Timestamp?)?.toDate() case final t?)
                                  Text("${t.day}.${t.month}.${t.year}",
                                      style: TextStyle(color: p.textSecondary, fontSize: 12)),
                                const SizedBox(height: 4),
                                Text(d.data()['text'] as String, style: const TextStyle(height: 1.4)),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: "Sil",
                            icon: Icon(Icons.delete_outline, color: p.textSecondary, size: 20),
                            onPressed: () => d.reference.delete(),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
