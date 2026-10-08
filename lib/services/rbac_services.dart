import '../comman/api_url.dart';
import '../network/api_client.dart';
import '../modules/rbac/model/rbac_role_model.dart';
import '../modules/rbac/model/rbac_sub_admin_model.dart';

class RbacServices {
  /// ============================================================
  /// FETCH ALL ROLES
  /// ============================================================
  static Future<List<RbacRoleModel>> getRoles({String search = ""}) async {
    // 1. Try canonical /api/rbac/roles/
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
        return list
            .map((e) => RbacRoleModel.fromJson(e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (_) {}

    // 2. Fallback: /api/seller/roles/ or /api/roles/
    try {
      final response = await ApiClient.get(
        endpoint: "/api/seller/roles/",
        requireAuth: true,
        suppressErrorDialog: true,
      );
      final list = _extractList(response);
      return list
          .map((e) => RbacRoleModel.fromJson(e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {}

    try {
      final response = await ApiClient.get(
        endpoint: "/api/roles/",
        requireAuth: true,
        suppressErrorDialog: true,
      );
      final list = _extractList(response);
      return list
          .map((e) => RbacRoleModel.fromJson(e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {}

    return [];
  }

  /// ============================================================
  /// CREATE ROLE
  /// ============================================================
  static Future<Map<String, dynamic>> createRole({
    required String name,
    required String description,
    required List<String> permissions,
  }) async {
    final body = <String, dynamic>{
      "name": name,
      "role_name": name,
      "description": description,
      "permissions": permissions,
    };

    // 1. Primary endpoint
    try {
      return await ApiClient.post(
        endpoint: ApiUrls.rbacRoles,
        body: body,
        requireAuth: true,
        suppressErrorDialog: true,
      );
    } catch (_) {}

    // 2. Fallback endpoint
    try {
      return await ApiClient.post(
        endpoint: ApiUrls.rbacRolesCreate,
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
    required List<String> permissions,
  }) async {
    final body = <String, dynamic>{
      "name": name,
      "role_name": name,
      "description": description,
      "permissions": permissions,
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
      endpoint: "/api/roles/$id/",
      requireAuth: true,
    );
  }

  /// ============================================================
  /// FETCH ALL SUB ADMINS
  /// ============================================================
  static Future<List<RbacSubAdminModel>> getSubAdmins({String search = ""}) async {
    // 1. Try canonical /api/rbac/sub-admins/
    try {
      String endpoint = ApiUrls.rbacSubAdmins;
      if (search.isNotEmpty) endpoint += "?search=${Uri.encodeComponent(search)}";
      final response = await ApiClient.get(
        endpoint: endpoint,
        requireAuth: true,
        suppressErrorDialog: true,
      );
      final list = _extractList(response);
      if (list.isNotEmpty) {
        return list
            .map((e) => RbacSubAdminModel.fromJson(e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (_) {}

    // 2. Fallback /api/seller/sub-admins/
    try {
      final response = await ApiClient.get(
        endpoint: "/api/seller/sub-admins/",
        requireAuth: true,
        suppressErrorDialog: true,
      );
      final list = _extractList(response);
      return list
          .map((e) => RbacSubAdminModel.fromJson(e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {}

    // 3. Fallback /api/sub-admins/
    try {
      final response = await ApiClient.get(
        endpoint: "/api/sub-admins/",
        requireAuth: true,
        suppressErrorDialog: true,
      );
      final list = _extractList(response);
      return list
          .map((e) => RbacSubAdminModel.fromJson(e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {}

    return [];
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
      "email": email,
      "mobile": mobile,
      "username": mobile.isNotEmpty ? mobile : email,
      "password": password,
      "branch_ref_code": branchRefCode,
      if (company != null && company.isNotEmpty) "company": company,
      if (companyId != null) "company_id": companyId,
      if (roleIds != null && roleIds.isNotEmpty) "role_ids": roleIds,
      if (roleIds != null && roleIds.isNotEmpty) "roles": roleIds,
      if (roles != null && roles.isNotEmpty) "role_names": roles,
    };

    // 1. Try canonical /api/rbac/sub-admins/
    try {
      return await ApiClient.post(
        endpoint: ApiUrls.rbacSubAdmins,
        body: body,
        requireAuth: true,
        suppressErrorDialog: true,
      );
    } catch (_) {}

    // 2. Try /api/rbac/sub-admins/create/
    try {
      return await ApiClient.post(
        endpoint: ApiUrls.rbacSubAdminsCreate,
        body: body,
        requireAuth: true,
        suppressErrorDialog: true,
      );
    } catch (_) {}

    // 3. Fallback /api/seller/sub-admins/create/
    return await ApiClient.post(
      endpoint: "/api/seller/sub-admins/create/",
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
      endpoint: "/api/sub-admins/$id/",
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
      endpoint: "/api/sub-admins/$id/",
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
      if (response['roles'] is List) return response['roles'] as List;
      if (response['sub_admins'] is List) return response['sub_admins'] as List;
      if (response['items'] is List) return response['items'] as List;
    }
    return [];
  }
}
