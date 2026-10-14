import 'package:flutter/material.dart';
import '../data/auth_store.dart';
import '../data/theme_store.dart';
import '../theme/app_theme.dart';
import '../widgets/premium.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notif = true;

  void _logout() {
    authStore.logout();
    // Tüm ekranları kapat, giriş ekranına dön
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        // ---- Görünüm ----
        const SectionTitle("Görünüm"),
        const SizedBox(height: 12),
        SoftCard(
          child: ListenableBuilder(
            listenable: themeStore,
            builder: (context, _) => SizedBox(
              width: double.infinity,
              child: SegmentedButton<ThemeMode>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: Icon(Icons.wb_sunny_outlined),
                    label: Text("Açık"),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.nightlight_outlined),
                    label: Text("Koyu"),
                  ),
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: Icon(Icons.phone_iphone),
                    label: Text("Sistem"),
                  ),
                ],
                selected: {themeStore.mode},
                onSelectionChanged: (s) => themeStore.setMode(s.first),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // ---- Bildirimler ----
        const SectionTitle("Bildirimler"),
        const SizedBox(height: 12),
        SoftCard(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: SwitchListTile(
            value: _notif,
            onChanged: (v) => setState(() => _notif = v),
            title: const Text("Günlük hatırlatma"),
            subtitle: Text("Yakında: her gün sana özel bir söz",
                style: TextStyle(color: p.textSecondary)),
          ),
        ),
        const SizedBox(height: 24),

        // ---- Hesap ----
        const SectionTitle("Hesap"),
        const SizedBox(height: 12),
        SoftCard(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.person_outline_rounded, color: p.primary),
                title: const Text("E-posta"),
                subtitle: Text(
                  authStore.email.isEmpty ? "—" : authStore.email,
                  style: TextStyle(color: p.textSecondary),
                ),
              ),
              Divider(color: p.border, height: 1),
              ListTile(
                leading: Icon(Icons.logout_rounded, color: p.accent),
                title: const Text("Çıkış yap"),
                onTap: _logout,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        Center(
          child: Text("Affecta · v1.0", style: TextStyle(color: p.textSecondary, fontSize: 12)),
        ),
      ],
    );
  }
}
