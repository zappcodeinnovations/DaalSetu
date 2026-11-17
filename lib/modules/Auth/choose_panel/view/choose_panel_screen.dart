import 'package:daalsetu/routes/app_routes.dart';
import 'package:daalsetu/services/panel_service.dart';
import 'package:daalsetu/services/realtime_notification_service.dart';
import 'package:daalsetu/theme/app_theme.dart';
import 'package:daalsetu/utils/app_preferences.dart';
import 'package:daalsetu/utils/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shown after a Buyer & Seller account logs in: continue as Buyer or Seller.
/// The panel can be switched later from the side menu or Settings.
class ChoosePanelScreen extends StatefulWidget {
  const ChoosePanelScreen({super.key});

  @override
  State<ChoosePanelScreen> createState() => _ChoosePanelScreenState();
}

class _ChoosePanelScreenState extends State<ChoosePanelScreen> {
  String? _busy;
  String? _lastUsed;

  @override
  void initState() {
    super.initState();
    AppPreferences.getActivePanel().then((panel) {
      if (mounted && panel != null && panel.isNotEmpty) {
        setState(() => _lastUsed = panel);
      }
    });
  }

  Future<void> _choose(String panel) async {
    if (_busy != null) return;
    setState(() => _busy = panel);
    try {
      await PanelService.activate(panel);
    } catch (error) {
      if (mounted) setState(() => _busy = null);
      AppSnackbar.showError(
        message: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _logout() async {
    await AppPreferences.logout();
    if (Get.isRegistered<RealtimeNotificationService>()) {
      RealtimeNotificationService.to.clearOnLogout();
    }
    Get.offAllNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    const Color(0xFF1E293B).withValues(alpha: 0.5),
                    theme.scaffoldBackgroundColor,
                  ]
                : [
                    const Color(0xFFFFF7ED),
                    theme.scaffoldBackgroundColor,
                  ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.4],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      children: [
                        const SizedBox(height: 16),

                        // ── Centered Logo Pod with Ambient Glow ────────
                        Center(
                          child: Container(
                            width: 100,
                            height: 100,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E293B)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFFFE0B2),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isDark
                                      ? Colors.black.withValues(alpha: 0.35)
                                      : AppTheme.secondaryOrange
                                          .withValues(alpha: 0.12),
                                  blurRadius: 18,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/thumb_logo.png',
                              fit: BoxFit.contain,
                              semanticLabel: 'Daalbroker logo',
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // ── Headline & Context Subtitle ──────────────
                        Text(
                          'Choose your panel',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Your account is a Buyer & Seller account. Pick the panel to use now; you can switch any time from the menu.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            height: 1.45,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Buyer Panel Card ─────────────────────────
                        _PanelCard(
                          key: const Key('choose-panel-buyer'),
                          title: 'Buyer Panel',
                          subtitle:
                              'Access buyer dashboard and purchasing features.',
                          icon: Icons.shopping_cart_outlined,
                          iconColor: const Color(0xFFEA580C),
                          iconBgColor: const Color(0xFFFFF7ED),
                          accentTag: 'PURCHASE & REQUIREMENTS',
                          busy: _busy == PanelService.buyer,
                          lastUsed: _lastUsed == PanelService.buyer,
                          enabled: _busy == null,
                          onTap: () => _choose(PanelService.buyer),
                        ),

                        const SizedBox(height: 14),

                        // ── Seller Panel Card ────────────────────────
                        _PanelCard(
                          key: const Key('choose-panel-seller'),
                          title: 'Seller Panel',
                          subtitle:
                              'Access seller dashboard and selling features.',
                          icon: Icons.storefront_outlined,
                          iconColor: const Color(0xFF0D9488),
                          iconBgColor: const Color(0xFFCCFBF1),
                          accentTag: 'SALES & INVENTORY',
                          busy: _busy == PanelService.seller,
                          lastUsed: _lastUsed == PanelService.seller,
                          enabled: _busy == null,
                          onTap: () => _choose(PanelService.seller),
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),

                  // ── Outlined Log out button ───────────────────────
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16, top: 8),
                    child: OutlinedButton.icon(
                      onPressed: _busy == null ? _logout : null,
                      icon: Icon(
                        Icons.logout_rounded,
                        size: 16,
                        color: isDark
                            ? const Color(0xFFF87171)
                            : const Color(0xFFDC2626),
                      ),
                      label: Text(
                        'Log out',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFFF87171)
                              : const Color(0xFFDC2626),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: isDark
                              ? const Color(0xFFEF4444).withValues(alpha: 0.3)
                              : const Color(0xFFFCA5A5),
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 9,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PanelCard extends StatelessWidget {
  const _PanelCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.accentTag,
    required this.busy,
    required this.lastUsed,
    required this.enabled,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String accentTag;
  final bool busy;
  final bool lastUsed;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final borderColor = lastUsed
        ? (isDark ? const Color(0xFFEA580C) : AppTheme.secondaryOrange)
        : (isDark ? const Color(0xFF2C394F) : const Color(0xFFFFE0B2));

    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: enabled ? onTap : null,
        splashColor: iconColor.withValues(alpha: 0.12),
        highlightColor: iconColor.withValues(alpha: 0.06),
        child: Ink(
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: borderColor,
              width: lastUsed ? 1.8 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: lastUsed
                    ? (isDark
                        ? const Color(0xFFEA580C).withValues(alpha: 0.22)
                        : AppTheme.secondaryOrange.withValues(alpha: 0.16))
                    : (isDark
                        ? Colors.black.withValues(alpha: 0.25)
                        : Colors.black.withValues(alpha: 0.04)),
                blurRadius: lastUsed ? 14 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top Bar: Icon pod + Last used pill ─────────
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark
                            ? iconBgColor.withValues(alpha: 0.15)
                            : iconBgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: busy
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: iconColor,
                                ),
                              )
                            : Icon(icon, color: iconColor, size: 22),
                      ),
                    ),
                    const Spacer(),
                    if (lastUsed)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppTheme.secondaryOrange.withValues(alpha: 0.22)
                              : const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark
                                ? AppTheme.secondaryOrange.withValues(alpha: 0.5)
                                : const Color(0xFFFFCC80),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          'Last used',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? const Color(0xFFFB923C)
                                : AppTheme.secondaryOrange,
                          ),
                        ),
                      ),
                    if (!lastUsed)
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 13,
                        color: isDark
                            ? const Color(0xFF64748B)
                            : const Color(0xFFCBD5E1),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── Title ──────────────────────────────────────
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),

                const SizedBox(height: 3),

                // ── Accent Tag ────────────────────────────────
                Text(
                  accentTag,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: iconColor,
                  ),
                ),

                const SizedBox(height: 6),

                // ── Card Subtitle ──────────────────────────────
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    height: 1.4,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
