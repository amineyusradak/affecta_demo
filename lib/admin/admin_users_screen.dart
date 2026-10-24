import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../data/auth_store.dart';
import '../models/app_user.dart';
import '../theme/app_theme.dart' show PaletteX;
import '../widgets/premium.dart';

/// Admin: kullanıcı listesi ve rol yönetimi.
/// Sadece profil bilgileri görünür; kullanıcının kayıtları/notları görünmez.
class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  Future<void> _changeRole(BuildContext context, AppUser u) async {
    const roles = {
      'user': ("Danışan", "Kendi günlüğünü tutar; istediği danışmana bağlanabilir."),
      'counselor': ("Danışman", "Davet koduyla danışan kabul eder, danışanların paylaştıklarını görür, kendi sözlerini ekler."),
      'admin': ("Admin", "Genel sözleri ve kullanıcı rollerini yönetir. Kimsenin kişisel kaydını göremez."),
    };

    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text("${u.displayName} için rol seç",
                  style: Theme.of(c).textTheme.headlineSmall),
            ),
            for (final r in roles.entries)
              ListTile(
                leading: Icon(
                  r.key == u.role ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: c.palette.primary,
                ),
                title: Text(r.value.$1),
                subtitle: Text(r.value.$2, style: const TextStyle(fontSize: 12)),
                onTap: () => Navigator.pop(c, r.key),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (picked == null || picked == u.role) return;
    await FirebaseFirestore.instance.doc('users/${u.uid}').update({'role': picked});
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${u.displayName} artık ${roles[picked]!.$1}")),
      );
    }
  }

  String _date(DateTime? d) => d == null
      ? ""
      : "${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}";

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('users')
          .orderBy('createdAt', descending: true)
          .limit(200)
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Text("Kullanıcılar yüklenemedi: ${snap.error}"));
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());

        final users = snap.data!.docs.map((d) => AppUser.fromMap(d.id, d.data())).toList();

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          itemCount: users.length + 1,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            if (i == 0) {
              return Text("${users.length} kullanıcı · rolünü değiştirmek için uzun bas",
                  style: TextStyle(color: p.textSecondary));
            }
            final u = users[i - 1];
            final isMe = u.uid == authStore.uid;

            return SoftCard(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: (u.isAdmin ? p.accent : p.primary).withValues(alpha: 0.18),
                  child: Text(
                    u.displayName.characters.first.toUpperCase(),
                    style: TextStyle(
                      color: u.isAdmin ? p.accent : p.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                title: Text(isMe ? "${u.displayName} (sen)" : u.displayName),
                subtitle: Text(
                  "${u.email}\nKatılım: ${_date(u.createdAt)}",
                  style: TextStyle(color: p.textSecondary, fontSize: 12),
                ),
                isThreeLine: true,
                trailing: u.role == 'user'
                    ? null
                    : Chip(
                        label: Text(AppUser.roleLabel(u.role)),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: (u.isAdmin ? p.accent : p.primary).withValues(alpha: 0.18),
                        side: BorderSide.none,
                      ),
                // Kendi rolünü buradan değiştirme (yanlışlıkla kilitlenmeyi önler)
                onLongPress: isMe ? null : () => _changeRole(context, u),
              ),
            );
          },
        );
      },
    );
  }
}
