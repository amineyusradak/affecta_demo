import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/auth_store.dart';
import '../data/counselor_store.dart';
import '../theme/app_theme.dart';
import '../widgets/premium.dart';

/// Danışman: davet kodunu gösterir. Danışan bu kodla danışmana bağlanır.
class InviteScreen extends StatelessWidget {
  const InviteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final me = authStore.user!;

    return StreamBuilder<String?>(
      stream: CounselorRepo.inviteCode(me.uid),
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Text("Kod yüklenemedi: ${snap.error}"));
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final code = snap.data;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            SoftCard(
              child: Column(
                children: [
                  Text("Davet kodun", style: TextStyle(color: p.textSecondary)),
                  const SizedBox(height: 12),
                  if (code == null)
                    Text("Henüz kod yok", style: AppTheme.serif(28, p.textPrimary))
                  else
                    SelectableText(
                      code,
                      style: AppTheme.serif(52, p.textPrimary, FontWeight.w700)
                          .copyWith(letterSpacing: 8),
                    ),
                  const SizedBox(height: 16),
                  if (code != null)
                    OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(
                          text: "Affecta'da bana bağlanmak için: Ayarlar → Danışmanım → "
                              "Danışmana bağlan → kod: $code",
                        ));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Davet mesajı kopyalandı. WhatsApp'a yapıştırabilirsin.")),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text("Davet mesajını kopyala"),
                    ),
                  const SizedBox(height: 8),
                  GradientButton(
                    label: code == null ? "Kod oluştur" : "Yeni kod oluştur",
                    icon: Icons.refresh_rounded,
                    onPressed: () => CounselorRepo.regenerateInvite(me.uid, me.displayName),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const SectionTitle("Nasıl çalışır?"),
            const SizedBox(height: 12),
            SoftCard(
              child: Text(
                "1. Kodu danışanına ver.\n"
                "2. Danışan uygulamada Ayarlar → Danışmanım → “Danışmana bağlan” der ve kodu yazar.\n"
                "3. Danışan paylaşımı onaylayınca listende görünür.\n\n"
                "• Danışanın mood’larını görürsün; notlarını sadece paylaşmayı seçtiği kayıtlarda görürsün.\n"
                "• Danışan paylaşımı istediği an kapatabilir.\n"
                "• Yeni kod oluşturursan eski kod çalışmaz; mevcut danışanların bağlı kalır.",
                style: TextStyle(height: 1.5, color: p.textPrimary),
              ),
            ),
          ],
        );
      },
    );
  }
}
