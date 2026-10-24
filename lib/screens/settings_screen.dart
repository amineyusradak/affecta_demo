import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

import '../data/auth_store.dart';
import '../data/mood_store.dart';
import '../data/quote_store.dart';
import '../data/reminder_store.dart';
import '../data/theme_store.dart';
import '../logic/quote_engine.dart';
import '../services/daily_sync.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/my_counselors_section.dart';
import '../widgets/premium.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _canPinWidget = false;

  @override
  void initState() {
    super.initState();
    // Bazı Android ana ekranları "widget ekle" penceresini açmayı destekler
    if (DailySync.supported) {
      HomeWidget.isRequestPinWidgetSupported().then((v) {
        if (mounted) setState(() => _canPinWidget = v ?? false);
      });
    }
  }

  void _toast(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _toggleReminder(bool on) async {
    if (on) {
      // İzin sadece kullanıcı bildirimi açmak istediğinde istenir
      final granted = await NotificationService.requestPermission();
      if (!granted) {
        _toast("Bildirim izni verilmedi. Telefon ayarlarından açabilirsin.");
        return;
      }
    }
    await reminderStore.setEnabled(on);
    // await sonrası ekran kapanmış olabilir: kontrol et
    if (on && mounted) {
      final t = reminderStore.time.format(context);
      _toast("Her gün $t'da günün sözü gelecek ✦");
    }
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: reminderStore.time);
    if (t != null) await reminderStore.setTime(t);
  }

  Future<void> _testNotification() async {
    if (!await NotificationService.requestPermission()) {
      _toast("Bildirim izni verilmedi.");
      return;
    }
    final q = QuoteEngine.pick(moodStore.items, quoteStore.quotes);
    await NotificationService.showNow(q.text, q.author);
  }

  // Çıkış yapınca AuthGate giriş ekranını kendiliğinden gösterir
  void _logout() => authStore.logout();

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
        const SectionTitle(
          "Günün sözü",
          subtitle: "İstersen kilit ekranına ve ana ekrana gelsin",
        ),
        const SizedBox(height: 12),
        SoftCard(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListenableBuilder(
            listenable: reminderStore,
            builder: (context, _) => Column(
              children: [
                SwitchListTile(
                  value: reminderStore.enabled,
                  onChanged: DailySync.supported ? _toggleReminder : null,
                  title: const Text("Günlük bildirim"),
                  subtitle: Text(
                    DailySync.supported
                        ? "Kilit ekranında günün sözü"
                        : "Yalnızca telefonda kullanılabilir",
                    style: TextStyle(color: p.textSecondary),
                  ),
                ),
                if (reminderStore.enabled) ...[
                  Divider(color: p.border, height: 1),
                  ListTile(
                    leading: Icon(Icons.schedule_rounded, color: p.primary),
                    title: const Text("Saat"),
                    trailing: Text(
                      reminderStore.time.format(context),
                      style: TextStyle(fontWeight: FontWeight.w800, color: p.primary),
                    ),
                    onTap: _pickTime,
                  ),
                  Divider(color: p.border, height: 1),
                  ListTile(
                    leading: Icon(Icons.notifications_active_outlined, color: p.primary),
                    title: const Text("Deneme bildirimi gönder"),
                    onTap: _testNotification,
                  ),
                ],
                if (_canPinWidget) ...[
                  Divider(color: p.border, height: 1),
                  ListTile(
                    leading: Icon(Icons.widgets_outlined, color: p.primary),
                    title: const Text("Ana ekrana widget ekle"),
                    subtitle: Text("İnce, tek satırlık söz şeridi",
                        style: TextStyle(color: p.textSecondary)),
                    onTap: () => HomeWidget.requestPinWidget(androidName: 'QuoteWidgetProvider'),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // ---- Danışmanım ----
        const MyCounselorsSection(),
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
                title: Text(authStore.user?.displayName ?? "—"),
                subtitle: Text(
                  "${authStore.email}\nKayıtların buluta yedekleniyor ☁",
                  style: TextStyle(color: p.textSecondary),
                ),
                isThreeLine: true,
              ),
              Divider(color: p.border, height: 1),
              // Admin / danışman, kendi günlüğündeyken panele buradan döner
              if (authStore.isAdmin || authStore.isCounselor) ...[
                ListTile(
                  leading: Icon(Icons.admin_panel_settings_outlined, color: p.primary),
                  title: Text(authStore.isAdmin ? "Admin paneline dön" : "Danışman paneline dön"),
                  onTap: () => authStore.setViewAsUser(false),
                ),
                Divider(color: p.border, height: 1),
              ],
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
