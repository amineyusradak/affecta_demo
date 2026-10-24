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
  bool _busy = false; // istek sürerken butonu kilitle

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    _pass2.dispose();
    super.dispose();
  }

  bool _isValidEmail(String s) {
    final r = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return r.hasMatch(s.trim());
  }

  void _toast(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _submit() async {
    final email = _email.text.trim();
    final pass = _pass.text;

    if (!_isValidEmail(email)) return _toast("Lütfen geçerli bir e-posta gir.");
    if (pass.length < 6) return _toast("Şifre en az 6 karakter olmalı.");
    if (_isRegister && _pass2.text != pass) return _toast("Şifreler aynı değil.");

    setState(() => _busy = true);
    final error = _isRegister
        ? await authStore.register(name: _name.text.trim(), email: email, password: pass)
        : await authStore.login(email: email, password: pass);
    if (!mounted) return;
    setState(() => _busy = false);

    // Başarılıysa ekran değiştirmeye gerek yok: AuthGate girişi görüp
    // kullanıcıyı (veya admini) doğru panele kendiliğinden götürür.
    if (error != null) _toast(error);
  }

  Future<void> _forgotPassword() async {
    final email = _email.text.trim();
    if (!_isValidEmail(email)) {
      return _toast("Önce e-posta adresini yaz, sonra tekrar dokun.");
    }
    final error = await authStore.resetPassword(email);
    if (!mounted) return;
    _toast(error ?? "Şifre sıfırlama bağlantısı $email adresine gönderildi.");
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
                    if (_isRegister) ...[
                      TextField(
                        controller: _name,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: "Adın",
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
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
                    if (!_isRegister)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _busy ? null : _forgotPassword,
                          child: Text("Şifremi unuttum",
                              style: TextStyle(color: p.textSecondary)),
                        ),
                      )
                    else
                      const SizedBox(height: 24),
                    GradientButton(
                      label: _isRegister ? "Kayıt Ol" : "Giriş Yap",
                      icon: Icons.auto_awesome,
                      loading: _busy,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _busy ? null : () => setState(() => _isRegister = !_isRegister),
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
