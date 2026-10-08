class RbacRoleModel {
  final int id;
  final String name;
  final String description;
  final List<String> permissions;
  final String createdAt;
  final int? subAdminsCount;

  RbacRoleModel({
    required this.id,
    required this.name,
    required this.description,
    required this.permissions,
    required this.createdAt,
    this.subAdminsCount,
  });

  factory RbacRoleModel.fromJson(Map<String, dynamic> json) {
    int parseId(dynamic val) {
      if (val is int) return val;
      return int.tryParse(val?.toString() ?? '0') ?? 0;
    }

    List<String> parsePermissions(dynamic raw) {
      if (raw is List) {
        return raw.map((e) {
          if (e is Map) return e['codename']?.toString() ?? e['name']?.toString() ?? e.toString();
          return e.toString();
        }).toList();
      }
      return [];
    }

    return RbacRoleModel(
      id: parseId(json['id'] ?? json['role_id']),
      name: json['name']?.toString() ?? json['role_name']?.toString() ?? 'Role',
      description: json['description']?.toString() ?? '',
      permissions: parsePermissions(json['permissions'] ?? json['permission_list'] ?? json['rights']),
      createdAt: json['created_at']?.toString() ?? '',
      subAdminsCount: json['sub_admins_count'] is int
          ? json['sub_admins_count'] as int
          : (json['users_count'] is int ? json['users_count'] as int : null),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role_name': name,
        'description': description,
        'permissions': permissions,
        'created_at': createdAt,
      };
}

class PermissionItem {
  final String code;
  final String label;

  const PermissionItem({required this.code, required this.label});
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
