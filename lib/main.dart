import 'package:flutter/material.dart';

import 'data/daily_store.dart';
import 'data/mood_store.dart';
import 'data/quote_store.dart';
import 'data/theme_store.dart';
import 'screens/login_screen.dart';
import 'screens/add_mood_screen.dart';
import 'screens/history_screen.dart';
import 'screens/report_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/today_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/premium.dart';

Future<void> main() async {
  // Uygulama açılmadan önce kayıtlı verileri ve tema seçimini oku
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([moodStore.load(), themeStore.load(), dailyStore.load(), quoteStore.load()]);
  runApp(const AffectaApp());
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
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeStore.mode,
        home: const LoginScreen(),
        routes: {
          '/login': (_) => const LoginScreen(),
          '/home': (_) => const HomeShell(),
        },
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
