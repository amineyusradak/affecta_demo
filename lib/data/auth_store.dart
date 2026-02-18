import 'package:flutter/foundation.dart';

class AuthStore extends ChangeNotifier {
  bool _isLoggedIn = false;
  String? _email;

  bool get isLoggedIn => _isLoggedIn;
  String get email => _email ?? "";

  void login({required String email, required String password}) {
    // Demo backend yok: sadece doğrulama yapıp giriş yaptırıyoruz
    _isLoggedIn = true;
    _email = email;
    notifyListeners();
  }

  void register({required String email, required String password}) {
    // Demo backend yok: kayıt + otomatik giriş
    _isLoggedIn = true;
    _email = email;
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    _email = null;
    notifyListeners();
  }
}

final authStore = AuthStore();
