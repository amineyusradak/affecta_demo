import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore'daki users/{uid} belgesi.
class AppUser {
  final String uid;
  final String email;
  final String name;

  /// "user" (danışan), "counselor" (danışman) veya "admin".
  /// Kullanıcı kendi rolünü değiştiremez
  /// (Firestore güvenlik kuralları engeller).
  final String role;
  final DateTime? createdAt;

  const AppUser({
    required this.uid,
    required this.email,
    required this.name,
    this.role = 'user',
    this.createdAt,
  });

  bool get isAdmin => role == 'admin';
  bool get isCounselor => role == 'counselor';

  static String roleLabel(String role) => switch (role) {
        'admin' => 'Admin',
        'counselor' => 'Danışman',
        _ => 'Danışan',
      };

  /// Görünen ad: ad yoksa e-postanın @ öncesi
  String get displayName => name.isNotEmpty ? name : email.split('@').first;

  factory AppUser.fromMap(String uid, Map<String, dynamic> m) => AppUser(
        uid: uid,
        email: m['email'] as String? ?? '',
        name: m['name'] as String? ?? '',
        role: m['role'] as String? ?? 'user',
        createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
      );
}
