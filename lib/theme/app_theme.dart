import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ── Brand Colors (from DaalSetu logo) ──────────────────────────────────
  static const Color primaryGold = Color(0xFFFFB300);
  static const Color accentOrange = Color(0xFFFF6D00);
  static const Color accentRed = Color(0xFFE53935);
  static const Color goldenAccent = Color(0xFFFFD54F);

  // ── Light Mode Surfaces ────────────────────────────────────────────────
  static const Color _lightBg = Color(0xFFFFFCF5);
  static const Color _lightCard = Colors.white;
  static const Color _lightSurface = Color(0xFFF9FAFB);

  // ── Dark Mode Surfaces ─────────────────────────────────────────────────
  static const Color _darkBg = Color(0xFF0D1117);
  static const Color _darkCard = Color(0xFF161E2E);
  static const Color _darkSurface = Color(0xFF1A2332);

  // ── Typography ─────────────────────────────────────────────────────────
  static TextTheme _buildTextTheme(TextTheme base, bool isDark) {
    final Color textPrimary = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final Color textSecondary =
        isDark ? const Color(0xFFB0BEC5) : const Color(0xFF5F6B7A);

    return GoogleFonts.interTextTheme(base).copyWith(
      displayLarge: GoogleFonts.poppins(
        color: textPrimary,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: GoogleFonts.poppins(
        color: textPrimary,
        fontWeight: FontWeight.bold,
      ),
      displaySmall: GoogleFonts.poppins(
        color: textPrimary,
        fontWeight: FontWeight.bold,
      ),
      headlineLarge: GoogleFonts.poppins(
        color: textPrimary,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: GoogleFonts.poppins(
        color: textPrimary,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: GoogleFonts.poppins(
        color: textPrimary,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: GoogleFonts.poppins(
        color: textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 20,
      ),
      titleMedium: GoogleFonts.poppins(
        color: textPrimary,
        fontWeight: FontWeight.w500,
        fontSize: 16,
      ),
      titleSmall: GoogleFonts.poppins(
        color: textSecondary,
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
      bodyLarge: GoogleFonts.inter(color: textPrimary, fontSize: 16),
      bodyMedium: GoogleFonts.inter(color: textSecondary, fontSize: 14),
      bodySmall: GoogleFonts.inter(color: textSecondary, fontSize: 12),
      labelLarge: GoogleFonts.inter(
        color: textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      labelMedium: GoogleFonts.inter(
        color: textSecondary,
        fontWeight: FontWeight.w500,
        fontSize: 12,
      ),
      labelSmall: GoogleFonts.inter(
        color: textSecondary,
        fontWeight: FontWeight.w500,
        fontSize: 10,
        letterSpacing: 1.0,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  LIGHT THEME
  // ═══════════════════════════════════════════════════════════════════════
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primaryGold,
    scaffoldBackgroundColor: _lightBg,
    textTheme: _buildTextTheme(ThemeData.light().textTheme, false),

    colorScheme: const ColorScheme.light(
      primary: primaryGold,
      onPrimary: Colors.white,
      secondary: accentOrange,
      onSecondary: Colors.white,
      error: accentRed,
      onError: Colors.white,
      surface: _lightCard,
      onSurface: Color(0xFF1A1A2E),
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: const IconThemeData(color: Color(0xFF1A1A2E)),
      titleTextStyle: GoogleFonts.poppins(
        color: const Color(0xFF1A1A2E),
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),

    cardColor: _lightCard,

    dividerColor: const Color(0xFFE8ECF0),

    iconTheme: const IconThemeData(color: Color(0xFF5F6B7A)),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.7),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Colors.white.withValues(alpha: 0.3),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Colors.white.withValues(alpha: 0.3),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryGold, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: accentRed),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryGold,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryGold,
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
      ),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: accentOrange,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return primaryGold;
        return const Color(0xFFBDBDBD);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryGold.withValues(alpha: 0.3);
        }
        return const Color(0xFFE0E0E0);
      }),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
    ),
  );

  // ═══════════════════════════════════════════════════════════════════════
  //  DARK THEME
  // ═══════════════════════════════════════════════════════════════════════
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryGold,
    scaffoldBackgroundColor: _darkBg,
    textTheme: _buildTextTheme(ThemeData.dark().textTheme, true),

    colorScheme: const ColorScheme.dark(
      primary: primaryGold,
      onPrimary: Color(0xFF1A1A2E),
      secondary: accentOrange,
      onSecondary: Colors.white,
      error: Color(0xFFEF5350),
      onError: Colors.white,
      surface: _darkCard,
      onSurface: Colors.white,
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: GoogleFonts.poppins(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),

    cardColor: _darkCard,

    dividerColor: const Color(0xFF2D3748),

    iconTheme: const IconThemeData(color: Color(0xFFB0BEC5)),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.06),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryGold, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFEF5350)),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryGold,
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryGold,
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
      ),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: accentOrange,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return primaryGold;
        return const Color(0xFF616161);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryGold.withValues(alpha: 0.3);
        }
        return const Color(0xFF424242);
      }),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
    ),
  );
}
