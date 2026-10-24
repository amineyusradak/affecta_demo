import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'admin/admin_shell.dart';
import 'data/auth_store.dart';
import 'counselor/counselor_shell.dart';
import 'data/daily_store.dart';
import 'data/link_store.dart';
import 'data/mood_store.dart';
import 'data/quote_store.dart';
import 'data/reminder_store.dart';
import 'data/theme_store.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'services/daily_sync.dart';
import 'screens/add_mood_screen.dart';
import 'screens/history_screen.dart';
import 'screens/report_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/today_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/premium.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase'e bağlan (ayarlar flutterfire configure ile üretilen dosyadan)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Telefondaki ayarları oku
  await Future.wait([themeStore.load(), dailyStore.load(), quoteStore.load(), reminderStore.load()]);

  // Giriş durumunu dinle; kim giriş yaparsa kayıtları onun hesabından gelsin
  authStore.start();
  authStore.addListener(() {
    moodStore.bindUser(authStore.uid);
    linkStore.bindUser(authStore.uid);
  });
  // Bağlı olduğum danışmanların sözlerini getir
  linkStore.addListener(
    () => quoteStore.bindCounselors(linkStore.links.map((l) => l.counselorId).toList()),
  );

  runApp(const AffectaApp());
  // Widget ve bildirimleri arka planda güncelle (açılışı bekletmez)
  DailySync.start();
}

class AffectaApp extends StatelessWidget {
  const AffectaApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Tema değişince tüm uygulama yeniden çizilir
    return ListenableBuilder(
      listenable: themeStore,
      builder: (context, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Affecta',
        // Türkçe: saat seçici, tarih ve butonlar Türkçe ve 24 saat biçiminde
        locale: const Locale('tr'),
        supportedLocales: const [Locale('tr')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeStore.mode,
        home: const AuthGate(),
      ),
    );
  }
}

/// Hangi ekranın açılacağına karar verir:
/// giriş yok → Giriş, admin → Admin paneli, danışman → Danışman paneli,
/// diğerleri (danışanlar) → Kullanıcı paneli
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: authStore,
      builder: (context, _) {
        // AnimatedSwitcher: paneller arası yumuşak geçiş
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: switch (authStore) {
            AuthStore(ready: false) => const _Splash(),
            AuthStore(isLoggedIn: false) => const LoginScreen(),
            AuthStore(showAdminPanel: true) => const AdminShell(),
            AuthStore(showCounselorPanel: true) => const CounselorShell(),
            _ => HomeShell(key: ValueKey(authStore.uid)),
          },
        );
      },
    );
  }
}

/// Giriş durumu kontrol edilirken görünen kısa açılış ekranı
class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuraBackground(
        child: Center(
          child: Text('☾', style: AppTheme.symbol(64, context.palette.primary)),
        ),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  final _titles = const ["Affecta", "Yeni Kayıt", "Geçmiş", "Rapor", "Ayarlar"];

  @override
  Widget build(BuildContext context) {
    final pages = [
      TodayScreen(onWriteEntry: () => setState(() => _index = 1)),
      const AddMoodScreen(),
      const HistoryScreen(),
      const ReportScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: Text(_titles[_index])),
      body: AuraBackground(child: SafeArea(child: pages[_index])),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.auto_awesome_outlined), selectedIcon: Icon(Icons.auto_awesome), label: "Bugün"),
          NavigationDestination(icon: Icon(Icons.edit_note_outlined), selectedIcon: Icon(Icons.edit_note), label: "Kayıt"),
          NavigationDestination(icon: Icon(Icons.book_outlined), selectedIcon: Icon(Icons.book), label: "Geçmiş"),
          NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: "Rapor"),
          NavigationDestination(icon: Icon(Icons.tune_outlined), selectedIcon: Icon(Icons.tune), label: "Ayarlar"),
        ],
      ),
    );
  }
}
