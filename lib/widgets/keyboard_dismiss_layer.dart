import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// App-wide keyboard handling, placed once above the navigator (see app.dart):
///  * a tap anywhere outside an input field closes the keyboard;
///  * on iPhone, a small bar above the keyboard with Previous / Next field arrows and Done (iOS has no
///    system key to hide the keyboard, and numeric keypads have no Next / Done key at all);
///  * the keyboard is closed whenever a screen is opened or closed (e.g. after a form is submitted).
class KeyboardDismissLayer extends StatelessWidget {
  const KeyboardDismissLayer({super.key, required this.child, this.showAccessoryBar});

  final Widget child;

  /// Defaults to iPhone / iPad only: Android keeps its own keyboard and back-key behaviour.
  final bool? showAccessoryBar;

  static void dismiss() => FocusManager.instance.primaryFocus?.unfocus();

  @override
  Widget build(BuildContext context) {
    final withBar = showAccessoryBar ?? defaultTargetPlatform == TargetPlatform.iOS;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: dismiss,
      child: Stack(
        children: [
          Positioned.fill(child: child),
          if (withBar) const _KeyboardAccessoryBar(),
        ],
      ),
    );
  }
}

class _KeyboardAccessoryBar extends StatelessWidget {
  const _KeyboardAccessoryBar();

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    if (inset <= 0) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Positioned(
      left: 0,
      right: 0,
      bottom: inset,
      child: Material(
        color: isDark ? const Color(0xFF2B2B2E) : const Color(0xFFD1D3D9),
        child: SizedBox(
          height: 42,
          child: Row(
            children: [
              // No tooltips: this bar sits above the Navigator, where there is no Overlay for them.
              IconButton(
                key: const Key('keyboard-previous'),
                icon: const Icon(Icons.keyboard_arrow_up_rounded),
                onPressed: () => FocusManager.instance.primaryFocus?.previousFocus(),
              ),
              IconButton(
                key: const Key('keyboard-next'),
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                onPressed: () => FocusManager.instance.primaryFocus?.nextFocus(),
              ),
              const Spacer(),
              TextButton(
                onPressed: KeyboardDismissLayer.dismiss,
                child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const SizedBox(width: 6),
            ],
          ),
        ),
      ),
    );
  }
}

/// Closes the keyboard when a screen is pushed or popped.
class KeyboardRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => KeyboardDismissLayer.dismiss();

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => KeyboardDismissLayer.dismiss();
}
