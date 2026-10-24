import 'package:flutter/material.dart';

import '../data/auth_store.dart';
import '../data/counselor_store.dart';
import '../logic/client_status.dart';
import '../models/counselor_link.dart';
import '../models/mood_entry.dart';
import '../theme/app_theme.dart';
import '../widgets/premium.dart';
import 'client_detail_screen.dart';

/// Danışman: bağlı danışanların listesi, son durum ve uyarılar.
class ClientsScreen extends StatelessWidget {
  /// Danışan yokken "Davet" sekmesine geçmek için
  final VoidCallback onOpenInvite;

  const ClientsScreen({super.key, required this.onOpenInvite});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return StreamBuilder<List<CounselorLink>>(
      stream: CounselorRepo.clients(authStore.uid!),
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Text("Danışanlar yüklenemedi: ${snap.error}"));
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());

        final clients = snap.data!..sort((a, b) => a.clientName.compareTo(b.clientName));

        if (clients.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('☾', style: AppTheme.symbol(56, p.primary)),
                  const SizedBox(height: 12),
                  Text("Henüz danışanın yok", style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 6),
                  Text(
                    "Davet kodunu danışanlarınla paylaş; bağlandıklarında burada görünecekler.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: p.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  GradientButton(label: "Davet kodumu göster", icon: Icons.qr_code_2, onPressed: onOpenInvite),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          itemCount: clients.length + 1,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            if (i == 0) {
              return Text("${clients.length} danışan", style: TextStyle(color: p.textSecondary));
            }
            return _ClientTile(link: clients[i - 1]);
          },
        );
      },
    );
  }
}

class _ClientTile extends StatelessWidget {
  final CounselorLink link;
  const _ClientTile({required this.link});

  String _ago(DateTime d) {
    final days = DateTime.now().difference(d).inDays;
    if (days == 0) return "bugün";
    if (days == 1) return "dün";
    return "$days gün önce";
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return StreamBuilder(
      stream: CounselorRepo.feed(link.id, limit: 14),
      builder: (context, snap) {
        final items = snap.data?.docs.map((d) => FeedItem.fromMap(d.id, d.data())).toList() ?? [];
        final status = ClientStatus.compute(items);
        final last = status.last;

        final alertColor = switch (status.topLevel) {
          AlertLevel.urgent => const Color(0xFFE0566B),
          AlertLevel.warning => const Color(0xFFE99A7C),
          _ => p.border,
        };

        return InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ClientDetailScreen(link: link)),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: p.surface.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: alertColor, width: status.topLevel == null ? 1 : 1.6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: last == null ? p.surfaceHigh : AppColors.mood(last.mood).withValues(alpha: 0.6),
                      ),
                      child: Text(last == null ? '–' : MoodEntry.emojiOf(last.mood),
                          style: const TextStyle(fontSize: 22)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(link.clientName.isEmpty ? "Danışan" : link.clientName,
                              style: AppTheme.serif(22, p.textPrimary, FontWeight.w700)),
                          Text(
                            !link.shareMood
                                ? "Paylaşımı kapattı"
                                : last == null
                                    ? "Henüz kayıt paylaşmadı"
                                    : "Son kayıt ${_ago(last.date)} · 7 kayıt ort. ${status.recentAverage!.toStringAsFixed(1)}",
                            style: TextStyle(color: p.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: p.textSecondary),
                  ],
                ),
                // Son 7 kaydın mini şeridi (eskiden yeniye)
                if (items.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      for (final e in items.take(7).toList().reversed)
                        Expanded(
                          child: Container(
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: AppColors.mood(e.mood),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                for (final a in status.alerts.where((a) => link.shareMood && items.isNotEmpty))
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(
                          a.level == AlertLevel.info ? Icons.schedule : Icons.warning_amber_rounded,
                          size: 16,
                          color: a.level == AlertLevel.info ? p.textSecondary : alertColor,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(a.message,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: a.level == AlertLevel.info ? FontWeight.w500 : FontWeight.w800,
                                color: a.level == AlertLevel.info ? p.textSecondary : alertColor,
                              )),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
