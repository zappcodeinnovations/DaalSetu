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
  static const Color borderLight = Color(0xFFCBD5E1);
  
  static const Color textPrimaryLight = Color(0xFF0A0F1D);
  static const Color textSecondaryLight = Color(0xFF1E293B);
  static const Color textMutedLight = Color(0xFF475569);

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
      titleSmall: GoogleFonts.poppins(color: sColor, fontWeight: FontWeight.w600, fontSize: 14),
      bodyLarge: GoogleFonts.inter(color: pColor, fontSize: 16, fontWeight: FontWeight.w600),
      bodyMedium: GoogleFonts.inter(color: sColor, fontSize: 14, fontWeight: FontWeight.w500),
      bodySmall: GoogleFonts.inter(color: mColor, fontSize: 12, fontWeight: FontWeight.w500),
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
      primaryColor: secondaryOrange,
      scaffoldBackgroundColor: bgDarkNavy,
      textTheme: textTheme,
      
      colorScheme: const ColorScheme.dark(
        primary: secondaryOrange,
        onPrimary: Colors.white,
        secondary: secondaryOrange,
        onSecondary: Colors.white,
        error: errorRed,
        onError: Colors.white,
        surface: cardColor,
        onSurface: Colors.white,
      ),

      // Chips (filter tabs): selected and unselected labels keep a high-contrast colour.
      chipTheme: ChipThemeData(
        labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        secondaryLabelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        checkmarkColor: Colors.white,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: bgDarkNavy,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: primaryGold),
        titleSpacing: 0,
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
          backgroundColor: secondaryOrange,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: secondaryOrange.withValues(alpha: 0.3),
          // Primary and secondary buttons share one size, so a pair (Accept / Cancel) is level.
          // No vertical padding: the 44 high minimum centres the label, and a button squeezed into
          // a shorter box (40-44) never clips its text. A pair of buttons shares one height.
          padding: const EdgeInsets.symmetric(horizontal: 16),
          minimumSize: const Size(96, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: secondaryOrange,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),

      // Secondary / Cancel actions: outlined in the brand orange, brand orange border.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: secondaryOrange,
          foregroundColor: Colors.white,
          // No vertical padding: the 44 high minimum centres the label, and a button squeezed into
          // a shorter box (40-44) never clips its text. A pair of buttons shares one height.
          padding: const EdgeInsets.symmetric(horizontal: 16),
          minimumSize: const Size(96, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: secondaryOrange,
          side: const BorderSide(color: secondaryOrange, width: 1.2),
          // No vertical padding: the 44 high minimum centres the label, and a button squeezed into
          // a shorter box (40-44) never clips its text. A pair of buttons shares one height.
          padding: const EdgeInsets.symmetric(horizontal: 16),
          minimumSize: const Size(96, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15),
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
          if (states.contains(WidgetState.selected)) return secondaryOrange;
          return textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return secondaryOrange.withValues(alpha: 0.38);
          }
          return borderColor;
        }),
      ),

      dialogTheme: DialogThemeData(
        // Even room around the Accept / Cancel pair.
        actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderColor, width: 1.2),
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: bgDarkNavy,
        elevation: 8,
        selectedItemColor: primaryGold,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
      ),

      timePickerTheme: TimePickerThemeData(
        backgroundColor: bgDarkNavy,
        hourMinuteTextColor: Colors.white,
        hourMinuteColor: cardColor,
        dayPeriodTextColor: Colors.white,
        dayPeriodColor: cardColor,
        dialHandColor: primaryGold,
        dialBackgroundColor: cardColor,
        dialTextColor: Colors.white,
        entryModeIconColor: primaryGold,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
      primaryColor: secondaryOrange,
      scaffoldBackgroundColor: bgLight,
      textTheme: textTheme,
      
      colorScheme: const ColorScheme.light(
        primary: secondaryOrange,
        onPrimary: Colors.white,
        secondary: secondaryOrange,
        onSecondary: Colors.white,
        error: errorRed,
        onError: Colors.white,
        surface: cardLight,
        onSurface: textPrimaryLight,
      ),

      // Chips (filter tabs): selected and unselected labels keep a high-contrast colour.
      chipTheme: ChipThemeData(
        labelStyle: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
        secondaryLabelStyle: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700),
        checkmarkColor: const Color(0xFF0F172A),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: cardLight,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: textPrimaryLight),
        titleSpacing: 0,
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
          side: const BorderSide(color: borderLight, width: 1.2),
        ),
        elevation: 3,
        shadowColor: Colors.black.withValues(alpha: 0.08),
      ),

      dividerColor: borderLight,
      iconTheme: const IconThemeData(color: textSecondaryLight),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardLight,
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        hintStyle: const TextStyle(color: textMutedLight, fontSize: 14, fontWeight: FontWeight.w500),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderLight, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderLight, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: secondaryOrange, width: 1.8),
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
          backgroundColor: secondaryOrange,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: secondaryOrange.withValues(alpha: 0.35),
          // Primary and secondary buttons share one size, so a pair (Accept / Cancel) is level.
          // No vertical padding: the 44 high minimum centres the label, and a button squeezed into
          // a shorter box (40-44) never clips its text. A pair of buttons shares one height.
          padding: const EdgeInsets.symmetric(horizontal: 16),
          minimumSize: const Size(96, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: secondaryOrange,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),

      // Secondary / Cancel actions: outlined in the brand orange, brand orange border.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: secondaryOrange,
          foregroundColor: Colors.white,
          // No vertical padding: the 44 high minimum centres the label, and a button squeezed into
          // a shorter box (40-44) never clips its text. A pair of buttons shares one height.
          padding: const EdgeInsets.symmetric(horizontal: 16),
          minimumSize: const Size(96, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: secondaryOrange,
          side: const BorderSide(color: secondaryOrange, width: 1.2),
          // No vertical padding: the 44 high minimum centres the label, and a button squeezed into
          // a shorter box (40-44) never clips its text. A pair of buttons shares one height.
          padding: const EdgeInsets.symmetric(horizontal: 16),
          minimumSize: const Size(96, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15),
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
          if (states.contains(WidgetState.selected)) return secondaryOrange;
          return Colors.transparent;
        }),
        side: const BorderSide(color: borderLight, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return secondaryOrange;
          return textMutedLight;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return secondaryOrange.withValues(alpha: 0.3);
          }
          return borderLight;
        }),
      ),

      dialogTheme: DialogThemeData(
        // Even room around the Accept / Cancel pair.
        actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
        backgroundColor: cardLight,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderLight, width: 1.2),
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: cardLight,
        surfaceTintColor: Colors.transparent,
        elevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: cardLight,
        elevation: 12,
        selectedItemColor: secondaryOrange,
        unselectedItemColor: textMutedLight,
        type: BottomNavigationBarType.fixed,
      ),

      timePickerTheme: TimePickerThemeData(
        backgroundColor: cardLight,
        hourMinuteTextColor: textPrimaryLight,
        hourMinuteColor: const Color(0xFFF1F5F9),
        dayPeriodTextColor: textPrimaryLight,
        dayPeriodColor: const Color(0xFFF1F5F9),
        dialHandColor: primaryGold,
        dialBackgroundColor: const Color(0xFFF1F5F9),
        dialTextColor: textPrimaryLight,
        entryModeIconColor: primaryGold,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }
}
