import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/quote.dart';

/// Söz listesini yönetir. Kaynaklar, sırayla:
/// 1) Firestore "quotes" koleksiyonu: admin panelinden eklenen/düzenlenen sözler
/// 2) Önbellek: en son Firestore'dan gelen liste (çevrimdışı için)
/// 3) Uygulama içi: assets/quotes.json (ilk açılış veya koleksiyon henüz boşsa)
class QuoteStore extends ChangeNotifier {
  static const _cacheKey = 'quotes_cache';

  final _col = FirebaseFirestore.instance.collection('quotes');
  StreamSubscription? _sub;

  List<Quote> _quotes = const [];
  List<Quote> get quotes => _quotes;

  /// Bağlı olduğum danışmanların sözleri (danışman kimliği → sözler)
  Map<String, List<Quote>> _fromCounselors = const {};
  StreamSubscription? _counselorSub;
  List<String> _counselorIds = const [];

  /// Bugün gösterilecek danışman sözü: her gün sırayla bir sonraki.
  /// Danışan birden çok danışmana bağlıysa sözler birleşir.
  Quote? counselorQuoteOfDay([DateTime? now]) {
    final all = _fromCounselors.values.expand((l) => l).toList()
      ..sort((a, b) => (a.id ?? '').compareTo(b.id ?? '')); // her telefonda aynı sıra
    if (all.isEmpty) return null;
    now ??= DateTime.now();
    final day = now.difference(DateTime(2024)).inDays;
    return all[day % all.length];
  }

  /// LinkStore değişince çağrılır: danışmanlarımın sözlerini dinle
  void bindCounselors(List<String> ids) {
    if (listEquals(ids, _counselorIds)) return;
    _counselorIds = ids;
    _counselorSub?.cancel();
    _fromCounselors = const {};
    notifyListeners();
    if (ids.isEmpty) return;

    // whereIn en fazla 30 kimlik alır; bir danışan için fazlasıyla yeter
    _counselorSub = _col.where('counselorId', whereIn: ids.take(30).toList()).snapshots().listen(
      (snap) {
        final map = <String, List<Quote>>{};
        for (final d in snap.docs) {
          final q = Quote.fromJson(d.data(), id: d.id);
          map.putIfAbsent(q.counselorId!, () => []).add(q);
        }
        _fromCounselors = map;
        notifyListeners();
      },
      onError: (e) => debugPrint('Danışman sözleri alınamadı: $e'),
    );
  }

  /// Uygulama içi varsayılan liste (admin "varsayılanları yükle" için de kullanır)
  static Future<List<Quote>> bundled() async =>
      Quote.listFromJson(await rootBundle.loadString('assets/quotes.json'));

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _quotes = _tryParse(prefs.getString(_cacheKey)) ?? await bundled();
    notifyListeners();

    // Firestore'u canlı dinle: admin söz ekleyince herkeste anında güncellenir
    _sub = _col.snapshots().listen((snap) async {
      // Sadece herkese açık sözler (danışmanların sözleri ayrı gösterilir)
      final fresh = snap.docs
          .map((d) => Quote.fromJson(d.data(), id: d.id))
          .where((q) => q.counselorId == null && q.text.trim().isNotEmpty && q.feelings.isNotEmpty)
          .toList();
      if (fresh.isEmpty) return; // koleksiyon boşsa eldekiyle devam

      _quotes = fresh;
      notifyListeners();
      await prefs.setString(
        _cacheKey,
        jsonEncode({'quotes': fresh.map((q) => q.toJson()).toList()}),
      );
    }, onError: (e) => debugPrint('Sözler Firestore\'dan alınamadı: $e'));
  }

  static List<Quote>? _tryParse(String? raw) {
    if (raw == null) return null;
    try {
      final list = Quote.listFromJson(raw);
      return list.isEmpty ? null : list;
    } catch (_) {
      return null; // bozuk önbellek uygulamayı çökertmesin
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _counselorSub?.cancel();
    super.dispose();
  }
}

final quoteStore = QuoteStore();
