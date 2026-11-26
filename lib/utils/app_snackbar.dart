import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

/// Single popup style for the whole app: success is green, error is red,
/// layout is identical and no title like "Error"/"Success" is ever shown.
class AppSnackbar {
  AppSnackbar._();

  static const String _fallbackMessage =
      "Something went wrong. Please try again.";

  // Titles that carry no information on their own; never shown to the user.
  static final RegExp _genericTitle = RegExp(
    r'^(error|success|successful|failed|failure|warning|notice|info|alert|validation|oops!?|done)$',
    caseSensitive: false,
  );

  static final RegExp _errorWords = RegExp(
    r"\b(error|fail(ed|ure)?|could ?n[o']t|can ?n[o']t|unable|invalid|required|missing|denied|not (found|allowed|available|valid|authori[sz]ed)|please (select|enter|fill|provide|choose|add|upload|check)|must|warning|validation|oops|incorrect|wrong|expired|exceed|already exists)\b",
    caseSensitive: false,
  );

  static void showError({
    String? title,
    required String message,
    Duration duration = const Duration(seconds: 4),
  }) => _show(message, isError: true, duration: duration);

  static void showSuccess({
    String? title,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) => _show(message, isError: false, duration: duration);

  static void showWarning({
    String? title,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) => _show(message, isError: true, duration: duration);

  static void showInfo({
    String? title,
    required String message,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) => _show(
    message,
    isError: false,
    duration: duration,
    actionLabel: actionLabel,
    onAction: onAction,
  );

  /// Drop-in replacement for `Get.snackbar`. Styling arguments are accepted
  /// for compatibility; only [backgroundColor] is used, to tell error from success.
  static void snackbar(
    String title,
    String message, {
    Duration? duration,
    Widget? titleText,
    Widget? messageText,
    Widget? icon,
    Widget? mainButton,
    SnackPosition? snackPosition,
    Color? backgroundColor,
    Color? colorText,
    Color? leftBarIndicatorColor,
    EdgeInsets? margin,
    EdgeInsets? padding,
    double? borderRadius,
    double? maxWidth,
    double? barBlur,
    double? overlayBlur,
    Color? overlayColor,
    List<BoxShadow>? boxShadows,
    bool? isDismissible,
    bool? shouldIconPulse,
    bool? showProgressIndicator,
    Curve? forwardAnimationCurve,
    Curve? reverseAnimationCurve,
    Duration? animationDuration,
    DismissDirection? dismissDirection,
    SnackStyle? snackStyle,
    void Function(GetSnackBar snack)? onTap,
  }) {
    final heading = title.trim().isNotEmpty
        ? title.trim()
        : (_textOf(titleText) ?? '').trim();
    var text = message.trim();
    if (text.isEmpty) text = _textOf(messageText) ?? '';
    if (text.isEmpty && !_genericTitle.hasMatch(heading)) text = heading;
    _show(
      text,
      isError: _isError(heading, text, backgroundColor),
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  /// Replacement for `ScaffoldMessenger.of(context).showSnackBar(...)`.
  static void showSnackBar(BuildContext context, SnackBar snackBar) {
    final action = snackBar.action;
    final text = _textOf(snackBar.content);
    final isError = _isError('', text ?? '', snackBar.backgroundColor);
    if (text != null) {
      _show(
        text,
        isError: isError,
        duration: snackBar.duration,
        actionLabel: action?.label,
        onAction: action?.onPressed,
      );
      return;
    }

    // Content is not plain text: keep the widget but apply the shared look.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: snackBar.content,
          duration: snackBar.duration,
          action: action,
          backgroundColor: isError ? AppTheme.errorRed : AppTheme.successGreen,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  static void _show(
    String message, {
    required bool isError,
    required Duration duration,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final text = _clean(message);

    void show() {
      // Errors and permission alerts are a centred popup (like the web), not a strip at the screen edge.
      if (isError) {
        _showErrorDialog(text);
        return;
      }
      if (Get.isDialogOpen == true || Get.isBottomSheetOpen == true) {
        if (Get.isSnackbarOpen == true) {
          Get.closeCurrentSnackbar();
        }
        Get.rawSnackbar(
          messageText: Row(
            children: [
              Icon(
                isError
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_outline_rounded,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 13.5,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor:
              isError ? AppTheme.errorRed : AppTheme.successGreen,
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          borderRadius: 14,
          duration: duration,
          mainButton: actionLabel == null
              ? null
              : TextButton(
                  onPressed: () {
                    Get.closeCurrentSnackbar();
                    onAction?.call();
                  },
                  child: Text(
                    actionLabel,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
        );
        return;
      }

      final context = Get.key.currentContext;
      if (context == null || !context.mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger == null) return;
      messenger
        ..removeCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  isError
                      ? Icons.error_outline_rounded
                      : Icons.check_circle_outline_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 13.5,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
            action: actionLabel == null
                ? null
                : SnackBarAction(
                    label: actionLabel,
                    textColor: Colors.white,
                    onPressed: () {
                      messenger.hideCurrentSnackBar();
                      onAction?.call();
                    },
                  ),
            backgroundColor: isError
                ? AppTheme.errorRed
                : AppTheme.successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            duration: duration,
            dismissDirection: DismissDirection.down,
          ),
        );
    }

    // Controller callbacks can fire during build or a route transition.
    // Let the Scaffold register before starting its snackbar animation.
    if (WidgetsBinding.instance.schedulerPhase ==
            SchedulerPhase.persistentCallbacks ||
        Get.key.currentContext == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => show());
      WidgetsBinding.instance.ensureVisualUpdate();
    } else {
      show();
    }
  }

  static bool _errorDialogOpen = false;
  static String? _lastErrorText;
  static DateTime? _lastErrorAt;

  /// One centred error popup at a time; the same message repeated within a few seconds (a background
  /// refresh failing again) is not shown twice.
  static void _showErrorDialog(String text) {
    final now = DateTime.now();
    if (_errorDialogOpen) return;
    if (_lastErrorText == text && _lastErrorAt != null && now.difference(_lastErrorAt!) < const Duration(seconds: 5)) {
      return;
    }
    final context = Get.key.currentContext;
    if (context == null || !context.mounted) return;
    _errorDialogOpen = true;
    _lastErrorText = text;
    _lastErrorAt = now;
    Get.dialog<void>(
      AlertDialog(
        key: const Key('app-error-dialog'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        icon: const Icon(Icons.error_outline_rounded, color: AppTheme.errorRed, size: 40),
        title: Text(
          'Something went wrong',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 14, height: 1.4),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          SizedBox(
            width: 140,
            height: 44,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEA7C1C)),
              onPressed: () => Get.back(),
              child: const Text('OK'),
            ),
          ),
        ],
      ),
      barrierDismissible: true,
    ).whenComplete(() => _errorDialogOpen = false);
  }

  /// Decides error vs success from the old background colour, then the title,
  /// then the message wording.
  static bool _isError(String title, String message, Color? color) {
    if (color != null) {
      final hsv = HSVColor.fromColor(color);
      if (hsv.saturation > 0.25) {
        if (hsv.hue < 50 || hsv.hue > 330) return true; // red / orange
        if (hsv.hue > 80 && hsv.hue < 170) return false; // green
      }
    }
    if (title.isNotEmpty && _errorWords.hasMatch(title)) return true;
    if (RegExp(
      r'^(success|successful|done)$',
      caseSensitive: false,
    ).hasMatch(title))
      return false;
    return message.trim().isEmpty || _errorWords.hasMatch(message);
  }

  /// Strips technical prefixes such as "Exception:" and "Error:".
  static String _clean(String raw) {
    var text = raw
        .replaceAll(RegExp(r'\b\w*Exception\s*:\s*'), '')
        .replaceAll(RegExp(r'\berror\s*[:\-]\s*', caseSensitive: false), '')
        .trim();
    if (text.isEmpty ||
        RegExp(
          r'^(error|null|exception)$',
          caseSensitive: false,
        ).hasMatch(text)) {
      return _fallbackMessage;
    }
    return text[0].toUpperCase() + text.substring(1);
  }

  static String? _textOf(Widget? widget) {
    if (widget == null) return null;
    if (widget is Text) return widget.data ?? widget.textSpan?.toPlainText();
    if (widget is RichText) return widget.text.toPlainText();
    if (widget is Flex) {
      final parts = widget.children
          .map(_textOf)
          .whereType<String>()
          .where((t) => t.trim().isNotEmpty);
      return parts.isEmpty ? null : parts.join(' ');
    }
    if (widget is SingleChildRenderObjectWidget) return _textOf(widget.child);
    if (widget is ParentDataWidget) return _textOf(widget.child);
    return null;
  }
}
