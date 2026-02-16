// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // 1. RENK PALETİ (Soft Premium Dark)
  //============================================================================

  // --- AÇIK TEMA (Light) - Değişmedi, sevmiştin ---
  static const Color lightBackground = Color(0xFFF0F2F5);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightPrimary = Color(0xFF1E293B);
  static const Color lightSecondary = Color(0xFF64748B);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF94A3B8);
  static const Color lightError = Color(0xFFEF4444);

  // --- KOYU TEMA (Dark) - YENİLENDİ! ---
  // Eski zifiri karanlık yerine, göz yormayan modern "Koyu Antrasit"
  static const Color darkBackground = Color(0xFF181A20); // Daha yumuşak, elit bir siyah
  static const Color darkSurface = Color(0xFF262A35);    // Kartlar için bir tık daha açık ton
  static const Color darkPrimary = Color(0xFFFFFFFF);    // Primary artık Tam Beyaz (Siyah üzerinde en iyi kontrast)
  static const Color darkSecondary = Color(0xFF8E9AAF);  // İkincil yazılar için metalik gri
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB0B3B8);
  static const Color darkError = Color(0xFFFF5252);

  // Gradientler
  static const LinearGradient lightPrimaryGradient = LinearGradient(
    colors: [Color(0xFF334155), Color(0xFF0F172A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkPrimaryGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFE0E0E0)], // Beyaz -> Gümüş geçişi
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // 2. TEMA OLUŞTURUCU
  //============================================================================
  static ThemeData _buildTheme({required bool isDarkMode}) {
    final baseColorScheme = isDarkMode ? const ColorScheme.dark() : const ColorScheme.light();

    // Renkleri seç
    final bgColor = isDarkMode ? darkBackground : lightBackground;
    final surfaceColor = isDarkMode ? darkSurface : lightSurface;
    final primaryColor = isDarkMode ? darkPrimary : lightPrimary;
    final textColor = isDarkMode ? darkTextPrimary : lightTextPrimary;
    final secondaryTextColor = isDarkMode ? darkTextSecondary : lightTextSecondary;

    // Font Ayarları
    final baseTextTheme = GoogleFonts.manropeTextTheme(
      isDarkMode ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: isDarkMode ? Brightness.dark : Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: bgColor,
      cardColor: surfaceColor,

      // Renk Şeması
      colorScheme: baseColorScheme.copyWith(
        primary: primaryColor,
        secondary: isDarkMode ? darkSecondary : lightSecondary,
        surface: surfaceColor,
        background: bgColor,
        error: isDarkMode ? darkError : lightError,
        onPrimary: isDarkMode ? Colors.black : Colors.white, // Buton üzerindeki yazı rengi
        onSurface: textColor,
        onBackground: textColor,
      ),

      // --- TİPOGRAFİ ---
      textTheme: baseTextTheme.apply(
        bodyColor: textColor,
        displayColor: textColor,
      ).copyWith(
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800, color: textColor),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, color: textColor),
        titleLarge: baseTextTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: textColor),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: textColor),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: secondaryTextColor),
      ),

      // --- APP BAR ---
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textColor),
        titleTextStyle: GoogleFonts.manrope(
          color: textColor,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),

      // --- KARTLAR (Daha yumuşak) ---
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
        ),
        shadowColor: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
      ),

      // --- BUTONLAR ---
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: isDarkMode ? Colors.black : Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
      ),

      // --- INPUT ALANLARI (Yenilendi) ---
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        // Dark modda input rengini biraz daha belirgin yaptık (Transparan beyaz)
        fillColor: isDarkMode ? Colors.white.withOpacity(0.08) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        hintStyle: TextStyle(
            color: secondaryTextColor.withOpacity(0.5),
            fontWeight: FontWeight.w500
        ),

        // Kenarlık Yok, Yumuşaklık Var
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
          borderSide: BorderSide(
              color: isDarkMode ? Colors.white.withOpacity(0.5) : primaryColor,
              width: 1.5
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
          borderSide: BorderSide(color: isDarkMode ? darkError : lightError, width: 1),
        ),
      ),

      // --- ALT PENCERELER ---
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceColor,
        modalBackgroundColor: surfaceColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),

      iconTheme: IconThemeData(
        color: textColor,
        size: 24,
      ),
    );
  }

  static final ThemeData lightTheme = _buildTheme(isDarkMode: false);
  static final ThemeData darkTheme = _buildTheme(isDarkMode: true);
}