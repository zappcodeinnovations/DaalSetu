import 'package:flutter/material.dart';

/// Centralized color & design tokens for the Onboarding module.
/// 
/// If you need to change the onboarding color theme (e.g. brand palette or button gradients),
/// change the color values here and all onboarding screens, buttons, dots, image frames,
/// and ambient washes will update automatically.
class OnboardingColors {
  OnboardingColors._();

  // ── 1. Primary Brand & Accent (Buttons, Active Dots, Highlights) ───────────
  static const Color primary = Color(0xFFF57C00);         // Brand Saffron
  static const Color primaryDeep = Color(0xFFEA580C);     // Deep Saffron (Gradient start)
  static const Color primaryLight = Color(0xFFFF9800);    // Warm Amber (Gradient end)

  // ── 2. Background Ambient Glow ─────────────────────────────────────────────
  static const Color glowStart = Color(0xFFFFE0B2);       // Soft top wash
  static const Color glowMid = Color(0xFFFFF3E0);         // Transition wash
  static const Color glowEnd = Colors.transparent;

  // Dark mode ambient wash
  static const Color glowStartDark = Color(0xFFE65100);
  static const Color glowMidDark = Color(0xFFF57C00);

  // ── 3. Image Dual-Ring Frame & Card Borders ────────────────────────────────
  static const Color border = Color(0xFFFFE0B2);          // Warm border tint
  static const Color imageFrameBg = Colors.white;         // Clean inner container
  static const Color imageFrameShadow = Color(0xFFF57C00); // Ambient glow shadow

  // ── 4. Dot Page Indicators ─────────────────────────────────────────────────
  static const Color activeDot = Color(0xFFF57C00);       // Active page pill
  static const Color inactiveDot = Color(0xFFFFE0B2);     // Inactive circular dots
  static const Color inactiveDotDark = Color(0xFF334155);

  // ── 5. Navigation / Skip Button ────────────────────────────────────────────
  static const Color skipPillBg = Color(0xFFFFF7ED);      // Saffron tinted pill bg
  static const Color skipPillBorder = Color(0xFFFFE0B2);  // Border tint
  static const Color skipPillText = Color(0xFFEA580C);    // High-contrast text

  // ── 6. Typography ──────────────────────────────────────────────────────────
  static const Color titleLight = Color(0xFF0F172A);      // Deep Slate
  static const Color descriptionLight = Color(0xFF64748B); // Muted Slate
  static const Color titleDark = Colors.white;
  static const Color descriptionDark = Color(0xFF94A3B8);

  // ── Convenient Gradients ───────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryDeep, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient ambientGlowGradient(bool isDark) {
    if (isDark) {
      return LinearGradient(
        colors: [
          glowStartDark.withValues(alpha: 0.22),
          glowMidDark.withValues(alpha: 0.10),
          Colors.transparent,
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    }
    return LinearGradient(
      colors: [
        glowStart.withValues(alpha: 0.75),
        glowMid.withValues(alpha: 0.35),
        Colors.transparent,
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }
}
