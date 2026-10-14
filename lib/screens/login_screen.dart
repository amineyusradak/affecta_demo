import 'package:flutter/material.dart';
import '../data/auth_store.dart';
import '../theme/app_theme.dart';
import '../widgets/premium.dart';

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
    final text = Theme.of(context).textTheme;
    final p = context.palette;

    return Scaffold(
      body: AuraBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo: altın çerçeveli ay simgesi
                    Center(
                      child: Container(
                        width: 92,
                        height: 92,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.buttonGradient,
                          boxShadow: [
                            BoxShadow(
                              color: p.glowA.withValues(alpha: 0.7),
                              blurRadius: 36,
                            ),
                          ],
                        ),
                        child: Text('☾', style: AppTheme.symbol(44, AppColors.onButton)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text("Affecta",
                        textAlign: TextAlign.center, style: text.displayMedium),
                    const SizedBox(height: 6),
                    Text(
                      "İçindeki sesi dinle.",
                      textAlign: TextAlign.center,
                      style: text.bodyLarge
                          ?.copyWith(color: p.textSecondary),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      _isRegister ? "Hesap oluştur" : "Tekrar hoş geldin",
                      style: text.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: "E-posta",
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _pass,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: "Şifre",
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                    if (_isRegister) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _pass2,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "Şifre (tekrar)",
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    GradientButton(
                      label: _isRegister ? "Kayıt Ol" : "Giriş Yap",
                      icon: Icons.auto_awesome,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => setState(() => _isRegister = !_isRegister),
                      child: Text(
                        _isRegister
                            ? "Zaten hesabın var mı? Giriş yap"
                            : "Hesabın yok mu? Kayıt ol",
                        style: TextStyle(color: p.primary, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
