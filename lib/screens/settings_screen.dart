import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notif = true;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 0,
              child: SwitchListTile(
                value: _notif,
                onChanged: (v) => setState(() => _notif = v),
                title: const Text("Bildirimler (demo)"),
                subtitle: const Text("Gerçekte: günlük hatırlatma bildirimi planlanacak."),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              child: const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text("Hakkında"),
                subtitle: Text("Affecta • Web Demo • Sunum için prototype"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
