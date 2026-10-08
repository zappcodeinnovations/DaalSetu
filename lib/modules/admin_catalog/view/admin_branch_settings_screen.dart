import 'package:daalsetu/modules/admin_catalog/view/admin_drawer.dart';
import 'package:daalsetu/network/api_client.dart';
import 'package:flutter/material.dart';

class AdminBranchSettingsScreen extends StatefulWidget {
  const AdminBranchSettingsScreen({super.key});

  @override
  State<AdminBranchSettingsScreen> createState() =>
      _AdminBranchSettingsScreenState();
}

class _AdminBranchSettingsScreenState extends State<AdminBranchSettingsScreen> {
  static const _endpoint = '/api/admin/branch-settings/';

  bool loading = true;
  String? error;
  String? savingKey;
  bool buyerCrossBranchAccess = false;
  bool transporterCrossBranchBidding = false;

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  String _message(Object value) =>
      value.toString().replaceFirst('Exception: ', '');

  Future<void> loadSettings() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final response = await ApiClient.get(
        endpoint: _endpoint,
        requireAuth: true,
      );
      final raw = response is Map ? response['data'] : null;
      if (raw is! Map) throw Exception('Invalid branch settings response.');
      if (!mounted) return;
      setState(() {
        buyerCrossBranchAccess = raw['buyer_cross_branch_access'] == true;
        transporterCrossBranchBidding =
            raw['transporter_cross_branch_bidding'] == true;
      });
    } catch (exception) {
      if (!mounted) return;
      setState(() => error = _message(exception));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> updateSetting(String key, bool enabled) async {
    setState(() => savingKey = key);
    try {
      final response = await ApiClient.post(
        endpoint: _endpoint,
        body: {'setting': key, 'enabled': enabled},
        requireAuth: true,
      );
      if (!mounted) return;
      final savedValue = response['enabled'] is bool
          ? response['enabled'] as bool
          : enabled;
      setState(() {
        if (key == 'buyer_cross_branch_access') {
          buyerCrossBranchAccess = savedValue;
        } else {
          transporterCrossBranchBidding = savedValue;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            (response['message'] ?? 'Branch setting updated.').toString(),
          ),
        ),
      );
    } catch (exception) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_message(exception)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => savingKey = null);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    drawer: const AdminDrawer(activeKey: 'branch_settings'),
    appBar: AppBar(
      title: const Text(
        'Branch Settings',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: loading || savingKey != null ? null : loadSettings,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : error != null
        ? _errorView()
        : RefreshIndicator(
            onRefresh: loadSettings,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.admin_panel_settings_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'These global controls affect buyers and transporters across every branch. Only a Super Admin can change them.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _settingCard(
                  keyName: 'buyer_cross_branch_access',
                  icon: Icons.shopping_cart_checkout_outlined,
                  title: 'Buyer Cross-Branch Access',
                  subtitle:
                      'Allow buyers to view offers outside their own branch.',
                  value: buyerCrossBranchAccess,
                ),
                const SizedBox(height: 12),
                _settingCard(
                  keyName: 'transporter_cross_branch_bidding',
                  icon: Icons.local_shipping_outlined,
                  title: 'Transporter Cross-Branch Bidding',
                  subtitle:
                      'Allow transporters to bid on contracts from other branches.',
                  value: transporterCrossBranchBidding,
                ),
              ],
            ),
          ),
  );

  Widget _errorView() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48),
          const SizedBox(height: 12),
          Text(error!, textAlign: TextAlign.center),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: loadSettings,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
      ),
    ),
  );

  Widget _settingCard({
    required String keyName,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
  }) {
    final saving = savingKey == keyName;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        secondary: saving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(subtitle),
        ),
        value: value,
        onChanged: savingKey == null
            ? (enabled) => updateSetting(keyName, enabled)
            : null,
      ),
    );
  }
}
