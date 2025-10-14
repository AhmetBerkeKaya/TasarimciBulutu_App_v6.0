import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // 1. RENK PALETLERİ
  //============================================================================
  // Açık Tema Renkleri
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightPrimary = Color(0xFF2563EB);
  static const Color lightSecondary = Color(0xFF94A3B8);
  static const Color lightText = Color(0xFF1E293B);
  static const Color lightError = Color(0xFFDC2626);
  static const Color lightLogoBackground = Color(0xFFE3F2FD); // Açık primarinin daha açık bir tonu

  // Koyu Tema Renkleri
  static const Color darkBackground = Color(0xFF1F2D50);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkPrimary = Color(0xFF3B82F6);
  static const Color darkSecondary = Color(0xFF64748B);
  static const Color darkText = Color(0xFFF1F5F9);
  static const Color darkError = Color(0xFFEF4444);
  static const Color darkLogoBackground = Colors.white12; // Hafif şeffaf beyaz


  static const LinearGradient lightPrimaryGradient = LinearGradient(
    colors: [Color(0xFF4B89FF), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkPrimaryGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // 2. TEMA OLUŞTURUCU FONKSİYON
  //============================================================================
  // Bu merkezi fonksiyon, bir renk şeması alıp tam bir tema döndürür.
  static ThemeData _buildTheme({required bool isDarkMode}) {
    // Önce temaya özel renkleri belirliyoruz
    final colorScheme = isDarkMode
        ? const ColorScheme.dark(
      primary: darkPrimary,
      secondary: darkSecondary,
      surface: darkCard,
      background: darkBackground,
      error: darkError,
      onPrimary: Colors.white,
      onSecondary: darkText,
      onSurface: darkText,
      onBackground: darkText,
      onError: Colors.white,
    )
        : const ColorScheme.light(
      primary: lightPrimary,
      secondary: lightSecondary,
      surface: lightCard,
      background: lightBackground,
      error: lightError,
      onPrimary: Colors.white,
      onSecondary: lightText,
      onSurface: lightText,
      onBackground: lightText,
      onError: Colors.white,
    );

    // Sonra bu renkleri kullanarak tam temayı oluşturuyoruz
    return ThemeData(
      brightness: isDarkMode ? Brightness.dark : Brightness.light,
      primaryColor: colorScheme.primary,
      scaffoldBackgroundColor: colorScheme.background,
      cardColor: colorScheme.surface,

      // Yazı tiplerini ve renklerini doğrudan renk şemasına göre ayarla
      textTheme: GoogleFonts.manropeTextTheme(ThemeData(brightness: colorScheme.brightness).textTheme).apply(
        bodyColor: colorScheme.onBackground,
        displayColor: colorScheme.onBackground,
      ),

      // AppBar teması
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: colorScheme.background,
        iconTheme: IconThemeData(color: colorScheme.onBackground),
        titleTextStyle: GoogleFonts.manrope(
          color: colorScheme.onBackground,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Card teması
      cardTheme: CardThemeData(
        elevation: 1,
        color: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),

      // Buton teması
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 1,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          textStyle: GoogleFonts.manrope(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
      ),

      // Input teması
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),

      // Chip teması
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.primary.withOpacity(0.15),
        labelStyle: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
      ),

      // Alt Navigasyon Barı teması
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.secondary,
        elevation: 5,
      ),
    );
  }

  // 3. SONUÇ TEMALARI
  //============================================================================
  // Merkezi fonksiyonumuzu çağırarak açık ve koyu temaları oluşturuyoruz
  static final ThemeData lightTheme = _buildTheme(isDarkMode: false);
  static final ThemeData darkTheme = _buildTheme(isDarkMode: true);
}