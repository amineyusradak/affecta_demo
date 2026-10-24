import 'package:cloud_firestore/cloud_firestore.dart';

import 'quote_engine.dart';

/// Danışanın danışmanla paylaştığı tek bir kayıt: links/{id}/feed/{entryId}
/// Not sadece danışan "paylaş" dediyse doludur.
class FeedItem {
  final String id;
  final DateTime date;
  final int mood;
  final List<String> cards;
  final String? note;

  const FeedItem({
    required this.id,
    required this.date,
    required this.mood,
    this.cards = const [],
    this.note,
  });

  factory FeedItem.fromMap(String id, Map<String, dynamic> m) => FeedItem(
        id: id,
        date: (m['date'] as Timestamp).toDate(),
        mood: m['mood'] as int,
        cards: List<String>.from(m['cards'] as List? ?? const []),
        note: m['note'] as String?,
      );
}

enum AlertLevel { info, warning, urgent }

class ClientAlert {
  final AlertLevel level;
  final String message;
  const ClientAlert(this.level, this.message);
}

/// Danışan listesinde gösterilecek özet ve uyarılar.
class ClientStatus {
  final FeedItem? last;
  final double? recentAverage; // son 7 kaydın ortalaması
  final List<ClientAlert> alerts;

  const ClientStatus({this.last, this.recentAverage, this.alerts = const []});

  /// En acil uyarının seviyesi (liste sıralaması ve renk için)
  AlertLevel? get topLevel => alerts.isEmpty
      ? null
      : alerts.map((a) => a.level).reduce((a, b) => a.index >= b.index ? a : b);

  /// [items]: en yeniden en eskiye sıralı paylaşılan kayıtlar
  factory ClientStatus.compute(List<FeedItem> items, {DateTime? now}) {
    now ??= DateTime.now();
    if (items.isEmpty) {
      return const ClientStatus(alerts: [ClientAlert(AlertLevel.info, "Henüz paylaşılan kayıt yok")]);
    }

    final alerts = <ClientAlert>[];
    final weekAgo = now.subtract(const Duration(days: 7));

    // 1) Acil: son 7 gündeki paylaşılan bir notta risk ifadesi
    if (items.any((e) => e.date.isAfter(weekAgo) && e.note != null && QuoteEngine.needsSupport(e.note!))) {
      alerts.add(const ClientAlert(AlertLevel.urgent, "Paylaşılan bir notta risk işareti var"));
    }

    // 2) Uyarı: son 3 kayıt düşük (mood 1–2)
    final last3 = items.take(3).toList();
    if (last3.length == 3 && last3.every((e) => e.mood <= 2)) {
      alerts.add(const ClientAlert(AlertLevel.warning, "Son 3 kaydı düşük seyrediyor"));
    }

    // 3) Bilgi: birkaç gündür kayıt yok
    final days = DateTime(now.year, now.month, now.day)
        .difference(DateTime(items.first.date.year, items.first.date.month, items.first.date.day))
        .inDays;
    if (days >= 3) alerts.add(ClientAlert(AlertLevel.info, "$days gündür kayıt yok"));

    final recent = items.take(7).toList();
    final avg = recent.fold<int>(0, (a, e) => a + e.mood) / recent.length;

    return ClientStatus(last: items.first, recentAverage: avg, alerts: alerts);
  }
}
