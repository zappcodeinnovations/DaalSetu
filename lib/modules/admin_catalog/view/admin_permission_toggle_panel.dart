import 'package:flutter/material.dart';

List<Map<String, dynamic>> permissionCategoryList(Object? value) =>
    (value is List ? value : const [])
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList();

String permissionText(Object? value) => (value ?? '').toString().trim();

int? permissionId(Object? value) {
  if (value is int) return value;
  return int.tryParse(permissionText(value));
}

/// Shared category picker used by role setup and a Sub Admin's permission
/// overrides. The API accepts permission ids, so the panel intentionally keeps
/// only that small, stable state in its parent screen.
class AdminPermissionTogglePanel extends StatefulWidget {
  const AdminPermissionTogglePanel({
    super.key,
    required this.categories,
    required this.selectedIds,
    required this.onChanged,
    this.inheritedIds = const <int>{},
    this.selectionLabel = 'Allowed',
    this.inheritedLabel = 'Provided by assigned role',
    this.disabledLabel = 'Denied',
  });

  final List<Map<String, dynamic>> categories;
  final Set<int> selectedIds;
  final Set<int> inheritedIds;
  final ValueChanged<Set<int>> onChanged;
  final String selectionLabel;
  final String inheritedLabel;
  final String disabledLabel;

  @override
  State<AdminPermissionTogglePanel> createState() =>
      _AdminPermissionTogglePanelState();
}

class _AdminPermissionTogglePanelState
    extends State<AdminPermissionTogglePanel> {
  late Set<int> _selectedIds;
  String? _categoryKey;

  @override
  void initState() {
    super.initState();
    _selectedIds = {...widget.selectedIds};
    _ensureCategory();
  }

  @override
  void didUpdateWidget(covariant AdminPermissionTogglePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIds != widget.selectedIds) {
      _selectedIds = {...widget.selectedIds};
    }
    _ensureCategory();
  }

  void _ensureCategory() {
    final available = widget.categories
        .map((category) => permissionText(category['key']))
        .where((key) => key.isNotEmpty)
        .toSet();
    if (_categoryKey == null || !available.contains(_categoryKey)) {
      _categoryKey = available.isEmpty ? null : available.first;
    }
  }

  List<Map<String, dynamic>> _maps(Object? value) =>
      (value is List ? value : const [])
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList();

  Map<String, dynamic>? get _category {
    for (final category in widget.categories) {
      if (permissionText(category['key']) == _categoryKey) return category;
    }
    return null;
  }

  void _setAllowed(int id, bool enabled) {
    setState(() {
      if (enabled) {
        _selectedIds.add(id);
      } else {
        _selectedIds.remove(id);
      }
    });
    widget.onChanged({..._selectedIds});
  }

  @override
  Widget build(BuildContext context) {
    if (widget.categories.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Permission catalogue is not available.'),
        ),
      );
    }

    final category = _category;
    final modules = _maps(category?['modules']);
    final selectedCount = _selectedIds.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey(_categoryKey),
          initialValue: _categoryKey,
          decoration: const InputDecoration(
            labelText: 'Permission category',
            border: OutlineInputBorder(),
          ),
          items: widget.categories
              .map(
                (item) => DropdownMenuItem<String>(
                  value: permissionText(item['key']),
                  child: Text(
                    permissionText(item['label']).isEmpty
                        ? permissionText(item['key'])
                        : permissionText(item['label']),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => _categoryKey = value),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Text(
            '$selectedCount permission${selectedCount == 1 ? '' : 's'} selected',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        ...modules.map((module) => _buildModule(context, module)),
      ],
    );
  }

  Widget _buildModule(BuildContext context, Map<String, dynamic> module) {
    final permissions = _maps(module['permissions']);
    if (permissions.isEmpty) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.only(top: 8),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              permissionText(module['name']),
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          ...permissions.map((permission) {
            final id = permissionId(permission['id']);
            if (id == null) return const SizedBox.shrink();
            final directlyAllowed = _selectedIds.contains(id);
            final inherited = widget.inheritedIds.contains(id);
            final enabled = directlyAllowed || inherited;
            final canChange = directlyAllowed || !inherited;
            return SwitchListTile.adaptive(
              value: enabled,
              onChanged: canChange ? (value) => _setAllowed(id, value) : null,
              title: Text(
                permissionText(permission['name']).isEmpty
                    ? permissionText(permission['code'])
                    : permissionText(permission['name']),
              ),
              subtitle: Text(
                directlyAllowed
                    ? widget.selectionLabel
                    : inherited
                    ? widget.inheritedLabel
                    : widget.disabledLabel,
              ),
            );
          }),
        ],
      ),
    );
  }
}
