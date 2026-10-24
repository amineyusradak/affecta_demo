import 'package:flutter/material.dart';

import '../admin/admin_quotes_screen.dart';
import '../data/auth_store.dart';
import '../widgets/premium.dart';
import 'clients_screen.dart';
import 'invite_screen.dart';

/// Danışman paneli: danışanlar, danışmanın kendi sözleri ve davet kodu.
class CounselorShell extends StatefulWidget {
  const CounselorShell({super.key});

  @override
  State<CounselorShell> createState() => _CounselorShellState();
}

class _CounselorShellState extends State<CounselorShell> {
  int _index = 0;

  static const _titles = ["Danışanlarım", "Sözlerim", "Davet"];

  @override
  Widget build(BuildContext context) {
    final me = authStore.user!;
    final pages = [
      ClientsScreen(onOpenInvite: () => setState(() => _index = 2)),
      // Aynı söz ekranı: bu sözler sadece bu danışmanın danışanlarına görünür
      AdminQuotesScreen(counselorId: me.uid, counselorName: me.displayName),
      const InviteScreen(),
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (v) {
              if (v == 'user') authStore.setViewAsUser(true);
              if (v == 'logout') authStore.logout();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'user', child: Text("Kendi günlüğüme geç")),
              PopupMenuItem(value: 'logout', child: Text("Çıkış yap")),
            ],
          ),
        ],
      ),
      body: AuraBackground(child: SafeArea(child: pages[_index])),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: "Danışanlar"),
          NavigationDestination(icon: Icon(Icons.format_quote_outlined), selectedIcon: Icon(Icons.format_quote), label: "Sözlerim"),
          NavigationDestination(icon: Icon(Icons.qr_code_2_outlined), selectedIcon: Icon(Icons.qr_code_2), label: "Davet"),
        ],
      ),
    );
  }
}
