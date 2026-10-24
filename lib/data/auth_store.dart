import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';

/// Giriş durumu ve kullanıcı profili (Firebase Auth + users/{uid}).
class AuthStore extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  AppUser? _user;
  bool _ready = false;

  /// Admin veya danışman, isterse uygulamayı danışan gibi de kullanabilir
  /// (kendi mood kayıtlarını tutmak için)
  bool _viewAsUser = false;

  StreamSubscription? _profileSub;

  AppUser? get user => _user;
  bool get ready => _ready; // ilk giriş kontrolü bitti mi?
  bool get isLoggedIn => _user != null;
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isCounselor => _user?.isCounselor ?? false;
  bool get showAdminPanel => isAdmin && !_viewAsUser;
  bool get showCounselorPanel => isCounselor && !_viewAsUser;
  String get email => _user?.email ?? '';
  String? get uid => _user?.uid;

  void setViewAsUser(bool v) {
    _viewAsUser = v;
    notifyListeners();
  }

  /// Uygulama açılınca çağrılır: oturum değişikliklerini dinler.
  void start() {
    _auth.authStateChanges().listen((fbUser) {
      _profileSub?.cancel();

      if (fbUser == null) {
        _user = null;
        _viewAsUser = false;
        _ready = true;
        notifyListeners();
        return;
      }

      // Profil belgesini canlı dinle: admin rol değiştirirse hemen yansısın
      _profileSub = _db.doc('users/${fbUser.uid}').snapshots().listen((snap) async {
        if (!snap.exists) {
          // Kayıt sırasında profil yazılamadıysa şimdi oluştur.
          // Ad gönderilmez: kayıt ekranının yazdığı adın üzerine yazmasın.
          await _createProfile(fbUser.uid, fbUser.email ?? '');
          return;
        }
        _user = AppUser.fromMap(fbUser.uid, snap.data()!);
        _ready = true;
        notifyListeners();
      }, onError: (e) {
        debugPrint('Profil okunamadı: $e');
        // Kurallar yüklenmemişse bile en azından kullanıcı olarak devam et
        _user = AppUser(uid: fbUser.uid, email: fbUser.email ?? '', name: '');
        _ready = true;
        notifyListeners();
      });
    });
  }

  /// merge: var olan alanları silmeden yazar (iki yerden yazılsa da güvenli)
  Future<void> _createProfile(String uid, String email, [String? name]) =>
      _db.doc('users/$uid').set({
        'email': email,
        if (name != null) 'name': name,
        'role': 'user', // herkes "user" olarak başlar
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  /// Hata varsa Türkçe mesaj döner, başarılıysa null.
  Future<String?> login({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return authErrorMessage(e.code);
    }
  }

  Future<String?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      await _createProfile(cred.user!.uid, email, name);
      return null;
    } on FirebaseAuthException catch (e) {
      return authErrorMessage(e.code);
    }
  }

  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return authErrorMessage(e.code);
    }
  }

  Future<void> logout() => _auth.signOut();
}

/// Firebase hata kodlarını kullanıcı dostu Türkçe mesajlara çevirir.
String authErrorMessage(String code) => switch (code) {
      'invalid-email' => 'E-posta adresi geçerli değil.',
      'user-disabled' => 'Bu hesap devre dışı bırakılmış.',
      'user-not-found' || 'wrong-password' || 'invalid-credential' =>
        'E-posta veya şifre hatalı.',
      'email-already-in-use' => 'Bu e-posta ile zaten bir hesap var. Giriş yapmayı dene.',
      'weak-password' => 'Şifre çok zayıf. En az 6 karakter kullan.',
      'too-many-requests' => 'Çok fazla deneme yapıldı. Biraz bekleyip tekrar dene.',
      'network-request-failed' => 'İnternet bağlantısı yok gibi görünüyor.',
      _ => 'Bir şeyler ters gitti ($code). Tekrar dene.',
    };

final authStore = AuthStore();
