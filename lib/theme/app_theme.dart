import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ── Brand Color System ─────────────────────────────────────────────────
  static const Color primaryGold = Color(0xFFF5B400);
  static const Color secondaryOrange = Color(0xFFF57C00);
  static const Color accentDeepSaffron = Color(0xFFE85D04);
  
  static const Color successGreen = Color(0xFF2E7D32);
  static const Color errorRed = Color(0xFFD32F2F);
  
  static const Color bgDarkNavy = Color(0xFF0F1724);
  static const Color bgSecondary = Color(0xFF1A2235);
  static const Color cardColor = Color(0xFF202B3D);
  static const Color borderColor = Color(0xFF2D3B55);
  
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFC7CEDB);
  static const Color textMuted = Color(0xFF8D96A7);

  static const Color bgLight = Color(0xFFF8F9FA);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE2E8F0);
  
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color textMutedLight = Color(0xFF94A3B8);

  // ── Typography ─────────────────────────────────────────────────────────
  static TextTheme _buildTextTheme(TextTheme base, Color pColor, Color sColor, Color mColor) {
    return GoogleFonts.interTextTheme(base).copyWith(
      displayLarge: GoogleFonts.poppins(color: pColor, fontWeight: FontWeight.bold),
      displayMedium: GoogleFonts.poppins(color: pColor, fontWeight: FontWeight.bold),
      displaySmall: GoogleFonts.poppins(color: pColor, fontWeight: FontWeight.bold),
      headlineLarge: GoogleFonts.poppins(color: pColor, fontWeight: FontWeight.bold),
      headlineMedium: GoogleFonts.poppins(color: pColor, fontWeight: FontWeight.w600),
      headlineSmall: GoogleFonts.poppins(color: pColor, fontWeight: FontWeight.w600),
      titleLarge: GoogleFonts.poppins(color: pColor, fontWeight: FontWeight.w600, fontSize: 20),
      titleMedium: GoogleFonts.poppins(color: pColor, fontWeight: FontWeight.w500, fontSize: 16),
      titleSmall: GoogleFonts.poppins(color: sColor, fontWeight: FontWeight.w500, fontSize: 14),
      bodyLarge: GoogleFonts.inter(color: pColor, fontSize: 16),
      bodyMedium: GoogleFonts.inter(color: sColor, fontSize: 14),
      bodySmall: GoogleFonts.inter(color: mColor, fontSize: 12),
      labelLarge: GoogleFonts.inter(color: pColor, fontWeight: FontWeight.w600, fontSize: 14),
      labelMedium: GoogleFonts.inter(color: sColor, fontWeight: FontWeight.w500, fontSize: 12),
      labelSmall: GoogleFonts.inter(color: mColor, fontWeight: FontWeight.w500, fontSize: 10, letterSpacing: 1.0),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  DARK THEME (DalSetu Premium Enterprise)
  // ═══════════════════════════════════════════════════════════════════════
  static ThemeData get darkTheme {
    final textTheme = _buildTextTheme(ThemeData.dark().textTheme, textPrimary, textSecondary, textMuted);

    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryGold,
      scaffoldBackgroundColor: bgDarkNavy,
      textTheme: textTheme,
      
      colorScheme: const ColorScheme.dark(
        primary: primaryGold,
        onPrimary: bgDarkNavy,
        secondary: secondaryOrange,
        onSecondary: Colors.white,
        error: errorRed,
        onError: Colors.white,
        surface: cardColor,
        onSurface: Colors.white,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: bgDarkNavy,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: primaryGold),
        titleTextStyle: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),

      cardColor: cardColor,
      cardTheme: CardThemeData(
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: borderColor, width: 1),
        ),
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.2),
      ),

      dividerColor: borderColor,
      iconTheme: const IconThemeData(color: primaryGold),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgSecondary,
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryGold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorRed, width: 1.5),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGold,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: primaryGold.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryGold,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: secondaryOrange,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryGold;
          return Colors.transparent;
        }),
        side: const BorderSide(color: borderColor, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryGold;
          return textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryGold.withValues(alpha: 0.3);
          }
          return borderColor;
        }),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: bgDarkNavy,
        elevation: 8,
        selectedItemColor: primaryGold,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  LIGHT THEME (DalSetu Fresh & Bright)
  // ═══════════════════════════════════════════════════════════════════════
  static ThemeData get lightTheme {
    final textTheme = _buildTextTheme(ThemeData.light().textTheme, textPrimaryLight, textSecondaryLight, textMutedLight);

    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryGold,
      scaffoldBackgroundColor: bgLight,
      textTheme: textTheme,
      
      colorScheme: const ColorScheme.light(
        primary: primaryGold,
        onPrimary: Colors.white,
        secondary: secondaryOrange,
        onSecondary: Colors.white,
        error: errorRed,
        onError: Colors.white,
        surface: cardLight,
        onSurface: textPrimaryLight,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: cardLight,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: textPrimaryLight),
        titleTextStyle: GoogleFonts.poppins(
          color: textPrimaryLight,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),

      cardColor: cardLight,
      cardTheme: CardThemeData(
        color: cardLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: borderLight, width: 1),
        ),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.05),
      ),

      dividerColor: borderLight,
      iconTheme: const IconThemeData(color: textSecondaryLight),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardLight,
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        hintStyle: const TextStyle(color: textMutedLight, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryGold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorRed, width: 1.5),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGold,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: primaryGold.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryGold,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: secondaryOrange,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryGold;
          return Colors.transparent;
        }),
        side: const BorderSide(color: borderLight, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryGold;
          return textMutedLight;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryGold.withValues(alpha: 0.3);
          }
          return borderLight;
        }),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: cardLight,
        elevation: 12,
        selectedItemColor: primaryGold,
        unselectedItemColor: textMutedLight,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
