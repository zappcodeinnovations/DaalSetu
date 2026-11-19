import 'package:daalsetu/modules/admin_catalog/view/admin_drawer.dart';
import 'package:daalsetu/modules/admin_catalog/view/admin_permission_toggle_panel.dart';
import 'package:daalsetu/network/api_client.dart';
import 'package:daalsetu/widgets/hero_header.dart';
import 'package:flutter/material.dart';
import '../../../utils/app_snackbar.dart';
import 'package:daalsetu/widgets/back_navigation.dart';

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
      AppSnackbar.showSnackBar(context, 
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

  void _showError(String message) => AppSnackbar.showSnackBar(context, 
    SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AdminDrawer(activeKey: 'sub_admins'),
      appBar: HeroHeader(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => goBackOrHome(context),
        ),
        title: 'Sub Admin Permissions',
        subtitle: 'Granular access overrides for ${_displayName()}',
        trailing: IconButton(
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: _load,
        ),
      ),
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
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: _saving
                      ? null
                      : const LinearGradient(
                          colors: [
                            Color(0xFFE65100),
                            Color(0xFFF57C00),
                            Color(0xFFFFA000),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  color: _saving ? Colors.grey : null,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: _saving
                      ? null
                      : [
                          BoxShadow(
                            color: const Color(0xFFE65100).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _saving ? null : _save,
                    child: Center(
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.save_outlined, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Save Permissions',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _header(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2638) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF2C394F) : const Color(0xFFFFE0B2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _displayName(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          if (permissionText(_user['email']).isNotEmpty)
            Text(
              permissionText(_user['email']),
              style: TextStyle(
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          const SizedBox(height: 6),
          Text(
            '${_overrideIds.length} extra permission${_overrideIds.length == 1 ? '' : 's'} • ${_roleIds.length} from roles',
            style: const TextStyle(
              color: Color(0xFFE65100),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
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
