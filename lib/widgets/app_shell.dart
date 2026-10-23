import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../modules/admin_catalog/view/admin_drawer.dart';
import '../routes/app_routes.dart';

/// The app-wide side drawer, opened from any signed-in page (not only the
/// dashboards). It slides in from the left as a route, so focus, overlays and
/// closing behave like any other screen.
class AppShell {
  AppShell._();

  /// Pages before sign-in never get the drawer.
  static const _publicRoutes = {
    AppRoutes.splash,
    AppRoutes.onboarding,
    AppRoutes.login,
    AppRoutes.loginWithOtp,
    AppRoutes.verifyOtp,
    AppRoutes.register,
    AppRoutes.forgot_password,
  };

  static bool get isSignedInPage =>
      !_publicRoutes.contains(Get.currentRoute) && Get.currentRoute.isNotEmpty;

  /// [activeKey] highlights the current page's item in the menu.
  static void openDrawer({String? activeKey}) {
    final context = Get.overlayContext;
    if (context == null) return;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, _, _) => Align(
        alignment: Alignment.centerLeft,
        child: AdminDrawer(activeKey: activeKey),
      ),
      transitionBuilder: (_, animation, _, child) => SlideTransition(
        position: Tween(begin: const Offset(-1, 0), end: Offset.zero).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: child,
      ),
    );
  }
}

/// Left side of a page's AppBar: the side-menu button followed by its back
/// button (or the page's own leading widget), so the drawer opens from the same
/// side on every signed-in page. Pair it with [widthFor] as `leadingWidth`.
class AppBarLeading extends StatelessWidget {
  const AppBarLeading({super.key, this.child, this.showBack = true});

  /// The page's own leading widget (e.g. a custom back button), kept first.
  final Widget? child;

  /// False for pages that hide the automatic back button.
  final bool showBack;

  static const double _slot = 40;

  static bool _hasBack(BuildContext context, {required bool hasChild, required bool showBack}) =>
      hasChild || (showBack && (ModalRoute.of(context)?.canPop ?? false));

  static double widthFor(BuildContext context, {bool hasChild = false, bool showBack = true}) {
    final slots = (_hasBack(context, hasChild: hasChild, showBack: showBack) ? 1 : 0) +
        (AppShell.isSignedInPage ? 1 : 0);
    return slots == 0 ? kToolbarHeight : slots * _slot + 12;
  }

  void _openMenu(BuildContext context) {
    // Always the app-wide drawer: it opens full screen, over the bottom nav bar.
    // A page that declares its own AdminDrawer keeps its highlighted item.
    final pageDrawer = Scaffold.maybeOf(context)?.widget.drawer;
    AppShell.openDrawer(activeKey: pageDrawer is AdminDrawer ? pageDrawer.activeKey : null);
  }

  @override
  Widget build(BuildContext context) {
    final own = child;
    final back = own != null
        ? SizedBox.square(dimension: _slot, child: own)
        : (_hasBack(context, hasChild: false, showBack: showBack)
            ? SizedBox.square(
                dimension: _slot,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  icon: const BackButtonIcon(),
                  onPressed: () => Navigator.maybePop(context),
                ),
              )
            : null);
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (AppShell.isSignedInPage)
            // Fixed 40px slots: an IconButton alone keeps a 48px tap target and overflows.
            SizedBox.square(
              dimension: _slot,
              child: IconButton(
                padding: EdgeInsets.zero,
                tooltip: 'Open menu',
                icon: const Icon(Icons.menu_rounded),
                onPressed: () => _openMenu(context),
              ),
            ),
          if (back != null) back,
        ],
      ),
    );
  }
}
