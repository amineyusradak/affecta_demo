import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'screens/add_mood_screen.dart';
import 'screens/history_screen.dart';
import 'screens/report_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(const AffectaApp());
}

class AffectaApp extends StatelessWidget {
  const AffectaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Affecta',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
      ),
      home: const LoginScreen(),
      routes: {
        '/home': (_) => const HomeShell(),
      },
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

  final _pages = const [
    AddMoodScreen(),
    HistoryScreen(),
    ReportScreen(),
    SettingsScreen(),
  ];

  final _titles = const ["Mood Ekle", "Geçmiş", "Rapor", "Ayarlar"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Affecta • ${_titles[_index]}")),
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.add_reaction_outlined), label: "Ekle"),
          NavigationDestination(icon: Icon(Icons.history), label: "Geçmiş"),
          NavigationDestination(icon: Icon(Icons.insights_outlined), label: "Rapor"),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: "Ayarlar"),
        ],
      ),
    );
  }
}
