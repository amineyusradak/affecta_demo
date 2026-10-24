import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Danışan ↔ danışman bağlantısı: links/{counselorId}_{clientId}
///
/// Bağlantıyı danışan kurar (davet koduyla) ve istediği an siler.
/// Danışman sadece bağlı danışanların PAYLAŞTIKLARINI görür.
class CounselorLink {
  final String counselorId;
  final String clientId;
  final String counselorName;
  final String clientName;

  /// Mood'larımı bu danışmanla paylaş (danışan istediği an kapatabilir)
  final bool shareMood;
  final DateTime? createdAt;

  const CounselorLink({
    required this.counselorId,
    required this.clientId,
    required this.counselorName,
    required this.clientName,
    this.shareMood = true,
    this.createdAt,
  });

  /// Belge kimliği: aynı kişiler arasında tek bağlantı olsun
  static String idFor(String counselorId, String clientId) => '${counselorId}_$clientId';
  String get id => idFor(counselorId, clientId);

  factory CounselorLink.fromMap(Map<String, dynamic> m) => CounselorLink(
        counselorId: m['counselorId'] as String,
        clientId: m['clientId'] as String,
        counselorName: m['counselorName'] as String? ?? '',
        clientName: m['clientName'] as String? ?? '',
        shareMood: m['shareMood'] as bool? ?? true,
        createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
      );
}

/// Davet kodu: karışmasın diye 0/O, 1/I gibi harfler yok. Örnek: "K7MP3Q"
String newInviteCode([Random? rnd]) {
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final r = rnd ?? Random.secure();
  return List.generate(6, (_) => alphabet[r.nextInt(alphabet.length)]).join();
}

/// Kullanıcının yazdığı kodu temizler: boşlukları atar, büyük harfe çevirir
String normalizeInviteCode(String raw) =>
    raw.replaceAll(RegExp(r'\s'), '').toUpperCase();
