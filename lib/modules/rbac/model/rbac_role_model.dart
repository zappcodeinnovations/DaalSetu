class RbacRoleModel {
  final int id;
  final String name;
  final String description;
  final List<String> permissions;
  final int permissionsCount;
  final String createdAt;
  final int? subAdminsCount;
  final dynamic rawPermissions;

  RbacRoleModel({
    required this.id,
    required this.name,
    required this.description,
    required this.permissions,
    required this.permissionsCount,
    required this.createdAt,
    this.subAdminsCount,
    this.rawPermissions,
  });

  int get totalPermissions => permissionsCount > 0 ? permissionsCount : permissions.length;

  factory RbacRoleModel.fromJson(Map<String, dynamic> json) {
    int parseId(dynamic val) {
      if (val is int) return val;
      return int.tryParse(val?.toString() ?? '0') ?? 0;
    }

    int parseCount(dynamic raw) {
      if (raw is int) return raw;
      if (raw is String) return int.tryParse(raw) ?? 0;
      return 0;
    }

    List<String> parsePermissionsList(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) {
        final list = <String>[];
        for (var e in raw) {
          if (e == null) continue;
          if (e is Map) {
            final code = e['codename'] ?? e['code'] ?? e['name'] ?? e['slug'] ?? e['permission'];
            if (code != null) list.add(code.toString());
          } else {
            list.add(e.toString());
          }
        }
        return list;
      }
      if (raw is Map) {
        final list = <String>[];
        raw.forEach((k, v) {
          if (v == true || v == 1 || v == 'true' || v == 'allow') {
            list.add(k.toString());
          } else if (v is List) {
            for (var item in v) {
              list.add(item.toString());
            }
          } else if (v is Map) {
            v.forEach((subK, subV) {
              if (subV == true || subV == 1 || subV == 'true') {
                list.add("${k}_$subK");
              }
            });
          }
        });
        return list;
      }
      return [];
    }

    final rawPerms = json['permissions'] ??
        json['permission_list'] ??
        json['permissions_list'] ??
        json['role_permissions'] ??
        json['permissions_data'] ??
        json['rights'] ??
        json['access'];

    final parsedList = parsePermissionsList(rawPerms);

    final count = json['permissions_count'] != null
        ? parseCount(json['permissions_count'])
        : (json['permission_count'] != null
            ? parseCount(json['permission_count'])
            : (json['total_permissions'] != null
                ? parseCount(json['total_permissions'])
                : (json['permissions'] is int
                    ? parseCount(json['permissions'])
                    : parsedList.length)));

    return RbacRoleModel(
      id: parseId(json['id'] ?? json['role_id']),
      name: json['name']?.toString() ?? json['role_name']?.toString() ?? 'Role',
      description: json['description']?.toString() ?? '',
      permissions: parsedList,
      permissionsCount: count,
      createdAt: json['created_at']?.toString() ?? '',
      subAdminsCount: json['sub_admins_count'] is int
          ? json['sub_admins_count'] as int
          : (json['users_count'] is int ? json['users_count'] as int : null),
      rawPermissions: rawPerms,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role_name': name,
        'description': description,
        'permissions': permissions,
        'permissions_count': totalPermissions,
        'created_at': createdAt,
      };
}

class PermissionItem {
  final String code;
  final String label;
  final int? id;

  const PermissionItem({required this.code, required this.label, this.id});
}

class PermissionGroup {
  final String title;
  final List<PermissionItem> items;

  const PermissionGroup({required this.title, required this.items});
}

class PermissionPanel {
  final String name;
  final List<PermissionGroup> groups;

  const PermissionPanel({required this.name, required this.groups});

  static List<PermissionPanel> getDefaultPanels() {
    return const [
      PermissionPanel(
        name: "User Management",
        groups: [
          PermissionGroup(
            title: "BRANCHES",
            items: [
              PermissionItem(code: "manage_branches", label: "Manage Branches"),
              PermissionItem(code: "view_branches", label: "View Branches"),
            ],
          ),
          PermissionGroup(
            title: "REGISTERED COMPANIES",
            items: [
              PermissionItem(code: "manage_registered_companies", label: "Manage Registered Companies"),
              PermissionItem(code: "view_registered_companies", label: "View Registered Companies"),
            ],
          ),
        ],
      ),
      PermissionPanel(
        name: "Offers & Requirements",
        groups: [
          PermissionGroup(
            title: "OFFERS & PRODUCTS",
            items: [
              PermissionItem(code: "manage_offers", label: "Manage Offers & Products"),
              PermissionItem(code: "view_offers", label: "View Offers & Products"),
            ],
          ),
          PermissionGroup(
            title: "BUYER REQUIREMENTS",
            items: [
              PermissionItem(code: "manage_requirements", label: "Manage Requirements"),
              PermissionItem(code: "view_requirements", label: "View Requirements"),
            ],
          ),
        ],
      ),
      PermissionPanel(
        name: "Deals & Logistics",
        groups: [
          PermissionGroup(
            title: "DEALS & CONTRACTS",
            items: [
              PermissionItem(code: "manage_contracts", label: "Manage Deals & Contracts"),
              PermissionItem(code: "view_contracts", label: "View Deals & Contracts"),
            ],
          ),
          PermissionGroup(
            title: "DELIVERY CHALLANS",
            items: [
              PermissionItem(code: "manage_challans", label: "Manage Delivery Challans"),
              PermissionItem(code: "view_challans", label: "View Delivery Challans"),
            ],
          ),
        ],
      ),
      PermissionPanel(
        name: "Team & Permissions",
        groups: [
          PermissionGroup(
            title: "SUB ADMINS",
            items: [
              PermissionItem(code: "manage_sub_admins", label: "Manage Sub Admins"),
              PermissionItem(code: "view_sub_admins", label: "View Sub Admins"),
            ],
          ),
          PermissionGroup(
            title: "ROLES & RBAC",
            items: [
              PermissionItem(code: "manage_roles", label: "Manage Roles"),
              PermissionItem(code: "view_roles", label: "View Roles"),
            ],
          ),
        ],
      ),
    ];
  }
}
