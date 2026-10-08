import 'package:daalsetu/modules/admin_catalog/view/admin_drawer.dart';
import 'package:daalsetu/modules/admin_catalog/view/admin_permission_toggle_panel.dart';
import 'package:daalsetu/network/api_client.dart';
import 'package:flutter/material.dart';

class AdminSubAdminPermissionsScreen extends StatefulWidget {
  const AdminSubAdminPermissionsScreen({
    super.key,
    required this.subAdminId,
    this.subAdminName,
  });

  final String subAdminId;
  final String? subAdminName;

  @override
  State<AdminSubAdminPermissionsScreen> createState() =>
      _AdminSubAdminPermissionsScreenState();
}

class _AdminSubAdminPermissionsScreenState
    extends State<AdminSubAdminPermissionsScreen> {
  bool _loading = true;
  bool _saving = false;
  String? _error;
  Map<String, dynamic> _user = const {};
  List<Map<String, dynamic>> _categories = const [];
  Set<int> _overrideIds = <int>{};
  Set<int> _roleIds = <int>{};

  String get _endpoint =>
      '/api/admin/sub-admins/${Uri.encodeComponent(widget.subAdminId)}/permissions/';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await ApiClient.get(
        endpoint: _endpoint,
        requireAuth: true,
      );
      final data = response is Map ? response['data'] : null;
      if (data is! Map) throw Exception('Permission data was not returned.');
      if (!mounted) return;
      setState(() {
        _user = data['user'] is Map
            ? Map<String, dynamic>.from(data['user'] as Map)
            : const {};
        _categories = permissionCategoryList(data['permission_categories']);
        _overrideIds = _ids(data['override_permission_ids']);
        _roleIds = _ids(data['role_permission_ids']);
      });
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Set<int> _ids(Object? value) => (value is List ? value : const [])
      .map(permissionId)
      .whereType<int>()
      .toSet();

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ApiClient.put(
        endpoint: _endpoint,
        data: {'permission_ids': _overrideIds.toList()..sort()},
        requireAuth: true,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sub Admin permissions updated.')),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) _showError(_message(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _displayName() {
    final name = permissionText(_user['name']);
    if (name.isNotEmpty) return name;
    final first = permissionText(_user['first_name']);
    final last = permissionText(_user['last_name']);
    final fullName = '$first $last'.trim();
    return fullName.isEmpty ? (widget.subAdminName ?? 'Sub Admin') : fullName;
  }

  String _message(Object error) =>
      error.toString().replaceFirst('Exception: ', '');

  void _showError(String message) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    drawer: const AdminDrawer(activeKey: 'sub_admins'),
    appBar: AppBar(title: const Text('Sub Admin Permissions')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? _FailureState(message: _error!, onRetry: _load)
        : SafeArea(
            child: Column(
              children: [
                _header(context),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 104),
                      children: [
                        const Text(
                          'Extra access for this Sub Admin',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Permissions supplied by an assigned role stay on here and cannot be removed from this screen.',
                        ),
                        const SizedBox(height: 12),
                        AdminPermissionTogglePanel(
                          categories: _categories,
                          selectedIds: _overrideIds,
                          inheritedIds: _roleIds,
                          selectionLabel: 'Extra permission',
                          disabledLabel: 'Not granted',
                          onChanged: (ids) =>
                              setState(() => _overrideIds = ids),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
    bottomNavigationBar: !_loading && _error == null
        ? SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Saving...' : 'Save Permissions'),
            ),
          )
        : null,
  );

  Widget _header(BuildContext context) => Container(
    width: double.infinity,
    color: Theme.of(context).colorScheme.primaryContainer,
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_displayName(), style: Theme.of(context).textTheme.titleLarge),
        if (permissionText(_user['email']).isNotEmpty)
          Text(permissionText(_user['email'])),
        const SizedBox(height: 4),
        Text(
          '${_overrideIds.length} extra permission${_overrideIds.length == 1 ? '' : 's'} • ${_roleIds.length} from roles',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );
}

class _FailureState extends StatelessWidget {
  const _FailureState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 42),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}
