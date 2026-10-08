import 'package:daalsetu/modules/admin_catalog/view/admin_drawer.dart';
import 'package:daalsetu/network/api_client.dart';
import 'package:flutter/material.dart';

const _matrixRoles = <String>[
  'admin',
  'sub_admin',
  'seller',
  'buyer',
  'both_sellerandbuyer',
  'transporter',
  'super_admin',
];

const _matrixModules = <String>[
  'branches',
  'brands',
  'categories',
  'challans',
  'contracts',
  'deals',
  'drivers',
  'kyc',
  'offer_images',
  'offer_videos',
  'offers',
  'permissions',
  'registered_companies',
  'reports',
  'roles',
  'shipment',
  'sub_admins',
  'tags',
  'transport',
  'users',
  'vehicles',
];

const _matrixActions = <String>['create', 'read', 'update', 'delete'];

class AdminPermissionsMatrixScreen extends StatefulWidget {
  const AdminPermissionsMatrixScreen({super.key});

  @override
  State<AdminPermissionsMatrixScreen> createState() =>
      _AdminPermissionsMatrixScreenState();
}

class _AdminPermissionsMatrixScreenState
    extends State<AdminPermissionsMatrixScreen> {
  bool _loading = true;
  String? _error;
  String _role = _matrixRoles.first;
  String _module = _matrixModules.first;
  final Map<String, bool> _rules = <String, bool>{};
  final Set<String> _updating = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _key(String role, String module, String action) =>
      '$role::$module::$action';

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await ApiClient.get(
        endpoint: '/api/admin/permissions/',
        requireAuth: true,
      );
      if (response is! Map) {
        throw Exception('Permission matrix was not returned.');
      }
      final next = <String, bool>{};
      final rules = response['permissions'];
      if (rules is List) {
        for (final item in rules.whereType<Map>()) {
          final role = _text(item['role']);
          final module = _text(item['module']);
          final action = _text(item['action']);
          if (role.isEmpty || module.isEmpty || action.isEmpty) {
            continue;
          }
          next[_key(role, module, action)] = item['is_allowed'] == true;
        }
      }
      if (!mounted) return;
      setState(() {
        _rules
          ..clear()
          ..addAll(next);
      });
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _update(String action, bool isAllowed) async {
    final key = _key(_role, _module, action);
    setState(() => _updating.add(key));
    try {
      await ApiClient.post(
        endpoint: '/api/admin/permissions/',
        body: {
          'role': _role,
          'module': _module,
          'action': action,
          'is_allowed': isAllowed,
        },
        requireAuth: true,
      );
      if (!mounted) return;
      setState(() => _rules[key] = isAllowed);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_pretty(action)} ${isAllowed ? 'allowed' : 'denied'} for ${_pretty(_role)}.',
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_message(error)),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _updating.remove(key));
    }
  }

  String _text(Object? value) => (value ?? '').toString().trim();
  String _message(Object error) =>
      error.toString().replaceFirst('Exception: ', '');
  String _pretty(String value) => value
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');

  @override
  Widget build(BuildContext context) => Scaffold(
    drawer: const AdminDrawer(activeKey: 'permissions_matrix'),
    appBar: AppBar(title: const Text('Permissions Matrix')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? _MatrixFailure(message: _error!, onRetry: _load)
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Set module access by role',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Each change is saved immediately. The server remains the final authority for access checks.',
                ),
                const SizedBox(height: 16),
                _selector(
                  label: 'Role',
                  value: _role,
                  values: _matrixRoles,
                  onChanged: (value) => setState(() => _role = value),
                ),
                const SizedBox(height: 12),
                _selector(
                  label: 'Module',
                  value: _module,
                  values: _matrixModules,
                  onChanged: (value) => setState(() => _module = value),
                ),
                const SizedBox(height: 18),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: _matrixActions.map((action) {
                      final key = _key(_role, _module, action);
                      final allowed = _rules[key] ?? false;
                      final updating = _updating.contains(key);
                      return SwitchListTile.adaptive(
                        value: allowed,
                        onChanged: updating
                            ? null
                            : (value) => _update(action, value),
                        title: Text(_pretty(action)),
                        subtitle: Text(
                          _rules.containsKey(key)
                              ? (allowed
                                    ? 'Explicitly allowed'
                                    : 'Explicitly denied')
                              : 'No explicit rule saved',
                        ),
                        secondary: updating
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                allowed
                                    ? Icons.check_circle_outline
                                    : Icons.block_outlined,
                              ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${_rules.length} explicit rule${_rules.length == 1 ? '' : 's'} loaded',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
  );

  Widget _selector({
    required String label,
    required String value,
    required List<String> values,
    required ValueChanged<String> onChanged,
  }) => DropdownButtonFormField<String>(
    key: ValueKey('$label-$value'),
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
    items: values
        .map(
          (item) => DropdownMenuItem(
            value: item,
            child: Text(_pretty(item), overflow: TextOverflow.ellipsis),
          ),
        )
        .toList(),
    onChanged: (selected) {
      if (selected != null) onChanged(selected);
    },
  );
}

class _MatrixFailure extends StatelessWidget {
  const _MatrixFailure({required this.message, required this.onRetry});

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
