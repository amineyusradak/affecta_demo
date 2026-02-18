import 'package:flutter/material.dart';
import '../data/auth_store.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isRegister = false;

  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    _pass2.dispose();
    super.dispose();
  }

  bool _isValidEmail(String s) {
    final r = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return r.hasMatch(s.trim());
  }

  void _submit() {
    final email = _email.text.trim();
    final pass = _pass.text;

    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen geçerli bir e-posta gir.")),
      );
      return;
    }
    if (pass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Şifre en az 6 karakter olmalı.")),
      );
      return;
    }

    if (_isRegister) {
      if (_pass2.text != pass) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Şifreler aynı değil.")),
        );
        return;
      }
      authStore.register(email: email, password: pass);
    } else {
      authStore.login(email: email, password: pass);
    }

    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Affecta",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _isRegister ? "Hesap oluştur" : "Giriş yap",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: _email,
                  decoration: const InputDecoration(
                    labelText: "E-posta",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _pass,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Şifre",
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_isRegister) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _pass2,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Şifre (tekrar)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _submit,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(_isRegister ? "Kayıt Ol" : "Giriş Yap"),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => setState(() => _isRegister = !_isRegister),
                  child: Text(_isRegister
                      ? "Zaten hesabın var mı? Giriş yap"
                      : "Hesabın yok mu? Kayıt ol"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
