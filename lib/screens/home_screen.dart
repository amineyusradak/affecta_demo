import 'package:flutter/material.dart';
import 'add_mood_screen.dart';
import 'history_screen.dart';
import 'report_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _i = 0;

  final _pages = const [
    AddMoodScreen(),
    HistoryScreen(),
    ReportScreen(),
    SettingsScreen(),
  ];

  final _titles = const [
    "Mood Ekle",
    "Geçmiş",
    "Rapor",
    "Ayarlar",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_i]),
        centerTitle: true,
      ),
      body: _pages[_i],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _i,
        onDestinationSelected: (v) => setState(() => _i = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.add_circle_outline), label: "Ekle"),
          NavigationDestination(icon: Icon(Icons.history), label: "Geçmiş"),
          NavigationDestination(icon: Icon(Icons.insights), label: "Rapor"),
          NavigationDestination(icon: Icon(Icons.settings), label: "Ayarlar"),
        ],
      ),
    );
  }
}
