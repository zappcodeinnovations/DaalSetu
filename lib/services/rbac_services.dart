import '../comman/api_url.dart';
import '../network/api_client.dart';
import '../modules/rbac/model/rbac_role_model.dart';
import '../modules/rbac/model/rbac_sub_admin_model.dart';

class RbacRolesFetchResult {
  final List<RbacRoleModel> roles;
  final List<PermissionPanel> panels;

  RbacRolesFetchResult({required this.roles, required this.panels});
}

class RbacServices {
  /// ============================================================
  /// FETCH ALL ROLES AND PERMISSION CATEGORIES
  /// ============================================================
  static Future<RbacRolesFetchResult> getRolesWithCategories({String search = ""}) async {
    List<RbacRoleModel> roles = [];
    List<PermissionPanel> panels = [];

    // 1. Primary: /api/admin/roles/
    try {
      String endpoint = ApiUrls.rbacRoles;
      if (search.isNotEmpty) endpoint += "?search=${Uri.encodeComponent(search)}";
      final response = await ApiClient.get(
        endpoint: endpoint,
        requireAuth: true,
        suppressErrorDialog: true,
      );

      final list = _extractList(response);
      if (list.isNotEmpty) {
        roles = list
            .map((e) => RbacRoleModel.fromJson(e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e)))
            .toList();
      }

      if (response is Map && response['permission_categories'] is List) {
        final catList = response['permission_categories'] as List;
        for (var c in catList) {
          if (c is Map<String, dynamic>) {
            panels.add(PermissionPanel.fromCategoryJson(c));
          }
        }
      }
    } catch (_) {}

    // Fallback if roles empty
    if (roles.isEmpty) {
      try {
        final response = await ApiClient.get(
          endpoint: "/api/company/roles/",
          requireAuth: true,
          suppressErrorDialog: true,
        );
        final list = _extractList(response);
        roles = list
            .map((e) => RbacRoleModel.fromJson(e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e)))
            .toList();
      } catch (_) {}
    }

    if (panels.isEmpty) {
      panels = PermissionPanel.getDefaultPanels();
    }

    return RbacRolesFetchResult(roles: roles, panels: panels);
  }

  static Future<List<RbacRoleModel>> getRoles({String search = ""}) async {
    final res = await getRolesWithCategories(search: search);
    return res.roles;
  }

  /// ============================================================
  /// FETCH ROLE DETAILS
  /// ============================================================
  static Future<RbacRoleModel?> getRoleDetails(int id) async {
    try {
      final response = await ApiClient.get(
        endpoint: ApiUrls.rbacRoleDetails(id),
        requireAuth: true,
        suppressErrorDialog: true,
      );
      final map = response is Map<String, dynamic>
          ? (response['data'] ?? response['role'] ?? response['result'] ?? response)
          : null;
      if (map is Map<String, dynamic>) {
        return RbacRoleModel.fromJson(map);
      }
    } catch (_) {}
    return null;
  }

  /// ============================================================
  /// CREATE ROLE
  /// ============================================================
  static Future<Map<String, dynamic>> createRole({
    required String name,
    required String description,
    required List<int> permissionIds,
    List<String> permissionCodes = const [],
  }) async {
    final body = <String, dynamic>{
      "name": name,
      "role_name": name,
      "description": description,
      "permission_ids": permissionIds,
      "permissions": permissionIds,
      if (permissionCodes.isNotEmpty) "permission_codes": permissionCodes,
      if (permissionCodes.isNotEmpty) "permission_list": permissionCodes,
      if (permissionCodes.isNotEmpty) "rights": permissionCodes,
    };

    // 1. Primary endpoint: /api/admin/roles/
    try {
      return await ApiClient.post(
        endpoint: ApiUrls.rbacRoles,
        body: body,
        requireAuth: true,
        suppressErrorDialog: true,
      );
    } catch (_) {}

    // 2. Fallback endpoint: /api/company/roles/
    try {
      return await ApiClient.post(
        endpoint: "/api/company/roles/",
        body: body,
        requireAuth: true,
        suppressErrorDialog: true,
      );
    } catch (_) {}

    return await ApiClient.post(
      endpoint: "/api/seller/roles/create/",
      body: body,
      requireAuth: true,
    );
  }

  /// ============================================================
  /// UPDATE ROLE
  /// ============================================================
  static Future<Map<String, dynamic>> updateRole({
    required int id,
    required String name,
    required String description,
    required List<int> permissionIds,
    List<String> permissionCodes = const [],
  }) async {
    final body = <String, dynamic>{
      "name": name,
      "role_name": name,
      "description": description,
      "permission_ids": permissionIds,
      "permissions": permissionIds,
      if (permissionCodes.isNotEmpty) "permission_codes": permissionCodes,
      if (permissionCodes.isNotEmpty) "permission_list": permissionCodes,
      if (permissionCodes.isNotEmpty) "rights": permissionCodes,
    };

    try {
      return await ApiClient.patch(
        endpoint: ApiUrls.rbacRoleDetails(id),
        data: body,
        requireAuth: true,
        suppressErrorDialog: true,
      );
    } catch (_) {}

    return await ApiClient.put(
      endpoint: ApiUrls.rbacRoleDetails(id),
      data: body,
      requireAuth: true,
    );
  }

  /// ============================================================
  /// DELETE ROLE
  /// ============================================================
  static Future<Map<String, dynamic>> deleteRole(int id) async {
    try {
      return await ApiClient.delete(
        endpoint: ApiUrls.rbacRoleDetails(id),
        requireAuth: true,
        suppressErrorDialog: true,
      );
    } catch (_) {}

    return await ApiClient.delete(
      endpoint: "/api/company/roles/$id/",
      requireAuth: true,
    );
  }

  /// ============================================================
  /// FETCH ALL SUB ADMINS
  /// ============================================================
  static Future<List<RbacSubAdminModel>> getSubAdmins({String search = ""}) async {
    final searchParam = search.isNotEmpty ? "?search=${Uri.encodeComponent(search)}" : "";

    final endpoints = [
      "/rbac/sub-admins/$searchParam",
      "/api/sub-admins/$searchParam",
      "/api/admin/sub-admins/$searchParam",
      "/api/seller/sub-admins/$searchParam",
      "/api/buyer/sub-admins/$searchParam",
      "/api/company/sub-admins/$searchParam",
      "/api/company/users/$searchParam",
      "/users/$searchParam",
      "/api/users/?role=sub_admin${search.isNotEmpty ? '&search=${Uri.encodeComponent(search)}' : ''}",
      "/api/users/$searchParam",
    ];

    for (var endpoint in endpoints) {
      try {
        final response = await ApiClient.get(
          endpoint: endpoint,
          requireAuth: true,
          suppressErrorDialog: true,
        );

        if (response is Map && response['raw'] is String) {
          final fromHtml = _parseHtmlTable(response['raw'] as String);
          if (fromHtml.isNotEmpty) {
            return fromHtml;
          }
        }

        final list = _extractList(response);
        if (list.isNotEmpty) {
          final items = list
              .map((e) => RbacSubAdminModel.fromJson(e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e)))
              .where((s) {
                if (endpoint.contains("/api/users/")) {
                  return s.roles.isNotEmpty || s.branchRefCode.isNotEmpty || s.fullName.isNotEmpty;
                }
                return true;
              })
              .toList();

          if (items.isNotEmpty) {
            return items;
          }
        }
      } catch (_) {}
    }

    return [];
  }

  static List<RbacSubAdminModel> _parseHtmlTable(String html) {
    final list = <RbacSubAdminModel>[];
    try {
      final rowRegex = RegExp(r'<tr[^>]*>([\s\S]*?)<\/tr>', caseSensitive: false);
      final cellRegex = RegExp(r'<td[^>]*>([\s\S]*?)<\/td>', caseSensitive: false);
      final tagStripRegex = RegExp(r'<[^>]*>');

      final rows = rowRegex.allMatches(html);
      for (var row in rows) {
        final rowContent = row.group(1) ?? '';
        final cells = cellRegex.allMatches(rowContent).map((m) {
          return (m.group(1) ?? '').replaceAll(tagStripRegex, '').trim();
        }).toList();

        if (cells.length >= 4) {
          final name = cells[0];
          final mobile = cells[1];
          final company = cells[2];
          final role = cells[3];
          final status = cells.length >= 5 ? cells[4] : 'Active';

          if (name.toLowerCase() == 'name' || mobile.toLowerCase() == 'mobile') continue;
          if (name.isEmpty && mobile.isEmpty) continue;

          final nameParts = name.split(' ');
          final fName = nameParts.first;
          final lName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

          final idMatch = RegExp(r'(?:data-id|user-id|users/|sub-admins/)["/]?(\d+)').firstMatch(rowContent);
          final id = idMatch != null ? int.tryParse(idMatch.group(1)!) ?? 0 : list.length + 1;

          list.add(RbacSubAdminModel(
            id: id,
            firstName: fName,
            lastName: lName,
            email: '',
            mobile: mobile,
            branchRefCode: '',
            company: company,
            roles: role.isNotEmpty ? [role] : [],
            isActive: status.toLowerCase().contains('active'),
            createdAt: '',
          ));
        }
      }
    } catch (_) {}
    return list;
  }

  /// ============================================================
  /// CREATE SUB ADMIN
  /// ============================================================
  static Future<Map<String, dynamic>> createSubAdmin({
    required String firstName,
    required String lastName,
    required String email,
    required String mobile,
    required String password,
    required String branchRefCode,
    String? company,
    dynamic companyId,
    List<dynamic>? roleIds,
    List<String>? roles,
  }) async {
    final body = <String, dynamic>{
      "first_name": firstName,
      "last_name": lastName,
      "name": "$firstName $lastName".trim(),
      "email": email,
      "mobile": mobile,
      "username": mobile.isNotEmpty ? mobile : email,
      "password": password,
      "role": "sub_admin",
      "branch_ref_code": branchRefCode,
      if (company != null && company.isNotEmpty) "company": company,
      if (company != null && company.isNotEmpty) "company_name": company,
      if (companyId != null) "company_id": companyId,
      if (roleIds != null && roleIds.isNotEmpty) "role_ids": roleIds,
      if (roleIds != null && roleIds.isNotEmpty) "roles": roleIds,
      if (roles != null && roles.isNotEmpty) "role_names": roles,
    };

    final createEndpoints = [
      "/rbac/sub-admins/",
      ApiUrls.addUser, // /api/adduser/
      ApiUrls.rbacSubAdmins, // /api/admin/sub-admins/
      ApiUrls.rbacSubAdminsCreate, // /api/admin/sub-admins/create/
      "/api/company/sub-admins/",
      "/api/users/create/",
      "/users/create/",
    ];

    for (var endpoint in createEndpoints) {
      try {
        return await ApiClient.post(
          endpoint: endpoint,
          body: body,
          requireAuth: true,
          suppressErrorDialog: true,
        );
      } catch (_) {}
    }

    return await ApiClient.post(
      endpoint: ApiUrls.addUser,
      body: body,
      requireAuth: true,
    );
  }

  /// ============================================================
  /// TOGGLE SUB ADMIN STATUS (ACTIVE / INACTIVE)
  /// ============================================================
  static Future<Map<String, dynamic>> toggleSubAdminStatus(int id, bool isActive) async {
    final body = {"is_active": isActive, "active": isActive};
    try {
      return await ApiClient.patch(
        endpoint: ApiUrls.rbacSubAdminDetails(id),
        data: body,
        requireAuth: true,
        suppressErrorDialog: true,
      );
    } catch (_) {}

    try {
      return await ApiClient.post(
        endpoint: ApiUrls.rbacSubAdminToggleStatus(id),
        body: body,
        requireAuth: true,
        suppressErrorDialog: true,
      );
    } catch (_) {}

    return await ApiClient.patch(
      endpoint: "/api/users/$id/",
      data: body,
      requireAuth: true,
    );
  }

  /// ============================================================
  /// DELETE SUB ADMIN
  /// ============================================================
  static Future<Map<String, dynamic>> deleteSubAdmin(int id) async {
    try {
      return await ApiClient.delete(
        endpoint: ApiUrls.rbacSubAdminDetails(id),
        requireAuth: true,
        suppressErrorDialog: true,
      );
    } catch (_) {}

    return await ApiClient.delete(
      endpoint: "/api/users/$id/",
      requireAuth: true,
    );
  }

  /// ============================================================
  /// HELPER: EXTRACT LIST
  /// ============================================================
  static List<dynamic> _extractList(dynamic response) {
    if (response == null) return [];
    if (response is List) return response;
    if (response is Map) {
      if (response['results'] is List) return response['results'] as List;
      if (response['data'] is List) return response['data'] as List;
      if (response['body'] is List) return response['body'] as List;
      if (response['roles'] is List) return response['roles'] as List;
      if (response['sub_admins'] is List) return response['sub_admins'] as List;
      if (response['users'] is List) return response['users'] as List;
      if (response['items'] is List) return response['items'] as List;
      if (response['list'] is List) return response['list'] as List;
      if (response['data'] is Map && response['data']['results'] is List) {
        return response['data']['results'] as List;
      }
      if (response['data'] is Map && response['data']['users'] is List) {
        return response['data']['users'] as List;
      }
      if (response['data'] is Map && response['data']['sub_admins'] is List) {
        return response['data']['sub_admins'] as List;
      }
      if (response['body'] is Map && response['body']['results'] is List) {
        return response['body']['results'] as List;
      }
    }
    return [];
  }
}
