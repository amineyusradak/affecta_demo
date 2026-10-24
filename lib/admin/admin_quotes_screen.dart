import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../data/quote_store.dart';
import '../models/quote.dart';
import '../theme/app_theme.dart';
import '../widgets/premium.dart';

/// Sözleri ekle / düzenle / sil.
///  - Admin ([counselorId] null): herkese açık "Günün sözü" havuzu
///  - Danışman: sadece kendi danışanlarına "Danışmanından" görünen sözler
class AdminQuotesScreen extends StatelessWidget {
  final String? counselorId;
  final String? counselorName;

  const AdminQuotesScreen({super.key, this.counselorId, this.counselorName});

  bool get _isCounselor => counselorId != null;

  static final _col = FirebaseFirestore.instance.collection('quotes');

  /// Koleksiyon boşken uygulama içindeki varsayılan sözleri tek seferde yükler
  Future<void> _seedDefaults(BuildContext context) async {
    final list = await QuoteStore.bundled();
    final batch = FirebaseFirestore.instance.batch();
    for (final q in list) {
      batch.set(_col.doc(), {...q.toJson(), 'createdAt': FieldValue.serverTimestamp()});
    }
    await batch.commit();
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("${list.length} söz yüklendi ✦")));
    }
  }

  Future<void> _delete(BuildContext context, Quote q) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Söz silinsin mi?"),
        content: Text("“${q.text}”"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("Vazgeç")),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text("Sil")),
        ],
      ),
    );
    if (ok == true) await _col.doc(q.id).delete();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showQuoteEditor(context, counselorId: counselorId, defaultAuthor: counselorName),
        icon: const Icon(Icons.add),
        label: const Text("Söz ekle"),
      ),
      body: StreamBuilder(
        // Danışman: sadece kendi sözleri. Admin: danışmanlara ait olmayanlar.
        // (Sıralama telefonda yapılır; böylece Firestore'da ek indeks gerekmez.)
        stream: (_isCounselor ? _col.where('counselorId', isEqualTo: counselorId) : _col).snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text("Sözler yüklenemedi: ${snap.error}"));
          }
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snap.data!.docs.toList()
            ..sort((a, b) {
              final ta = a.data()['createdAt'] as Timestamp?;
              final tb = b.data()['createdAt'] as Timestamp?;
              if (ta == null || tb == null) return ta == null ? -1 : 1; // yeni eklenen en üstte
              return tb.compareTo(ta);
            });
          final quotes = docs
              .map((d) => Quote.fromJson(d.data(), id: d.id))
              .where((q) => _isCounselor || q.counselorId == null)
              .toList();

          if (quotes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('✦', style: AppTheme.symbol(48, p.primary)),
                    const SizedBox(height: 12),
                    Text("Henüz söz yok", style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 6),
                    Text(
                      _isCounselor
                          ? "Buraya eklediğin sözler, danışanlarının ana ekranında her gün “Danışmanından” başlığıyla görünür."
                          : "Uygulamadaki hazır sözleri buraya yükleyip düzenlemeye başlayabilirsin.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: p.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    if (!_isCounselor)
                      GradientButton(
                        label: "Varsayılan sözleri yükle",
                        icon: Icons.download_outlined,
                        onPressed: () => _seedDefaults(context),
                      ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            itemCount: quotes.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              if (i == 0) {
                return Text("${quotes.length} söz · düzenlemek için dokun",
                    style: TextStyle(color: p.textSecondary));
              }
              final q = quotes[i - 1];
              return InkWell(
                borderRadius: BorderRadius.circular(26),
                onTap: () => showQuoteEditor(context, existing: q, counselorId: counselorId, defaultAuthor: counselorName),
                child: SoftCard(
                  padding: const EdgeInsets.fromLTRB(18, 14, 8, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("“${q.text}”",
                                style: AppTheme.serif(19, p.textPrimary)
                                    .copyWith(fontStyle: FontStyle.italic)),
                            const SizedBox(height: 6),
                            Text("— ${q.author ?? 'Affecta'}",
                                style: TextStyle(fontWeight: FontWeight.w700, color: p.textSecondary)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (final f in q.feelings)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: p.primary.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(f.label,
                                        style: TextStyle(fontSize: 11, color: p.primary, fontWeight: FontWeight.w700)),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: "Sil",
                        icon: Icon(Icons.delete_outline, color: p.textSecondary),
                        onPressed: () => _delete(context, q),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Söz ekleme / düzenleme penceresi
Future<void> showQuoteEditor(
  BuildContext context, {
  Quote? existing,
  String? counselorId,
  String? defaultAuthor,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true, // klavye açılınca pencere yukarı kalksın
    builder: (_) => _QuoteEditor(
      existing: existing,
      counselorId: counselorId,
      defaultAuthor: defaultAuthor,
    ),
  );
}

class _QuoteEditor extends StatefulWidget {
  final Quote? existing;
  final String? counselorId;

  /// Yazar boş bırakılırsa kullanılacak ad (danışman için kendi adı)
  final String? defaultAuthor;

  const _QuoteEditor({this.existing, this.counselorId, this.defaultAuthor});

  @override
  State<_QuoteEditor> createState() => _QuoteEditorState();
}

class _QuoteEditorState extends State<_QuoteEditor> {
  late final _text = TextEditingController(text: widget.existing?.text);
  late final _author = TextEditingController(text: widget.existing?.author);
  late final Set<Feeling> _feelings = {...?widget.existing?.feelings};
  bool _saving = false;

  @override
  void dispose() {
    _text.dispose();
    _author.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _text.text.trim();
    if (text.isEmpty || _feelings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Söz metni ve en az bir duygu gerekli.")),
      );
      return;
    }
    setState(() => _saving = true);

    final typed = _author.text.trim();
    final author = typed.isNotEmpty ? typed : widget.defaultAuthor;
    final data = Quote(
      text: text,
      author: author,
      feelings: _feelings,
      counselorId: widget.counselorId,
    ).toJson();
    final col = FirebaseFirestore.instance.collection('quotes');

    try {
      if (widget.existing?.id case final id?) {
        await col.doc(id).update(data);
      } else {
        await col.add({...data, 'createdAt': FieldValue.serverTimestamp()});
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Kaydedilemedi: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.existing == null ? "Yeni söz" : "Sözü düzenle",
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            TextField(
              controller: _text,
              maxLines: 4,
              minLines: 2,
              maxLength: 500,
              decoration: const InputDecoration(labelText: "Söz"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _author,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: widget.defaultAuthor == null
                    ? "Kimin sözü? (boş bırakılırsa Affecta)"
                    : "Kimin sözü? (boş bırakılırsa ${widget.defaultAuthor})",
              ),
            ),
            const SizedBox(height: 16),
            Text("Hangi duygulara iyi gelir?", style: TextStyle(color: p.textSecondary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final f in Feeling.values)
                  FilterChip(
                    label: Text(f.label),
                    selected: _feelings.contains(f),
                    onSelected: (v) => setState(() => v ? _feelings.add(f) : _feelings.remove(f)),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            GradientButton(label: "Kaydet", icon: Icons.check, loading: _saving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
