import 'package:flutter/material.dart';

import '../data/auth_store.dart';
import '../widgets/premium.dart';
import 'admin_overview_screen.dart';
import 'admin_quotes_screen.dart';
import 'admin_users_screen.dart';

/// Admin paneli: kullanıcı panelinden tamamen ayrı bir ekran.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  static const _titles = ["Genel Bakış", "Sözler", "Kullanıcılar"];
  static const _pages = [AdminOverviewScreen(), AdminQuotesScreen(), AdminUsersScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(_titles[_index]),
        leading: const Padding(
          padding: EdgeInsets.only(left: 12),
          child: Center(child: _AdminBadge()),
        ),
        leadingWidth: 84,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (v) {
              if (v == 'user') authStore.setViewAsUser(true);
              if (v == 'logout') authStore.logout();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'user', child: Text("Kullanıcı görünümüne geç")),
              PopupMenuItem(value: 'logout', child: Text("Çıkış yap")),
            ],
          ),
        ],
      ),
      body: AuraBackground(child: SafeArea(child: _pages[_index])),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: "Genel"),
          NavigationDestination(icon: Icon(Icons.format_quote_outlined), selectedIcon: Icon(Icons.format_quote), label: "Sözler"),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: "Kullanıcılar"),
        ],
      ),
    );
  }
}

/// Sol üstte "ADMIN" rozeti: hangi panelde olduğun hep belli olsun
class _AdminBadge extends StatelessWidget {
  const _AdminBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(colors: [Color(0xFFF7C59F), Color(0xFFF9C6D3)]),
      ),
      child: const Text(
        "ADMIN",
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          color: Color(0xFF2E2A3D),
        ),
      ),
    );
  }
}
