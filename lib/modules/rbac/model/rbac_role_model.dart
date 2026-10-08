class RbacRoleModel {
  final int id;
  final String name;
  final String slug;
  final String description;
  final List<int> permissionIds;
  final List<String> permissions;
  final bool isSystem;
  final String updatedAt;
  final int? subAdminsCount;

  RbacRoleModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.permissionIds,
    required this.permissions,
    required this.isSystem,
    required this.updatedAt,
    this.subAdminsCount,
  });

  int get totalPermissions => permissionIds.isNotEmpty ? permissionIds.length : permissions.length;

  factory RbacRoleModel.fromJson(Map<String, dynamic> json) {
    int parseId(dynamic val) {
      if (val is int) return val;
      return int.tryParse(val?.toString() ?? '0') ?? 0;
    }

    List<int> parseIds(dynamic raw) {
      if (raw is List) {
        final list = <int>[];
        for (var e in raw) {
          if (e is int) {
            list.add(e);
          } else if (e is Map && e['id'] != null) {
            final id = parseId(e['id']);
            if (id > 0) list.add(id);
          } else if (e != null) {
            final id = int.tryParse(e.toString());
            if (id != null) list.add(id);
          }
        }
        return list;
      }
      return [];
    }

    List<String> parseStrings(dynamic raw) {
      if (raw is List) {
        return raw.map((e) {
          if (e is Map) return e['code']?.toString() ?? e['codename']?.toString() ?? e['name']?.toString() ?? e.toString();
          return e.toString();
        }).toList();
      }
      return [];
    }

    final pIds = parseIds(json['permission_ids'] ?? json['permissions']);
    final pNames = parseStrings(json['permissions'] ?? json['permission_list'] ?? json['rights']);

    return RbacRoleModel(
      id: parseId(json['id'] ?? json['role_id']),
      name: json['name']?.toString() ?? json['role_name']?.toString() ?? 'Role',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      permissionIds: pIds,
      permissions: pNames,
      isSystem: json['is_system'] == true,
      updatedAt: json['updated_at']?.toString() ?? json['created_at']?.toString() ?? '',
      subAdminsCount: json['sub_admins_count'] is int
          ? json['sub_admins_count'] as int
          : (json['users_count'] is int ? json['users_count'] as int : null),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'description': description,
        'permission_ids': permissionIds,
        'permissions': permissionIds,
        'updated_at': updatedAt,
      };
}

class PermissionItem {
  final int id;
  final String code;
  final String label;
  final String module;

  const PermissionItem({
    required this.id,
    required this.code,
    required this.label,
    this.module = '',
  });

  factory PermissionItem.fromJson(Map<String, dynamic> json) {
    int parseId(dynamic val) {
      if (val is int) return val;
      return int.tryParse(val?.toString() ?? '0') ?? 0;
    }

    return PermissionItem(
      id: parseId(json['id']),
      code: json['code']?.toString() ?? json['codename']?.toString() ?? '',
      label: json['name']?.toString() ?? json['label']?.toString() ?? '',
      module: json['module']?.toString() ?? '',
    );
  }
}

class PermissionGroup {
  final String title;
  final List<PermissionItem> items;

  const PermissionGroup({required this.title, required this.items});
}

class PermissionPanel {
  final String key;
  final String name;
  final List<PermissionGroup> groups;

  const PermissionPanel({
    required this.key,
    required this.name,
    required this.groups,
  });

  factory PermissionPanel.fromCategoryJson(Map<String, dynamic> json) {
    final modulesList = json['modules'];
    final groups = <PermissionGroup>[];

    if (modulesList is List) {
      for (var m in modulesList) {
        if (m is Map<String, dynamic>) {
          final modName = m['name']?.toString() ?? 'MODULE';
          final title = modName.replaceAll('_', ' ').toUpperCase();
          final permsRaw = m['permissions'];
          final items = <PermissionItem>[];
          if (permsRaw is List) {
            for (var p in permsRaw) {
              if (p is Map<String, dynamic>) {
                items.add(PermissionItem.fromJson(p));
              }
            }
          }
          if (items.isNotEmpty) {
            groups.add(PermissionGroup(title: title, items: items));
          }
        }
      }
    }

    return PermissionPanel(
      key: json['key']?.toString() ?? '',
      name: json['label']?.toString() ?? json['name']?.toString() ?? 'Category',
      groups: groups,
    );
  }

  static List<PermissionPanel> getDefaultPanels() {
    return const [
      PermissionPanel(
        key: "user_management",
        name: "User Management",
        groups: [
          PermissionGroup(
            title: "BRANCHES",
            items: [
              PermissionItem(id: 13, code: "manage_branches", label: "Manage Branches", module: "branches"),
              PermissionItem(id: 12, code: "view_branches", label: "View Branches", module: "branches"),
            ],
          ),
          PermissionGroup(
            title: "REGISTERED COMPANIES",
            items: [
              PermissionItem(id: 2, code: "manage_registered_companies", label: "Manage Registered Companies", module: "registered_companies"),
              PermissionItem(id: 1, code: "view_registered_companies", label: "View Registered Companies", module: "registered_companies"),
            ],
          ),
        ],
      ),
      PermissionPanel(
        key: "offers",
        name: "Offers & Requirements",
        groups: [
          PermissionGroup(
            title: "OFFERS & PRODUCTS",
            items: [
              PermissionItem(id: 101, code: "manage_offers", label: "Manage Offers & Products", module: "offers"),
              PermissionItem(id: 102, code: "view_offers", label: "View Offers & Products", module: "offers"),
            ],
          ),
          PermissionGroup(
            title: "BUYER REQUIREMENTS",
            items: [
              PermissionItem(id: 103, code: "manage_requirements", label: "Manage Requirements", module: "requirements"),
              PermissionItem(id: 104, code: "view_requirements", label: "View Requirements", module: "requirements"),
            ],
          ),
        ],
      ),
      PermissionPanel(
        key: "deals_logistics",
        name: "Deals & Logistics",
        groups: [
          PermissionGroup(
            title: "DEALS & CONTRACTS",
            items: [
              PermissionItem(id: 201, code: "manage_contracts", label: "Manage Deals & Contracts", module: "contracts"),
              PermissionItem(id: 202, code: "view_contracts", label: "View Deals & Contracts", module: "contracts"),
            ],
          ),
          PermissionGroup(
            title: "DELIVERY CHALLANS",
            items: [
              PermissionItem(id: 203, code: "manage_challans", label: "Manage Delivery Challans", module: "challans"),
              PermissionItem(id: 204, code: "view_challans", label: "View Delivery Challans", module: "challans"),
            ],
          ),
        ],
      ),
      PermissionPanel(
        key: "rbac",
        name: "Team & Permissions",
        groups: [
          PermissionGroup(
            title: "SUB ADMINS",
            items: [
              PermissionItem(id: 301, code: "manage_sub_admins", label: "Manage Sub Admins", module: "sub_admins"),
              PermissionItem(id: 302, code: "view_sub_admins", label: "View Sub Admins", module: "sub_admins"),
            ],
          ),
          PermissionGroup(
            title: "ROLES & RBAC",
            items: [
              PermissionItem(id: 303, code: "manage_roles", label: "Manage Roles", module: "roles"),
              PermissionItem(id: 304, code: "view_roles", label: "View Roles", module: "roles"),
            ],
          ),
        ],
      ),
    ];
  }
}
