import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Bir temanın (açık / koyu) tüm renkleri.
/// ThemeExtension sayesinde her ekranda `context.palette` ile okunur
/// ve tema değişince otomatik güncellenir.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color background;
  final Color surface; // kart zemini
  final Color surfaceHigh; // seçili / vurgulu zemin
  final Color border;
  final Color primary; // lavanta vurgu (ikon, link)
  final Color accent; // şeftali vurgu
  final Color textPrimary;
  final Color textSecondary;
  final List<Color> backgroundGradient;
  final Color glowA; // arka plandaki ışık hareleri
  final Color glowB;

  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceHigh,
    required this.border,
    required this.primary,
    required this.accent,
    required this.textPrimary,
    required this.textSecondary,
    required this.backgroundGradient,
    required this.glowA,
    required this.glowB,
  });

  /// ☀️ Açık tema: krem zemin, lavanta + şeftali pastel
  static const light = AppPalette(
    background: Color(0xFFFBF8F5),
    surface: Color(0xFFFFFFFF),
    surfaceHigh: Color(0xFFF4EFFA),
    border: Color(0xFFECE5F3),
    primary: Color(0xFF8E7AE0),
    accent: Color(0xFFE99A7C),
    textPrimary: Color(0xFF2E2A3D),
    textSecondary: Color(0xFF7D7791),
    backgroundGradient: [Color(0xFFF1EAFF), Color(0xFFFBF8F5), Color(0xFFFFF0E8)],
    glowA: Color(0xFFCDBDFF),
    glowB: Color(0xFFFFD3BE),
  );

  /// 🌙 Koyu tema: zifiri değil, yumuşak mor-gri
  static const dark = AppPalette(
    background: Color(0xFF1E1B29),
    surface: Color(0xFF282436),
    surfaceHigh: Color(0xFF332E45),
    border: Color(0xFF3D3852),
    primary: Color(0xFFC3B4FF),
    accent: Color(0xFFF5C6B4),
    textPrimary: Color(0xFFF3F0FA),
    textSecondary: Color(0xFFABA5C0),
    backgroundGradient: [Color(0xFF2B2542), Color(0xFF1E1B29), Color(0xFF241E2A)],
    glowA: Color(0xFF8E7AE0),
    glowB: Color(0xFFE3A58F),
  );

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(AppPalette? other, double t) =>
      (other == null || t < 0.5) ? this : other;
}

/// Kısayol: `context.palette.primary`
extension PaletteX on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}

/// Temadan bağımsız sabit pastel renkler.
class AppColors {
  /// Ana buton gradyanı (iki temada da aynı)
  static const buttonGradient = LinearGradient(
    colors: [Color(0xFFF9C6D3), Color(0xFFC9B8FF)],
  );
  static const onButton = Color(0xFF2E2A3D);

  /// Her mood puanının pastel rengi (1 = çok kötü … 5 = harika)
  static const moods = {
    1: Color(0xFFC9C3E6), // sisli lavanta
    2: Color(0xFFB9D7F2), // gök mavisi
    3: Color(0xFFF6E3A8), // tereyağı sarısı
    4: Color(0xFFB8E0D2), // nane
    5: Color(0xFFF7B9C9), // pembe
  };

  static Color mood(int m) => moods[m] ?? moods[3]!;

  /// Pastel bir rengin koyu tonu: sembol ve yazılarda okunurluk için
  static Color deep(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness(0.42).withSaturation((hsl.saturation * 0.8).clamp(0, 1)).toColor();
  }
}

/// Pastel rengin temaya uygun okunur tonu:
/// açık temada koyulaştırır, koyu temada açar.
extension InkX on BuildContext {
  Color ink(Color c) {
    if (Theme.of(this).brightness == Brightness.light) return AppColors.deep(c);
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness(0.80).toColor();
  }
}

class AppTheme {
  static ThemeData light() => _build(Brightness.light, AppPalette.light);
  static ThemeData dark() => _build(Brightness.dark, AppPalette.dark);

  /// Başlık yazı tipi: Cormorant Garamond (zarif, mistik)
  static TextStyle serif(double size, Color color, [FontWeight w = FontWeight.w600]) =>
      GoogleFonts.cormorantGaramond(fontSize: size, fontWeight: w, color: color, height: 1.1);

  /// Kart sembolleri için yazı tipi (emoji yerine zarif çizgi semboller)
  static TextStyle symbol(double size, Color color) => GoogleFonts.notoSansSymbols(
        fontSize: size,
        color: color,
        height: 1,
      ).copyWith(fontFamilyFallback: [GoogleFonts.notoSansSymbols2().fontFamily!]);

  static ThemeData _build(Brightness b, AppPalette p) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: ColorScheme.fromSeed(
        seedColor: p.primary,
        brightness: b,
        primary: p.primary,
        secondary: p.accent,
        surface: p.surface,
        onSurface: p.textPrimary,
      ),
      scaffoldBackgroundColor: p.background,
      extensions: [p],
    );

    // Gövde yazıları: Manrope (modern, okunaklı)
    final body = GoogleFonts.manropeTextTheme(base.textTheme).apply(
      bodyColor: p.textPrimary,
      displayColor: p.textPrimary,
    );

    OutlineInputBorder field(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: c, width: w),
        );

    return base.copyWith(
      textTheme: body.copyWith(
        displayMedium: serif(42, p.textPrimary),
        headlineMedium: serif(30, p.textPrimary),
        headlineSmall: serif(25, p.textPrimary),
        titleLarge: serif(22, p.textPrimary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: p.textPrimary,
        titleTextStyle: serif(26, p.textPrimary),
        // Saat/pil simgeleri: açık temada koyu, koyu temada açık
        systemOverlayStyle: b == Brightness.light
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        labelStyle: TextStyle(color: p.textSecondary),
        hintStyle: TextStyle(color: p.textSecondary),
        prefixIconColor: p.textSecondary,
        border: field(p.border),
        enabledBorder: field(p.border),
        focusedBorder: field(p.primary, 1.5),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: p.primary.withValues(alpha: 0.18),
        height: 68,
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            color: s.contains(WidgetState.selected) ? p.primary : p.textSecondary,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: s.contains(WidgetState.selected) ? p.primary : p.textSecondary,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.textPrimary,
        contentTextStyle: TextStyle(color: p.background),
        actionTextColor: AppColors.moods[5],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
      ),
    );
  }
}
