import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../data/mood_store.dart' show statsDayId;
import '../logic/stats_summary.dart';
import '../models/mood_entry.dart';
import '../theme/app_theme.dart';
import '../widgets/premium.dart';

/// Admin: anonim genel bakış. Kullanıcı notlarına erişim YOK; sadece sayılar.
class AdminOverviewScreen extends StatefulWidget {
  const AdminOverviewScreen({super.key});

  @override
  State<AdminOverviewScreen> createState() => _AdminOverviewScreenState();
}

class _AdminOverviewScreenState extends State<AdminOverviewScreen> {
  final _db = FirebaseFirestore.instance;
  late Future<({int users, StatsSummary stats})> _future = _load();

  Future<({int users, StatsSummary stats})> _load() async {
    final now = DateTime.now();
    final days = [
      for (var i = 6; i >= 0; i--) statsDayId(DateTime(now.year, now.month, now.day - i)),
    ];

    // count(): belgeleri indirmeden sadece sayıyı getirir (ucuz ve hızlı)
    final usersCount = await _db.collection('users').count().get();
    final snaps = await Future.wait(days.map((d) => _db.doc('stats/$d').get()));

    return (
      users: usersCount.count ?? 0,
      stats: StatsSummary.from(days, {
        for (final s in snaps)
          if (s.exists) s.id: s.data()!,
      }),
    );
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) {
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                SoftCard(
                  child: Text(
                    "Veriler yüklenemedi. Güvenlik kurallarının yüklendiğinden ve "
                    "hesabının admin olduğundan emin ol.\n\n${snap.error}",
                    style: TextStyle(color: p.textSecondary),
                  ),
                ),
              ],
            );
          }
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());

          final users = snap.data!.users;
          final s = snap.data!.stats;
          final maxDaily = s.daily.fold<int>(1, (a, d) => d.entries > a ? d.entries : a);
          final maxMood = s.moodCounts.values.fold<int>(1, (a, b) => b > a ? b : a);

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              // ---- Özet kutuları ----
              Row(
                children: [
                  Expanded(child: _StatTile(label: "Kullanıcı", value: "$users", icon: Icons.people_outline)),
                  const SizedBox(width: 12),
                  Expanded(child: _StatTile(label: "Bugün kayıt", value: "${s.todayEntries}", icon: Icons.edit_note)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _StatTile(label: "7 gün kayıt", value: "${s.totalEntries}", icon: Icons.calendar_today_outlined)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatTile(
                      label: "7 gün ort. mood",
                      value: s.totalEntries == 0 ? "–" : s.average.toStringAsFixed(1),
                      icon: Icons.favorite_border,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ---- Günlük kayıt grafiği ----
              const SectionTitle("Son 7 gün", subtitle: "Günlük toplam kayıt sayısı"),
              const SizedBox(height: 12),
              SoftCard(
                child: SizedBox(
                  height: 150,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final d in s.daily)
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text("${d.entries}",
                                  style: TextStyle(fontSize: 11, color: p.textSecondary)),
                              const SizedBox(height: 4),
                              Container(
                                height: 100 * d.entries / maxDaily + 4,
                                margin: const EdgeInsets.symmetric(horizontal: 6),
                                decoration: BoxDecoration(
                                  gradient: AppColors.buttonGradient,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              const SizedBox(height: 6),
                              // "2026-10-20" → "20"
                              Text(d.day.substring(8),
                                  style: TextStyle(fontSize: 11, color: p.textSecondary)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ---- Mood dağılımı ----
              const SectionTitle("Mood dağılımı", subtitle: "Son 7 gün, tüm kullanıcılar (anonim)"),
              const SizedBox(height: 12),
              SoftCard(
                child: Column(
                  children: [
                    for (var m = 5; m >= 1; m--)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Text(MoodEntry.emojiOf(m), style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: s.moodCounts[m]! / maxMood,
                                  minHeight: 14,
                                  color: AppColors.mood(m),
                                  backgroundColor: AppColors.mood(m).withValues(alpha: 0.2),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 28,
                              child: Text("${s.moodCounts[m]}",
                                  textAlign: TextAlign.end,
                                  style: TextStyle(fontWeight: FontWeight.w700, color: p.textSecondary)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.lock_outline, size: 16, color: p.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Gizlilik: Kullanıcıların notlarını ve kişisel kayıtlarını admin dahil kimse göremez.",
                      style: TextStyle(fontSize: 12, color: p.textSecondary),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatTile({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: p.primary, size: 22),
          const SizedBox(height: 10),
          Text(value, style: AppTheme.serif(34, p.textPrimary, FontWeight.w700)),
          Text(label, style: TextStyle(color: p.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}
