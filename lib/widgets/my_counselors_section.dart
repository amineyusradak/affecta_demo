import 'package:flutter/material.dart';

import '../data/auth_store.dart';
import '../data/link_store.dart';
import '../models/counselor_link.dart';
import '../theme/app_theme.dart';
import 'premium.dart';

/// Ayarlar → "Danışmanım": bağlı danışmanlar, paylaşım anahtarı, bağlanma.
class MyCounselorsSection extends StatelessWidget {
  const MyCounselorsSection({super.key});

  Future<void> _disconnect(BuildContext context, CounselorLink l) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Bağlantı kaldırılsın mı?"),
        content: Text("${l.counselorName} artık kayıtlarını göremeyecek ve daha önce paylaştıkların da silinecek."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("Vazgeç")),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text("Kaldır")),
        ],
      ),
    );
    if (ok == true) await linkStore.disconnect(l);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return ListenableBuilder(
      listenable: linkStore,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle("Danışmanım", subtitle: "Ne paylaşacağına sen karar verirsin"),
          const SizedBox(height: 12),
          SoftCard(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              children: [
                for (final l in linkStore.links) ...[
                  SwitchListTile(
                    value: l.shareMood,
                    onChanged: (v) => linkStore.setShareMood(l, v),
                    title: Text(l.counselorName),
                    subtitle: Text(
                      l.shareMood
                          ? "Mood’larını görüyor · notlarını sadece paylaştığın kayıtlarda görür"
                          : "Paylaşım kapalı · hiçbir kaydını göremiyor",
                      style: TextStyle(color: p.textSecondary, fontSize: 12),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => _disconnect(context, l),
                      child: Text("Bağlantıyı kaldır", style: TextStyle(color: p.accent)),
                    ),
                  ),
                  Divider(color: p.border, height: 1),
                ],
                ListTile(
                  leading: Icon(Icons.link_rounded, color: p.primary),
                  title: const Text("Danışmana bağlan"),
                  subtitle: Text("Danışmanından aldığın davet koduyla",
                      style: TextStyle(color: p.textSecondary, fontSize: 12)),
                  onTap: () => showDialog(context: context, builder: (_) => const _ConnectDialog()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Kod girme + açık rıza onayı
class _ConnectDialog extends StatefulWidget {
  const _ConnectDialog();

  @override
  State<_ConnectDialog> createState() => _ConnectDialogState();
}

class _ConnectDialogState extends State<_ConnectDialog> {
  final _code = TextEditingController();
  bool _consent = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final err = await linkStore.connect(
      _code.text,
      clientName: authStore.user?.displayName ?? '',
    );
    if (!mounted) return;
    if (err == null) {
      // Pencere kapanmadan önce al: kapandıktan sonra bu context kullanılamaz
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(const SnackBar(content: Text("Danışmanına bağlandın 💜")));
    } else {
      setState(() {
        _busy = false;
        _error = err;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AlertDialog(
      title: const Text("Danışmana bağlan"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _code,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              style: AppTheme.serif(26, p.textPrimary, FontWeight.w700).copyWith(letterSpacing: 6),
              decoration: InputDecoration(labelText: "Davet kodu", errorText: _error, counterText: ""),
            ),
            const SizedBox(height: 12),
            // Açık rıza: ne paylaşılacağını açıkça söyle
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: p.surfaceHigh,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                "Bağlandığında danışmanın şunları görebilir:\n"
                "• Mood puanların ve seçtiğin kartlar (son 30 gün ve sonrası)\n"
                "• Notların: SADECE “danışmanımla paylaş” dediğin kayıtlarda\n\n"
                "Paylaşımı istediğin an kapatabilir veya bağlantıyı kaldırabilirsin. "
                "Kaldırdığında paylaştıkların da silinir.",
                style: TextStyle(fontSize: 13, height: 1.45, color: p.textPrimary),
              ),
            ),
            CheckboxListTile(
              value: _consent,
              onChanged: (v) => setState(() => _consent = v ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text("Okudum, bu bilgilerin danışmanımla paylaşılmasına açıkça onay veriyorum.",
                  style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: const Text("Vazgeç")),
        FilledButton(
          onPressed: (_consent && !_busy) ? _connect : null,
          child: _busy
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text("Bağlan"),
        ),
      ],
    );
  }
}
