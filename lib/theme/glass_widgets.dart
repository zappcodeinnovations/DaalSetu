import 'dart:ui';
import 'package:flutter/material.dart';

/// ─── GLASS CARD ───────────────────────────────────────────────────────────
/// A reusable frosted-glass card with backdrop blur, translucent fill, and
/// a subtle luminous border.
class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double blur;
  final double opacity;
  final Color? borderColor;
  final Color? glowColor;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.padding,
    this.margin,
    this.blur = 16,
    this.opacity = 0.12,
    this.borderColor,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveOpacity = isDark ? opacity : opacity + 0.55;
    final effectiveBorder =
        borderColor ?? Colors.white.withValues(alpha: isDark ? 0.12 : 0.5);
    final effectiveGlow = glowColor ?? Colors.transparent;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          if (effectiveGlow != Colors.transparent)
            BoxShadow(
              color: effectiveGlow.withValues(alpha: 0.15),
              blurRadius: 20,
              spreadRadius: 0,
            ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.white)
                  .withValues(alpha: effectiveOpacity),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: effectiveBorder, width: 1),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// ─── GRADIENT SCAFFOLD ────────────────────────────────────────────────────
/// A scaffold whose background is a smooth gradient, consistent with the
/// DaalSetu brand (golden warm tones).
class GradientScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  const GradientScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF1A1206),
                  const Color(0xFF0D1117),
                  const Color(0xFF0D1117),
                ]
              : [
                  const Color(0xFFFFF8E1),
                  const Color(0xFFFFFCF5),
                  Colors.white,
                ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBar,
        body: body,
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
      ),
    );
  }
}

/// ─── GLASS BUTTON ─────────────────────────────────────────────────────────
/// A premium CTA button with gradient fill and subtle glow.
class GlassButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final double height;
  final double borderRadius;
  final List<Color>? gradientColors;
  final bool isLoading;

  const GlassButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.height = 56,
    this.borderRadius = 16,
    this.gradientColors,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = gradientColors ??
        [
          theme.colorScheme.primary,
          theme.colorScheme.primary.withValues(alpha: 0.85),
        ];

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(colors: colors),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : child,
          ),
        ),
      ),
    );
  }
}

/// ─── GLASS TEXT FIELD ─────────────────────────────────────────────────────
/// A frosted-glass input field that matches the glassmorphism design system.
class GlassTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final TextStyle? style;

  const GlassTextField({
    super.key,
    this.controller,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: style ??
          TextStyle(
            color: theme.textTheme.bodyLarge?.color,
            fontSize: 15,
          ),
      decoration: InputDecoration(
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.7),
        hintText: hintText,
        hintStyle: TextStyle(
          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
          fontSize: 14,
        ),
        prefixIcon: prefixIcon != null
            ? Icon(
                prefixIcon,
                color: theme.colorScheme.primary.withValues(alpha: 0.7),
                size: 20,
              )
            : null,
        suffixIcon: suffixIcon,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: theme.colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: theme.colorScheme.error, width: 1.5),
        ),
      ),
    );
  }
}

/// ─── DECORATIVE BACKGROUND SHAPES ─────────────────────────────────────────
/// Floating circles and blobs for visual depth behind content.
class DecoCircle extends StatelessWidget {
  final double size;
  final Color color;
  final Alignment alignment;
  final Offset offset;

  const DecoCircle({
    super.key,
    this.size = 200,
    required this.color,
    this.alignment = Alignment.topRight,
    this.offset = Offset.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: alignment == Alignment.topRight || alignment == Alignment.topLeft
          ? -size / 3 + offset.dy
          : null,
      bottom:
          alignment == Alignment.bottomRight || alignment == Alignment.bottomLeft
              ? -size / 3 + offset.dy
              : null,
      right: alignment == Alignment.topRight || alignment == Alignment.bottomRight
          ? -size / 3 + offset.dx
          : null,
      left: alignment == Alignment.topLeft || alignment == Alignment.bottomLeft
          ? -size / 3 + offset.dx
          : null,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.2),
              color.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }
}

/// ─── GLASS ICON BOX ───────────────────────────────────────────────────────
/// A small frosted container for icons (used in list tiles, KPIs, etc.)
class GlassIconBox extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final double size;
  final double iconSize;

  const GlassIconBox({
    super.key,
    required this.icon,
    this.color,
    this.size = 44,
    this.iconSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: effectiveColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Icon(icon, color: effectiveColor, size: iconSize),
    );
  }
}
