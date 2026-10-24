import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/counselor_link.dart';
import '../models/mood_entry.dart';
import 'mood_store.dart';

/// DANIŞAN tarafı: bağlı olduğum danışmanlar ve onlarla ne paylaştığım.
///
/// Paylaşım "feed" ile yapılır: danışan, paylaşmayı seçtiği her kaydın bir
/// kopyasını links/{id}/feed altına yazar. Danışman SADECE bu kopyaları görür;
/// asıl kayıtlar (users/{uid}/entries) her zaman yalnızca danışana aittir.
/// Not, sadece danışan o kayıt için "paylaş" dediyse kopyaya eklenir.
class LinkStore extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;
  String? _uid;
  StreamSubscription? _sub;
  List<CounselorLink> _links = const [];

  List<CounselorLink> get links => _links;
  bool get hasCounselor => _links.isNotEmpty;

  /// Paylaşılan kayıtların kaç gün geriye gideceği (bağlanınca)
  static const backfillDays = 30;

  CollectionReference<Map<String, dynamic>> _feed(CounselorLink l) =>
      _db.collection('links/${l.id}/feed');

  Future<void> bindUser(String? uid) async {
    if (uid == _uid) return;
    await _sub?.cancel();
    _uid = uid;
    _links = const [];
    notifyListeners();
    if (uid == null) return;

    _sub = _db.collection('links').where('clientId', isEqualTo: uid).snapshots().listen(
      (snap) {
        _links = snap.docs.map((d) => CounselorLink.fromMap(d.data())).toList();
        notifyListeners();
      },
      onError: (e) => debugPrint('Bağlantılar okunamadı: $e'),
    );
  }

  /// Davet koduyla danışmana bağlanır. Hata varsa Türkçe mesaj, yoksa null.
  Future<String?> connect(String rawCode, {required String clientName}) async {
    final uid = _uid;
    if (uid == null) return "Önce giriş yapmalısın.";
    final code = normalizeInviteCode(rawCode);
    if (code.length != 6) return "Davet kodu 6 karakter olmalı.";

    try {
      final invite = await _db.doc('invites/$code').get();
      if (!invite.exists) return "Bu kod bulunamadı. Danışmanından kodu tekrar iste.";

      final counselorId = invite['counselorId'] as String;
      if (counselorId == uid) return "Kendi davet kodunla bağlanamazsın.";
      if (_links.any((l) => l.counselorId == counselorId)) {
        return "Bu danışmana zaten bağlısın.";
      }

      final link = CounselorLink(
        counselorId: counselorId,
        clientId: uid,
        counselorName: invite['counselorName'] as String? ?? 'Danışman',
        clientName: clientName,
      );
      await _db.doc('links/${link.id}').set({
        'counselorId': link.counselorId,
        'clientId': link.clientId,
        'counselorName': link.counselorName,
        'clientName': link.clientName,
        'shareMood': true,
        'inviteCode': code, // kurallar kodun gerçekten bu danışmana ait olduğunu kontrol eder
        'createdAt': FieldValue.serverTimestamp(),
      });
      await _backfill(link);
      return null;
    } catch (e) {
      return "Bağlanılamadı: $e";
    }
  }

  /// Bağlantıyı tamamen kaldırır: danışmanın gördüğü tüm kopyalar da silinir.
  Future<void> disconnect(CounselorLink l) async {
    await _clearFeed(l);
    await _db.doc('links/${l.id}').delete();
  }

  /// Mood paylaşımını aç/kapat. Kapatınca danışmanın gördükleri silinir.
  Future<void> setShareMood(CounselorLink l, bool share) async {
    await _db.doc('links/${l.id}').update({'shareMood': share});
    final updated = CounselorLink(
      counselorId: l.counselorId,
      clientId: l.clientId,
      counselorName: l.counselorName,
      clientName: l.clientName,
      shareMood: share,
    );
    share ? await _backfill(updated) : await _clearFeed(updated);
  }

  // ---- MoodStore'dan çağrılır: kayıt değişince paylaşılan kopyaları güncelle ----

  static Map<String, dynamic> feedData(MoodEntry e) => {
        'date': Timestamp.fromDate(e.date),
        'mood': e.mood,
        'cards': e.selectedCardIds,
        // Not SADECE danışan paylaşmayı seçtiyse gider
        if (e.shareNote && e.note.trim().isNotEmpty) 'note': e.note,
      };

  void syncEntry(MoodEntry e) {
    for (final l in _links.where((l) => l.shareMood)) {
      _feed(l).doc(e.id).set(feedData(e)).catchError((err) => debugPrint('Paylaşım yazılamadı: $err'));
    }
  }

  void removeEntry(String entryId) {
    for (final l in _links) {
      _feed(l).doc(entryId).delete().catchError((err) => debugPrint('Paylaşım silinemedi: $err'));
    }
  }

  Future<void> _backfill(CounselorLink l) async {
    final from = DateTime.now().subtract(const Duration(days: backfillDays));
    final batch = _db.batch();
    for (final e in moodStore.items.where((e) => e.date.isAfter(from))) {
      batch.set(_feed(l).doc(e.id), feedData(e));
    }
    await batch.commit();
  }

  Future<void> _clearFeed(CounselorLink l) async {
    final docs = await _feed(l).get();
    final batch = _db.batch();
    for (final d in docs.docs) {
      batch.delete(d.reference);
    }
    await batch.commit();
  }
}

final linkStore = LinkStore();
