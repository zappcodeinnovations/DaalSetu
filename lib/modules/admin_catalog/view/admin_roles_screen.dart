import 'package:daalsetu/modules/admin_catalog/view/admin_drawer.dart';
import 'package:daalsetu/modules/admin_catalog/view/admin_permission_toggle_panel.dart';
import 'package:daalsetu/network/api_client.dart';
import 'package:flutter/material.dart';

class AdminRolesScreen extends StatefulWidget {
  const AdminRolesScreen({super.key, this.showAdminDrawer = true});

  final bool showAdminDrawer;

  @override
  State<AdminRolesScreen> createState() => _AdminRolesScreenState();
}

class _AdminRolesScreenState extends State<AdminRolesScreen> {
  final _search = TextEditingController();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _roles = const [];
  List<Map<String, dynamic>> _categories = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await ApiClient.get(
        endpoint: '/api/admin/roles/',
        requireAuth: true,
      );
      if (response is! Map) throw Exception('Roles were not returned.');
      if (!mounted) return;
      setState(() {
        _roles = _maps(response['results']);
        _categories = permissionCategoryList(response['permission_categories']);
      });
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> _maps(Object? value) =>
      (value is List ? value : const [])
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList();

  Future<void> _openEditor([Map<String, dynamic>? role]) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AdminRoleEditorScreen(
          role: role,
          permissionCategories: _categories,
        ),
      ),
    );
    if (changed == true) await _load();
  }

  String _message(Object error) =>
      error.toString().replaceFirst('Exception: ', '');

  List<Map<String, dynamic>> get _matchingRoles {
    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) return _roles;
    return _roles.where((role) {
      return [
        role['name'],
        role['slug'],
        role['description'],
      ].map(permissionText).join(' ').toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    drawer: widget.showAdminDrawer
        ? const AdminDrawer(activeKey: 'roles')
        : null,
    appBar: AppBar(title: const Text('Roles')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _loading ? null : () => _openEditor(),
      icon: const Icon(Icons.add),
      label: const Text('Add Role'),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? _RoleFailure(message: _error!, onRetry: _load)
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 92),
              children: [
                TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Search roles',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                if (_matchingRoles.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 80),
                    child: Center(
                      child: Text(
                        _roles.isEmpty
                            ? 'No roles created yet.'
                            : 'No roles match this search.',
                      ),
                    ),
                  )
                else
                  ..._matchingRoles.map(
                    (role) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _roleCard(role),
                    ),
                  ),
              ],
            ),
          ),
  );

  Widget _roleCard(Map<String, dynamic> role) {
    final name = permissionText(role['name']).isEmpty
        ? permissionText(role['slug'])
        : permissionText(role['name']);
    final permissions = role['permission_ids'] is List
        ? (role['permission_ids'] as List).length
        : 0;
    final system = role['is_system'] == true;
    return Card(
      child: ListTile(
        onTap: () => _openEditor(role),
        leading: CircleAvatar(
          child: Icon(system ? Icons.lock_outline : Icons.badge_outlined),
        ),
        title: Text(name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (permissionText(role['description']).isNotEmpty)
              Text(permissionText(role['description'])),
            const SizedBox(height: 4),
            Text(
              '$permissions permission${permissions == 1 ? '' : 's'}${system ? ' • System role' : ''}',
            ),
          ],
        ),
        isThreeLine: permissionText(role['description']).isNotEmpty,
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class AdminRoleEditorScreen extends StatefulWidget {
  const AdminRoleEditorScreen({
    super.key,
    this.role,
    required this.permissionCategories,
  });

  final Map<String, dynamic>? role;
  final List<Map<String, dynamic>> permissionCategories;

  @override
  State<AdminRoleEditorScreen> createState() => _AdminRoleEditorScreenState();
}

class _AdminRoleEditorScreenState extends State<AdminRoleEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late Set<int> _permissionIds;
  bool _saving = false;
  bool _deleting = false;

  bool get _editing => widget.role != null;
  String get _id => permissionText(widget.role?['id']);
  bool get _isSystem => widget.role?['is_system'] == true;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: permissionText(widget.role?['name']));
    _description = TextEditingController(
      text: permissionText(widget.role?['description']),
    );
    _permissionIds = _ids(widget.role?['permission_ids']);
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Set<int> _ids(Object? value) => (value is List ? value : const [])
      .map(permissionId)
      .whereType<int>()
      .toSet();

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final data = {
      'name': _name.text.trim(),
      'description': _description.text.trim(),
      'permission_ids': _permissionIds.toList()..sort(),
    };
    try {
      if (_editing) {
        await ApiClient.patch(
          endpoint: '/api/admin/roles/${Uri.encodeComponent(_id)}/',
          data: data,
          requireAuth: true,
        );
      } else {
        await ApiClient.post(
          endpoint: '/api/admin/roles/',
          body: data,
          requireAuth: true,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_editing ? 'Role updated.' : 'Role created.')),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) _showError(_message(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete role?'),
        content: const Text('Users assigned to it will lose this role.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _deleting = true);
    try {
      await ApiClient.delete(
        endpoint: '/api/admin/roles/${Uri.encodeComponent(_id)}/',
        requireAuth: true,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) _showError(_message(error));
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  String _message(Object error) =>
      error.toString().replaceFirst('Exception: ', '');

  void _showError(String text) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text), backgroundColor: Colors.red.shade700),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(_editing ? 'Edit Role' : 'Create Role'),
      actions: [
        if (_editing && !_isSystem)
          IconButton(
            tooltip: 'Delete role',
            onPressed: _deleting ? null : _delete,
            icon: _deleting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_outline),
          ),
      ],
    ),
    body: SafeArea(
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 104),
          children: [
            if (_isSystem)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'This is a system role. Its name can be shown here, while the API controls which changes are permitted.',
                ),
              ),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Role name',
                border: OutlineInputBorder(),
              ),
              validator: (value) => permissionText(value).isEmpty
                  ? 'Role name is required.'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              minLines: 2,
              maxLines: 4,
            ),
            const SizedBox(height: 20),
            Text('Permissions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            AdminPermissionTogglePanel(
              categories: widget.permissionCategories,
              selectedIds: _permissionIds,
              onChanged: (ids) => setState(() => _permissionIds = ids),
            ),
          ],
        ),
      ),
    ),
    bottomNavigationBar: SafeArea(
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
        label: Text(
          _saving
              ? 'Saving...'
              : _editing
              ? 'Save Changes'
              : 'Create Role',
        ),
      ),
    ),
  );
}

class _RoleFailure extends StatelessWidget {
  const _RoleFailure({required this.message, required this.onRetry});

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
