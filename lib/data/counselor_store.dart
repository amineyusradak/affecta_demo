import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/counselor_link.dart';

/// DANIŞMAN tarafı: davet kodu, danışanlar, seans notları.
class CounselorRepo {
  static final _db = FirebaseFirestore.instance;

  /// Danışmanın aktif davet kodu (yoksa null)
  static Stream<String?> inviteCode(String counselorId) => _db
      .collection('invites')
      .where('counselorId', isEqualTo: counselorId)
      .limit(1)
      .snapshots()
      .map((s) => s.docs.isEmpty ? null : s.docs.first.id);

  /// Yeni kod üretir; eskisi silinir (eski kodla artık kimse bağlanamaz,
  /// ama önceden bağlanmış danışanlar bağlı kalır).
  static Future<String> regenerateInvite(String counselorId, String counselorName) async {
    final old = await _db.collection('invites').where('counselorId', isEqualTo: counselorId).get();
    final batch = _db.batch();
    for (final d in old.docs) {
      batch.delete(d.reference);
    }
    final code = newInviteCode();
    batch.set(_db.doc('invites/$code'), {
      'counselorId': counselorId,
      'counselorName': counselorName,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
    return code;
  }

  static Stream<List<CounselorLink>> clients(String counselorId) => _db
      .collection('links')
      .where('counselorId', isEqualTo: counselorId)
      .snapshots()
      .map((s) => s.docs.map((d) => CounselorLink.fromMap(d.data())).toList());

  /// Danışanın paylaştığı kayıtlar (en yeni önce)
  static Stream<QuerySnapshot<Map<String, dynamic>>> feed(String linkId, {int limit = 60}) => _db
      .collection('links/$linkId/feed')
      .orderBy('date', descending: true)
      .limit(limit)
      .snapshots();

  /// Danışmanın ÖZEL seans notları (danışan göremez)
  static CollectionReference<Map<String, dynamic>> notes(String linkId) =>
      _db.collection('links/$linkId/notes');

  /// Danışman bir danışanı listesinden çıkarır: paylaşılan kopyalar ve
  /// seans notları da silinir (bağlantı olmadan kimse erişemez zaten).
  static Future<void> removeClient(String linkId) async {
    final batch = _db.batch();
    for (final sub in ['feed', 'notes']) {
      final docs = await _db.collection('links/$linkId/$sub').get();
      for (final d in docs.docs) {
        batch.delete(d.reference);
      }
    }
    batch.delete(_db.doc('links/$linkId'));
    await batch.commit();
  }
}
