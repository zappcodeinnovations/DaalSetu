import 'package:daalsetu/routes/app_routes.dart';
import 'package:daalsetu/services/panel_service.dart';
import 'package:daalsetu/services/realtime_notification_service.dart';
import 'package:daalsetu/utils/app_preferences.dart';
import 'package:daalsetu/utils/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
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
                      const SizedBox(height: 24),
                      Center(
                        child: Image.asset(
                          'assets/images/thumb_logo.png',
                          width: 128,
                          height: 128,
                          fit: BoxFit.contain,
                          semanticLabel: 'Daalbroker logo',
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Choose your panel',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Your account is a Buyer & Seller account. Pick the panel to use now; you can switch any time from the menu.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.textTheme.bodyMedium?.color?.withValues(
                            alpha: 0.75,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _PanelCard(
                        key: const Key('choose-panel-buyer'),
                        title: 'Buyer Panel',
                        subtitle:
                            'Access buyer dashboard and purchasing features.',
                        icon: Icons.shopping_cart_outlined,
                        busy: _busy == PanelService.buyer,
                        lastUsed: _lastUsed == PanelService.buyer,
                        enabled: _busy == null,
                        onTap: () => _choose(PanelService.buyer),
                      ),
                      const SizedBox(height: 14),
                      _PanelCard(
                        key: const Key('choose-panel-seller'),
                        title: 'Seller Panel',
                        subtitle:
                            'Access seller dashboard and selling features.',
                        icon: Icons.storefront_outlined,
                        busy: _busy == PanelService.seller,
                        lastUsed: _lastUsed == PanelService.seller,
                        enabled: _busy == null,
                        onTap: () => _choose(PanelService.seller),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextButton.icon(
                    onPressed: _busy == null ? _logout : null,
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Log out'),
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

class _PanelCard extends StatelessWidget {
  const _PanelCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.busy,
    required this.lastUsed,
    required this.enabled,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool busy;
  final bool lastUsed;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: lastUsed
                  ? primary
                  : theme.dividerColor.withValues(alpha: 0.5),
              width: lastUsed ? 1.6 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  busy
                      ? SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: primary,
                          ),
                        )
                      : Icon(icon, color: primary, size: 30),
                  const Spacer(),
                  if (lastUsed)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Last used',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: primary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12.5,
                  color: theme.textTheme.bodyMedium?.color?.withValues(
                    alpha: 0.7,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
