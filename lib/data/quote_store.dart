import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/quote.dart';

/// Söz listesini yönetir. Üç kaynak, sırayla:
/// 1) İnternet: GitHub'daki quotes.json (güncellenince uygulamaya yeni sözler gelir)
/// 2) Önbellek: en son internetten indirilen liste (çevrimdışı için)
/// 3) Uygulama içi: assets/quotes.json (ilk açılış / internet hiç yoksa)
class QuoteStore extends ChangeNotifier {
  /// Sözlerin internetteki adresi. Bu dosyayı GitHub'da düzenlemek yeterli.
  static const remoteUrl =
      'https://raw.githubusercontent.com/amineyusradak/affecta_demo/main/assets/quotes.json';

  static const _cacheKey = 'quotes_cache';

  List<Quote> _quotes = const [];
  List<Quote> get quotes => _quotes;

  /// Açılışta hızlıca yerel listeyi yükler, sonra arka planda interneti dener.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);

    _quotes = _tryParse(cached) ?? _tryParse(await rootBundle.loadString('assets/quotes.json'))!;
    notifyListeners();

    refresh(); // beklemeden: açılışı yavaşlatmasın
  }

  /// İnternetten güncel listeyi indirir; başarısız olursa eldekiyle devam eder.
  Future<void> refresh() async {
    try {
      final res = await http.get(Uri.parse(remoteUrl)).timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) return;

      final fresh = _tryParse(res.body);
      if (fresh == null || fresh.isEmpty) return;

      _quotes = fresh;
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, res.body);
    } catch (e) {
      debugPrint('Sözler internetten alınamadı: $e');
    }
  }

  static List<Quote>? _tryParse(String? raw) {
    if (raw == null) return null;
    try {
      final list = Quote.listFromJson(raw);
      return list.isEmpty ? null : list;
    } catch (_) {
      return null; // bozuk dosya uygulamayı çökertmesin
    }
  }
}

final quoteStore = QuoteStore();
