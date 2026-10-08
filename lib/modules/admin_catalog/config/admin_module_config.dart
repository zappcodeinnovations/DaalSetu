import 'package:flutter/material.dart';
import 'package:daalsetu/modules/admin_catalog/view/assign_vehicle_dialog.dart';
import 'package:daalsetu/modules/admin_catalog/view/offer_interests_dialog.dart';
import 'package:daalsetu/modules/admin_catalog/config/admin_detail_config.dart';
import 'package:daalsetu/modules/admin_catalog/config/admin_actions.dart';
import 'package:daalsetu/modules/admin_catalog/model/admin_record.dart';
import 'package:daalsetu/network/api_client.dart';

enum AdminRequestMethod { post, patch }

class AdminCustomAction {
  const AdminCustomAction({
    required this.title,
    required this.icon,
    required this.onPressed,
    this.isVisible,
  });

  final String title;
  final IconData icon;
  final Future<bool> Function(BuildContext context, Map<String, dynamic> record) onPressed;
  final bool Function(Map<String, dynamic> record)? isVisible;
}

class AdminFieldConfig {
  const AdminFieldConfig(
    this.key,
    this.label, {
    this.required = false,
    this.numeric = false,
    this.multiline = false,
    this.options = const [],
    this.defaultValue,
    this.hiddenValue,
    this.isDate = false,
    this.optionLabels = const {},
    this.optionsLoader,
    this.multiSelect = false,
    this.isFile = false,
    this.initialValue,
    this.createOnly = false,
    this.singleSelectAsList = false,
    this.sendAsBoolean = false,
  });

  final String key;
  final String label;
  final bool required;
  final bool numeric;
  final bool multiline;
  final bool isDate;
  final List<String> options;
  final String? defaultValue;
  final Object? hiddenValue;

  /// Readable labels for [options] (value -> label).
  final Map<String, String> optionLabels;

  /// Loads dropdown choices from the server instead of [options].
  final Future<List<AdminOption>> Function()? optionsLoader;

  /// Sends a list of ids (e.g. category_ids) instead of one value.
  final bool multiSelect;

  /// A picked image/file; the form is then sent as multipart/form-data.
  final bool isFile;

  /// Value to show when editing, for fields the record nests (e.g. transporter.id).
  final Object? Function(Map<String, dynamic> record)? initialValue;

  /// Shown and sent only when creating (e.g. password).
  final bool createOnly;

  /// Renders one dropdown but sends the selected id inside a one-item list.
  final bool singleSelectAsList;

  /// Converts the dropdown values `true` / `false` to JSON booleans.
  final bool sendAsBoolean;
}

class AdminModuleConfig {
  const AdminModuleConfig({
    required this.key,
    required this.title,
    required this.icon,
    required this.listEndpoint,
    required this.titleKeys,
    this.subtitleKeys = const [],
    this.searchParameter = 'search',
    this.filterParameter,
    this.filterOptions = const [],
    this.staticQuery = const {},
    this.detailEndpoint,
    this.createEndpoint,
    this.updateEndpoint,
    this.deleteEndpoint,
    this.updateMethod = AdminRequestMethod.patch,
    this.fields = const [],
    this.customActions = const [],
    this.detailSections = const [],
    this.clientFilter,
    this.idKey,
  });

  final String key;
  final String title;
  final IconData icon;
  final String listEndpoint;
  final List<String> titleKeys;
  final List<String> subtitleKeys;
  final String? searchParameter;
  final String? filterParameter;
  final List<String> filterOptions;
  final Map<String, String> staticQuery;
  final String Function(String id)? detailEndpoint;
  final String? createEndpoint;
  final String Function(String id)? updateEndpoint;
  final String Function(String id)? deleteEndpoint;
  final AdminRequestMethod updateMethod;
  final List<AdminFieldConfig> fields;
  final List<AdminCustomAction> customActions;
  final List<AdminDetailSection> detailSections;
  final bool Function(Map<String, dynamic> item)? clientFilter;

  /// Record field used in item URLs when it is not `id` (e.g. rfq_id).
  final String? idKey;

  String recordId(AdminRecord record) =>
      idKey == null ? record.id : (record[idKey!] ?? record.id).toString();

  bool get canCreate => createEndpoint != null && fields.isNotEmpty;
  bool get canEdit => updateEndpoint != null && fields.isNotEmpty;
  bool get canDelete => deleteEndpoint != null;
}

Object? transporterIdOf(Map<String, dynamic> record) =>
    record['transporter'] is Map ? (record['transporter'] as Map)['id'] : record['transporter_id'];

Object? parentAdminIdOf(Map<String, dynamic> record) =>
    record['parent_admin'] is Map ? (record['parent_admin'] as Map)['id'] : null;

Object? roleIdsOf(Map<String, dynamic> record) =>
    (record['roles'] is List ? record['roles'] as List : const []).map((role) => role is Map ? role['id'] : role).toList();

Object? assignedAdminIdOf(Map<String, dynamic> record) {
  final admins = record['assigned_admins'];
  if (admins is List && admins.isNotEmpty) {
    final first = admins.first;
    return first is Map ? first['id'] : first;
  }
  final ids = record['assigned_admin_ids'];
  return ids is List && ids.isNotEmpty ? ids.first : null;
}

class AdminModules {
  AdminModules._();

  // Same fields as the web "Add User" form; the backend needs email, mobile and password.
  static const userFields = [
    AdminFieldConfig('first_name', 'First name', required: true),
    AdminFieldConfig('last_name', 'Last name'),
    AdminFieldConfig('mobile', 'Mobile number', required: true, numeric: true),
    AdminFieldConfig('email', 'Email', required: true),
    AdminFieldConfig('password', 'Password', required: true, createOnly: true),
    AdminFieldConfig(
      'role',
      'Role',
      required: true,
      // Super Admin can also create admins; the backend rejects roles the caller may not create.
      options: ['seller', 'buyer', 'transporter', 'admin'],
      optionLabels: {'seller': 'Seller', 'buyer': 'Buyer', 'transporter': 'Transporter', 'admin': 'Admin'},
    ),
    AdminFieldConfig('branch_code', 'Branch code'),
    AdminFieldConfig('assigned_category_ids', 'Buyer categories (buyers only)', multiSelect: true, optionsLoader: loadCategoryOptions),
    AdminFieldConfig('pan_number', 'PAN number'),
    AdminFieldConfig('gst_number', 'GST number'),
  ];

  static const userDetailSections = [
    AdminDetailSection(
      title: 'Account Information',
      fields: [
        AdminDetailField('id', 'User ID', copyable: true),
        AdminDetailField('username', 'Name'),
        AdminDetailField('mobile', 'Mobile Number', type: AdminDetailFieldType.phone),
        AdminDetailField('email', 'Email Address', type: AdminDetailFieldType.email),
      ],
    ),
    AdminDetailSection(
      title: 'Profile Details',
      fields: [
        AdminDetailField('first_name', 'First Name'),
        AdminDetailField('last_name', 'Last Name'),
        AdminDetailField('company_name', 'Company Name'),
      ],
    ),
    AdminDetailSection(
      title: 'Application Status',
      fields: [
        AdminDetailField('role', 'Role'),
        AdminDetailField('kyc_status', 'KYC Status', type: AdminDetailFieldType.status),
        AdminDetailField('is_active', 'Active Status', type: AdminDetailFieldType.boolean),
      ],
    ),
    AdminDetailSection(
      title: 'Compliance',
      fields: [
        AdminDetailField('pan_number', 'PAN Number', copyable: true),
        AdminDetailField('gst_number', 'GST Number', copyable: true),
      ],
    ),
    AdminDetailSection(
      title: 'Metadata',
      fields: [
        AdminDetailField('created_at', 'Created At', type: AdminDetailFieldType.date),
        AdminDetailField('updated_at', 'Updated At', type: AdminDetailFieldType.date),
      ],
    ),
  ];

  static final Map<String, AdminModuleConfig> all = {
    'users': AdminModuleConfig(
      key: 'users',
      title: 'User Management',
      icon: Icons.people_alt_outlined,
      listEndpoint: '/api/users/',
      titleKeys: const ['username', 'name', 'mobile'],
      subtitleKeys: const ['role', 'mobile', 'email', 'kyc_status'],
      detailEndpoint: (id) => '/api/users/$id/',
      filterParameter: 'role',
      filterOptions: const ['buyer', 'seller', 'transporter', 'admin'],
      createEndpoint: '/api/users/create/',
      updateEndpoint: (id) => '/api/users/$id/update/',
      deleteEndpoint: (id) => '/api/users/$id/delete/',
      fields: userFields,
      detailSections: userDetailSections,
      customActions: [userStatusAction()],
    ),
    // Web "Salesman" panel = sub admin users (role sub_admin), managed with the same rules as the web form.
    'salesman': AdminModuleConfig(
      key: 'salesman',
      title: 'Sub Admins',
      icon: Icons.support_agent_outlined,
      listEndpoint: '/api/admin/sub-admin-accounts/',
      titleKeys: const ['name', 'mobile'],
      subtitleKeys: const ['status', 'mobile', 'email', 'roles', 'company'],
      detailEndpoint: (id) => '/api/admin/sub-admin-accounts/$id/',
      filterParameter: 'status',
      filterOptions: const ['active', 'deactivated', 'suspended'],
      createEndpoint: '/api/admin/sub-admin-accounts/',
      updateEndpoint: (id) => '/api/admin/sub-admin-accounts/$id/',
      // DELETE on this API deactivates the account (reversible with Activate).
      deleteEndpoint: (id) => '/api/admin/sub-admin-accounts/$id/',
      fields: const [
        AdminFieldConfig('first_name', 'First name', required: true),
        AdminFieldConfig('last_name', 'Last name'),
        AdminFieldConfig('email', 'Email', required: true),
        AdminFieldConfig('mobile', 'Mobile number', required: true, numeric: true),
        AdminFieldConfig('password', 'Password', required: true, createOnly: true),
        AdminFieldConfig('company_id', 'Company', required: true, optionsLoader: loadSubAdminCompanyOptions),
        AdminFieldConfig('parent_admin_id', 'Under Admin (Super Admin only)', optionsLoader: loadParentAdminOptions,
            initialValue: parentAdminIdOf),
        AdminFieldConfig('access_role_ids', 'Roles', required: true, multiSelect: true, optionsLoader: loadSubAdminRoleOptions,
            initialValue: roleIdsOf),
      ],
      detailSections: [
        const AdminDetailSection(
          title: 'Account',
          fields: [
            AdminDetailField('id', 'User ID', copyable: true),
            AdminDetailField('name', 'Name'),
            AdminDetailField('mobile', 'Mobile', type: AdminDetailFieldType.phone),
            AdminDetailField('email', 'Email', type: AdminDetailFieldType.email),
            AdminDetailField('status', 'Status', type: AdminDetailFieldType.status),
            AdminDetailField('suspension_reason', 'Suspension Reason'),
          ],
        ),
        const AdminDetailSection(
          title: 'Assignment',
          fields: [
            AdminDetailField('parent_admin', 'Under Admin'),
            AdminDetailField('company', 'Company'),
            AdminDetailField('branch', 'Branch'),
            AdminDetailField('roles', 'Roles'),
          ],
        ),
        const AdminDetailSection(
          title: 'Activity',
          fields: [
            AdminDetailField('date_joined', 'Joined', type: AdminDetailFieldType.date),
            AdminDetailField('last_login', 'Last Login', type: AdminDetailFieldType.date),
          ],
        ),
      ],
      customActions: [
        adminPostAction(
          title: 'Suspend',
          icon: Icons.block_outlined,
          endpoint: (record) => '/api/admin/sub-admin-accounts/${record['id']}/',
          action: 'suspend',
          confirmMessage: 'The Sub Admin will not be able to log in until activated.',
          noteKey: 'reason',
          noteLabel: 'Reason',
          noteRequired: true,
          destructive: true,
          isVisible: (record) => recordStatus(record) == 'active',
        ),
        adminPostAction(
          title: 'Activate',
          icon: Icons.check_circle_outline,
          endpoint: (record) => '/api/admin/sub-admin-accounts/${record['id']}/',
          action: 'activate',
          confirmMessage: 'Allow this Sub Admin to log in again?',
          isVisible: (record) => recordStatus(record) != 'active',
        ),
      ],
    ),
    'kyc': AdminModuleConfig(
      key: 'kyc',
      title: 'User KYCs',
      icon: Icons.verified_user_outlined,
      listEndpoint: '/api/kyc/list/',
      titleKeys: const ['username', 'name', 'mobile'],
      subtitleKeys: const ['role', 'kyc_status', 'mobile'],
      detailEndpoint: (id) => '/api/users/$id/',
      filterParameter: 'kyc_status',
      filterOptions: const ['pending', 'approved', 'rejected'],
      detailSections: [
        const AdminDetailSection(
          title: 'User Information',
          fields: [
            AdminDetailField('id', 'User ID', copyable: true),
            AdminDetailField('username', 'Name'),
            AdminDetailField('mobile', 'Mobile Number', type: AdminDetailFieldType.phone),
            AdminDetailField('email', 'Email', type: AdminDetailFieldType.email),
            AdminDetailField('role', 'Role'),
          ],
        ),
        const AdminDetailSection(
          title: 'KYC Details',
          fields: [
            AdminDetailField('kyc_status', 'KYC Status', type: AdminDetailFieldType.status),
            AdminDetailField('rejection_reason', 'Rejection Reason'),
            AdminDetailField('remarks', 'Remarks'),
          ],
        ),
        const AdminDetailSection(
          title: 'Documents',
          fields: [
            AdminDetailField('pan_number', 'PAN Number', copyable: true),
            AdminDetailField('pan_card_upload', 'PAN Card', type: AdminDetailFieldType.image),
            AdminDetailField('gst_number', 'GST Number', copyable: true),
            AdminDetailField('gst_certificate_upload', 'GST Certificate', type: AdminDetailFieldType.image),
            AdminDetailField('adhar_front_upload', 'Aadhar Front', type: AdminDetailFieldType.image),
            AdminDetailField('adhar_back_upload', 'Aadhar Back', type: AdminDetailFieldType.image),
          ],
        ),
      ],
      // Same rules as the web KYC page.
      customActions: [
        adminPostAction(
          title: 'Approve',
          icon: Icons.verified_outlined,
          endpoint: (record) => '/api/kyc/${record['id']}/approve/',
          action: 'approve',
          confirmMessage: "Approve this user's KYC documents?",
          isVisible: (record) => (record['kyc_status'] ?? '').toString().toLowerCase() != 'approved',
        ),
        adminPostAction(
          title: 'Reject',
          icon: Icons.cancel_outlined,
          endpoint: (record) => '/api/kyc/${record['id']}/reject/',
          action: 'reject',
          confirmMessage: 'The user will see this reason and can submit again.',
          noteKey: 'rejection_reason',
          noteLabel: 'Rejection reason',
          noteRequired: true,
          destructive: true,
          isVisible: (record) => const ['pending', 'rejected'].contains((record['kyc_status'] ?? '').toString().toLowerCase()),
        ),
      ],
    ),
    'branch_requests': AdminModuleConfig(
      key: 'branch_requests',
      title: 'Branch Requests',
      icon: Icons.how_to_reg_outlined,
      listEndpoint: '/api/admin/branch-requests/',
      titleKeys: const ['user'],
      subtitleKeys: const ['status', 'branch', 'request_note', 'created_at'],
      filterParameter: 'status',
      filterOptions: const ['pending', 'approved', 'rejected'],
      detailSections: [
        const AdminDetailSection(
          title: 'User',
          fields: [
            AdminDetailField('user.name', 'Name'),
            AdminDetailField('user.mobile', 'Mobile', type: AdminDetailFieldType.phone),
            AdminDetailField('user.role', 'Role'),
          ],
        ),
        const AdminDetailSection(
          title: 'Branch Request',
          fields: [
            AdminDetailField('id', 'Request ID', copyable: true),
            AdminDetailField('branch.name', 'Branch'),
            AdminDetailField('branch.branch_code', 'Branch Code', copyable: true),
            AdminDetailField('status', 'Status', type: AdminDetailFieldType.status),
            AdminDetailField('request_note', 'Request Note'),
            AdminDetailField('created_at', 'Requested At', type: AdminDetailFieldType.date),
            AdminDetailField('review_note', 'Review Note'),
            AdminDetailField('reviewed_at', 'Reviewed At', type: AdminDetailFieldType.date),
          ],
        ),
      ],
      customActions: [
        adminPostAction(
          title: 'Approve',
          icon: Icons.check_circle_outline,
          endpoint: (record) => '/api/admin/branch-requests/${record['id']}/',
          action: 'approve',
          confirmMessage: 'Approve this user for the requested branch?',
          noteKey: 'review_note',
          noteLabel: 'Review note',
          isVisible: (record) => recordStatus(record) == 'pending',
        ),
        adminPostAction(
          title: 'Reject',
          icon: Icons.cancel_outlined,
          endpoint: (record) => '/api/admin/branch-requests/${record['id']}/',
          action: 'reject',
          confirmMessage: 'Reject this branch request?',
          noteKey: 'review_note',
          noteLabel: 'Review note',
          destructive: true,
          isVisible: (record) => recordStatus(record) == 'pending',
        ),
      ],
    ),
    'branches': AdminModuleConfig(
      key: 'branches',
      title: 'Branch Master',
      icon: Icons.account_tree_outlined,
      listEndpoint: '/api/admin/branches/',
      titleKeys: const ['location_name', 'branch_code'],
      subtitleKeys: const ['branch_code', 'state', 'city', 'is_active'],
      filterParameter: 'status',
      filterOptions: const ['active', 'inactive'],
      createEndpoint: '/api/branch/create/',
      updateEndpoint: (id) => '/api/branch/update/$id/',
      deleteEndpoint: (id) => '/api/branch/delete/$id/',
      updateMethod: AdminRequestMethod.post,
      fields: [
        const AdminFieldConfig('location_name', 'Location name', required: true),
        const AdminFieldConfig('state', 'State', required: true),
        const AdminFieldConfig('city', 'City', required: true),
        const AdminFieldConfig('area', 'Area', required: true),
        const AdminFieldConfig('is_active', 'Status', options: ['true', 'false'], optionLabels: {'true': 'Active', 'false': 'Inactive'}, defaultValue: 'true', sendAsBoolean: true),
        AdminFieldConfig('assigned_admin_ids', 'Assigned admin', required: true, optionsLoader: loadAdminOptions, initialValue: assignedAdminIdOf, singleSelectAsList: true),
      ],
      detailSections: [
        const AdminDetailSection(
          title: 'Branch',
          fields: [
            AdminDetailField('location_name', 'Location'),
            AdminDetailField('branch_code', 'Branch Code', copyable: true),
            AdminDetailField('state', 'State'),
            AdminDetailField('city', 'City'),
            AdminDetailField('area', 'Area'),
            AdminDetailField('is_active', 'Active', type: AdminDetailFieldType.boolean),
            AdminDetailField('created_at', 'Created At', type: AdminDetailFieldType.date),
          ],
        ),
        const AdminDetailSection(
          title: 'Assignment',
          fields: [AdminDetailField('assigned_admins', 'Assigned Admin')],
        ),
      ],
      customActions: [
        adminPostAction(
          title: 'Toggle Status',
          icon: Icons.toggle_on_outlined,
          endpoint: (record) => '/api/branch/toggle/${record['id']}/',
          action: 'toggle',
          confirmMessage: 'Change this branch active status?',
        ),
      ],
    ),
    'category_requests': AdminModuleConfig(
      key: 'category_requests',
      title: 'Category Requests',
      icon: Icons.pending_actions_outlined,
      // Buyer requests to deal in categories (web "Category Requests"), not the category master.
      listEndpoint: '/api/buyer-categories/',
      titleKeys: const ['buyer'],
      subtitleKeys: const ['status', 'categories', 'request_note', 'requested_at'],
      filterParameter: 'status',
      filterOptions: const ['pending', 'approved', 'rejected'],
      detailSections: [
        const AdminDetailSection(
          title: 'Request',
          fields: [
            AdminDetailField('id', 'Request ID', copyable: true),
            AdminDetailField('status', 'Status', type: AdminDetailFieldType.status),
            AdminDetailField('categories', 'Requested Categories'),
            AdminDetailField('request_note', 'Buyer Note'),
            AdminDetailField('requested_at', 'Requested At', type: AdminDetailFieldType.date),
          ],
        ),
        const AdminDetailSection(
          title: 'Buyer',
          fields: [
            AdminDetailField('buyer.name', 'Name'),
            AdminDetailField('buyer.mobile', 'Mobile', type: AdminDetailFieldType.phone),
          ],
        ),
        const AdminDetailSection(
          title: 'Review',
          fields: [
            AdminDetailField('reviewed_by', 'Reviewed By'),
            AdminDetailField('reviewed_at', 'Reviewed At', type: AdminDetailFieldType.date),
            AdminDetailField('admin_comment', 'Admin Comment'),
          ],
        ),
      ],
      customActions: [
        adminPostAction(
          title: 'Approve',
          icon: Icons.check_circle_outline,
          endpoint: (record) => '/api/buyer-categories/requests/${record['id']}/',
          action: 'approve',
          confirmMessage: 'The buyer will be able to deal in the requested categories.',
          noteKey: 'comment',
          noteLabel: 'Comment',
          isVisible: (record) => recordStatus(record) == 'pending',
        ),
        adminPostAction(
          title: 'Reject',
          icon: Icons.cancel_outlined,
          endpoint: (record) => '/api/buyer-categories/requests/${record['id']}/',
          action: 'reject',
          confirmMessage: 'The buyer will be told the request was rejected.',
          noteKey: 'comment',
          noteLabel: 'Reason',
          destructive: true,
          isVisible: (record) => recordStatus(record) == 'pending',
        ),
      ],
    ),
    'sub_categories': AdminModuleConfig(
      key: 'sub_categories',
      title: 'Sub-Category Master',
      icon: Icons.account_tree_outlined,
      listEndpoint: '/api/categories/',
      titleKeys: const ['category_name'],
      subtitleKeys: const ['parent_name', 'status', 'is_active'],
      detailEndpoint: (id) => '/api/categories/$id/',
      createEndpoint: '/api/categories/',
      updateEndpoint: (id) => '/api/categories/$id/',
      deleteEndpoint: (id) => '/api/categories/$id/',
      fields: const [
        AdminFieldConfig('category_name', 'Sub-category name', required: true),
        AdminFieldConfig('parent', 'Parent category', required: true, optionsLoader: loadParentCategoryOptions),
        AdminFieldConfig('is_active', 'Status', options: ['true', 'false'], optionLabels: {'true': 'Active', 'false': 'Inactive'}, defaultValue: 'true'),
        AdminFieldConfig('image', 'Image', isFile: true),
      ],
      detailSections: [
        const AdminDetailSection(
          title: 'Sub-category',
          fields: [
            AdminDetailField('id', 'ID', copyable: true),
            AdminDetailField('category_name', 'Name'),
            AdminDetailField('parent_name', 'Parent Category'),
            AdminDetailField('full_path', 'Full Path'),
            AdminDetailField('status', 'Status', type: AdminDetailFieldType.status),
            AdminDetailField('is_active', 'Active', type: AdminDetailFieldType.boolean),
            AdminDetailField('image_url', 'Image', type: AdminDetailFieldType.image),
            AdminDetailField('created_at', 'Created At', type: AdminDetailFieldType.date),
          ],
        ),
      ],
      clientFilter: (item) => item['parent'] != null,
    ),
    'categories': AdminModuleConfig(
      key: 'categories',
      title: 'Category Master',
      icon: Icons.category_outlined,
      listEndpoint: '/api/categories/',
      titleKeys: const ['name', 'category_name'],
      subtitleKeys: const ['parent_name', 'level', 'is_active'],
      detailEndpoint: (id) => '/api/categories/$id/',
      createEndpoint: '/api/categories/',
      updateEndpoint: (id) => '/api/categories/$id/',
      deleteEndpoint: (id) => '/api/categories/$id/',
      fields: const [
        AdminFieldConfig('name', 'Category name', required: true),
        AdminFieldConfig('description', 'Description', multiline: true),
      ],
      detailSections: [
        const AdminDetailSection(
          title: 'Category Information',
          fields: [
            AdminDetailField('id', 'Category ID', copyable: true),
            AdminDetailField('name', 'Name'),
            AdminDetailField('description', 'Description'),
            AdminDetailField('level', 'Level'),
            AdminDetailField('parent_name', 'Parent Category'),
            AdminDetailField('is_active', 'Active Status', type: AdminDetailFieldType.boolean),
            AdminDetailField('status', 'Status', type: AdminDetailFieldType.status),
          ],
        ),
        const AdminDetailSection(
          title: 'Media',
          fields: [
            AdminDetailField('image_url', 'Category Image', type: AdminDetailFieldType.image),
          ],
        ),
        const AdminDetailSection(
          title: 'Metadata',
          fields: [
            AdminDetailField('created_at', 'Created At', type: AdminDetailFieldType.date),
            AdminDetailField('updated_at', 'Updated At', type: AdminDetailFieldType.date),
          ],
        ),
      ],
    ),
    'brands': AdminModuleConfig(
      key: 'brands',
      title: 'Brand Master',
      icon: Icons.branding_watermark_outlined,
      listEndpoint: '/api/brands/',
      titleKeys: const ['brand_name', 'name'],
      subtitleKeys: const ['status', 'created_by_name', 'created_at'],
      detailEndpoint: (id) => '/api/brands/$id/',
      filterParameter: 'status',
      filterOptions: const ['pending', 'active', 'inactive', 'rejected'],
      createEndpoint: '/api/brands/',
      updateEndpoint: (id) => '/api/brands/$id/',
      deleteEndpoint: (id) => '/api/brands/$id/',
      fields: const [
        AdminFieldConfig('brand_name', 'Brand name', required: true),
        AdminFieldConfig(
          'status',
          'Status',
          required: true,
          options: ['active', 'pending', 'inactive', 'rejected'],
          optionLabels: {'active': 'Active', 'pending': 'Pending', 'inactive': 'Inactive', 'rejected': 'Rejected'},
          defaultValue: 'active',
        ),
        AdminFieldConfig('category_ids', 'Categories', multiSelect: true, optionsLoader: loadCategoryOptions),
      ],
      detailSections: [
        const AdminDetailSection(
          title: 'Brand Information',
          fields: [
            AdminDetailField('id', 'Brand ID', copyable: true),
            AdminDetailField('brand_name', 'Brand Name'),
            AdminDetailField('status', 'Status', type: AdminDetailFieldType.status),
            AdminDetailField('product_count', 'Offers Using It'),
            AdminDetailField('created_by_name', 'Created By'),
            AdminDetailField('created_at', 'Created At', type: AdminDetailFieldType.date),
          ],
        ),
      ],
      customActions: [
        AdminCustomAction(
          title: 'Approve',
          icon: Icons.check_circle_outline,
          isVisible: (record) => recordStatus(record) == 'pending',
          onPressed: (context, record) => adminConfirmAndRun(
            context,
            title: 'Approve Brand',
            message: 'Make "${record['brand_name']}" active so sellers can use it.',
            confirmText: 'Approve',
            request: (_) => ApiClient.patch(endpoint: '/api/brands/${record['id']}/', data: const {'status': 'active'}, requireAuth: true),
          ),
        ),
      ],
    ),
    'tags': AdminModuleConfig(
      key: 'tags',
      title: 'Tag Master',
      icon: Icons.sell_outlined,
      listEndpoint: '/api/tags/',
      titleKeys: const ['tag_name', 'name'],
      subtitleKeys: const ['is_active', 'created_at'],
      createEndpoint: '/api/tags/',
      updateEndpoint: (id) => '/api/tags/$id/',
      deleteEndpoint: (id) => '/api/tags/$id/',
      fields: const [
        AdminFieldConfig('tag_name', 'Tag name', required: true),
        AdminFieldConfig('is_active', 'Active Status', options: ['true', 'false'], defaultValue: 'true'),
      ],
      detailSections: [
        const AdminDetailSection(
          title: 'Tag Information',
          fields: [
            AdminDetailField('id', 'Tag ID', copyable: true),
            AdminDetailField('tag_name', 'Tag Name'),
            AdminDetailField('is_active', 'Active Status', type: AdminDetailFieldType.boolean),
          ],
        ),
        const AdminDetailSection(
          title: 'Usage Metrics',
          fields: [
            AdminDetailField('assigned_users_count', 'Assigned Users Count'),
          ],
        ),
        const AdminDetailSection(
          title: 'Metadata',
          fields: [
            AdminDetailField('created_at', 'Created At', type: AdminDetailFieldType.date),
          ],
        ),
      ],
    ),
    'drivers': AdminModuleConfig(
      key: 'drivers',
      title: 'Registered Drivers',
      icon: Icons.person_pin_circle_outlined,
      listEndpoint: '/api/drivers/',
      titleKeys: const ['name', 'driver_name', 'mobile'],
      subtitleKeys: const [
        'phone_number',
        'license_number',
        'assignment_status_display',
        'status_display',
      ],
      detailEndpoint: (id) => '/api/drivers/$id/',
      filterParameter: 'status',
      filterOptions: const ['active', 'inactive'],
      createEndpoint: '/api/drivers/',
      updateEndpoint: (id) => '/api/drivers/$id/',
      deleteEndpoint: (id) => '/api/drivers/$id/',
      fields: const [
        AdminFieldConfig('transporter_id', 'Transporter', required: true, optionsLoader: loadTransporterOptions, initialValue: transporterIdOf),
        AdminFieldConfig('driver_name', 'Driver name', required: true),
        AdminFieldConfig('phone_number', 'Phone number', required: true, numeric: true,),
        AdminFieldConfig('email', 'Email'),
        AdminFieldConfig('license_number', 'License number', required: true),
        AdminFieldConfig('license_expiry', 'License expiry', isDate: true),
        AdminFieldConfig('experience', 'Experience', numeric: true),
        AdminFieldConfig('address', 'Address', multiline: true),
        AdminFieldConfig('status', 'Status', options: ['active', 'inactive'], optionLabels: {'active': 'Active', 'inactive': 'Inactive'}, defaultValue: 'active'),
      ],
      detailSections: [
        const AdminDetailSection(
          title: 'Driver Information',
          fields: [
            AdminDetailField('id', 'Driver ID', copyable: true),
            AdminDetailField('driver_name', 'Driver Name'),
            AdminDetailField('phone_number', 'Phone Number', type: AdminDetailFieldType.phone),
            AdminDetailField('email', 'Email Address', type: AdminDetailFieldType.email),
            AdminDetailField('experience', 'Experience (Years)'),
            AdminDetailField('address', 'Address'),
            AdminDetailField('status_display', 'Status', type: AdminDetailFieldType.status),
          ],
        ),
        const AdminDetailSection(
          title: 'License Information',
          fields: [
            AdminDetailField('license_number', 'License Number', copyable: true),
            AdminDetailField('license_expiry', 'License Expiry', type: AdminDetailFieldType.date),
            AdminDetailField('license_upload_url', 'License Document', type: AdminDetailFieldType.image),
          ],
        ),
        const AdminDetailSection(
          title: 'Transporter Information',
          fields: [
            AdminDetailField('transporter.id', 'Transporter ID', copyable: true),
            AdminDetailField('transporter.username', 'Transporter Name'),
            AdminDetailField('transporter.mobile', 'Transporter Mobile', type: AdminDetailFieldType.phone),
          ],
        ),
        const AdminDetailSection(
          title: 'Assignment Information',
          fields: [
            AdminDetailField('assignment_status_display', 'Assignment Status', type: AdminDetailFieldType.status),
            AdminDetailField('assigned_vehicle.vehicle_number', 'Assigned Vehicle Number'),
            AdminDetailField('assigned_vehicle.vehicle_status_display', 'Vehicle Status', type: AdminDetailFieldType.status),
          ],
        ),
        const AdminDetailSection(
          title: 'Metadata',
          fields: [
            AdminDetailField('created_at', 'Created At', type: AdminDetailFieldType.date),
            AdminDetailField('updated_at', 'Updated At', type: AdminDetailFieldType.date),
          ],
        ),
      ],
      customActions: [
        AdminCustomAction(
          title: 'Assign Vehicle',
          icon: Icons.local_shipping_outlined,
          isVisible: (record) => record['assigned_vehicle'] == null,
          onPressed: (context, record) async {
            final result = await showModalBottomSheet<bool>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => AssignVehicleDialog(
                driverId: record['id'].toString(),
                driverName: (record['driver_name'] ?? 'Driver').toString(),
              ),
            );
            return result == true;
          },
        ),
      ],
    ),
    'vehicles': AdminModuleConfig(
      key: 'vehicles',
      title: 'Registered Vehicles',
      icon: Icons.local_shipping_outlined,
      listEndpoint: '/api/vehicles/',
      titleKeys: const ['vehicle_number', 'registration_number', 'name'],
      subtitleKeys: const ['vehicle_status_display', 'vehicle_type', 'load_capacity_tons', 'driver_name', 'transporter'],
      detailEndpoint: (id) => '/api/vehicles/$id/',
      filterParameter: 'vehicle_status',
      filterOptions: const ['available', 'busy', 'maintenance', 'inactive'],
      createEndpoint: '/api/vehicles/',
      updateEndpoint: (id) => '/api/vehicles/$id/',
      deleteEndpoint: (id) => '/api/vehicles/$id/',
      // Same fields and choices as the web "Register Vehicle" form; dropdown values are the backend choices.
      fields: const [
        AdminFieldConfig('transporter_id', 'Transporter', required: true, optionsLoader: loadTransporterOptions, initialValue: transporterIdOf),
        AdminFieldConfig('vehicle_number', 'Vehicle number (e.g. MH31AB1234)', required: true),
        AdminFieldConfig('vehicle_type', 'Vehicle type (e.g. Truck)', required: true),
        AdminFieldConfig('vehicle_brand', 'Brand', required: true, options: ['tata', 'mahindra', 'ashok_leyland', 'eicher', 'bharatbenz', 'isuzu', 'other'],
            optionLabels: {'tata': 'Tata', 'mahindra': 'Mahindra', 'ashok_leyland': 'Ashok Leyland', 'eicher': 'Eicher', 'bharatbenz': 'BharatBenz', 'isuzu': 'Isuzu', 'other': 'Other'}),
        AdminFieldConfig('vehicle_brand_other', 'Brand name (when Brand is Other)'),
        AdminFieldConfig('model_name', 'Model name'),
        AdminFieldConfig('manufacturing_year', 'Manufacturing year', required: true, numeric: true),
        AdminFieldConfig('fuel_type', 'Fuel type', required: true, options: ['diesel', 'petrol', 'cng', 'electric'],
            optionLabels: {'diesel': 'Diesel', 'petrol': 'Petrol', 'cng': 'CNG', 'electric': 'Electric'}),
        AdminFieldConfig('load_capacity_tons', 'Capacity (tons)', required: true),
        AdminFieldConfig('body_type', 'Body type', required: true,
            options: ['open_body', 'closed_body', 'container', 'flatbed', 'refrigerated', 'tanker', 'other'],
            optionLabels: {'open_body': 'Open Body', 'closed_body': 'Closed Body', 'container': 'Container', 'flatbed': 'Flatbed', 'refrigerated': 'Refrigerated', 'tanker': 'Tanker', 'other': 'Other'}),
        AdminFieldConfig('body_type_other', 'Body type name (when Body type is Other)'),
        AdminFieldConfig('number_of_axles', 'Number of axles', required: true, options: ['1', '2', '3', '4', '5', '6']),
        AdminFieldConfig('length_ft', 'Length (ft)'),
        AdminFieldConfig('width_ft', 'Width (ft)'),
        AdminFieldConfig('height_ft', 'Height (ft)'),
        AdminFieldConfig('rc_number', 'RC number'),
        AdminFieldConfig('rc_upload', 'RC document', isFile: true),
        AdminFieldConfig('insurance_number', 'Insurance number'),
        AdminFieldConfig('insurance_expiry_date', 'Insurance expiry', isDate: true),
        AdminFieldConfig('permit_type', 'Permit type', options: ['national_permit', 'state_permit', 'other'],
            optionLabels: {'national_permit': 'National Permit', 'state_permit': 'State Permit', 'other': 'Other'}),
        AdminFieldConfig('permit_type_other', 'Permit name (when Permit type is Other)'),
        AdminFieldConfig('permit_expiry_date', 'Permit expiry', isDate: true),
        AdminFieldConfig('vehicle_status', 'Status', options: ['available', 'busy', 'maintenance', 'inactive'],
            optionLabels: {'available': 'Available', 'busy': 'Busy', 'maintenance': 'Maintenance', 'inactive': 'Inactive'}, defaultValue: 'available'),
      ],
      detailSections: [
        const AdminDetailSection(
          title: 'Vehicle Information',
          fields: [
            AdminDetailField('id', 'Vehicle ID', copyable: true),
            AdminDetailField('vehicle_number', 'Vehicle Number', copyable: true),
            AdminDetailField('vehicle_type', 'Vehicle Type'),
            AdminDetailField('vehicle_brand_display', 'Vehicle Brand'),
            AdminDetailField('model_name', 'Model Name'),
            AdminDetailField('manufacturing_year', 'Manufacturing Year'),
            AdminDetailField('fuel_type', 'Fuel Type'),
            AdminDetailField('load_capacity_tons', 'Load Capacity (Tons)'),
            AdminDetailField('body_type_display', 'Body Type'),
            AdminDetailField('number_of_axles', 'Number of Axles'),
          ],
        ),
        const AdminDetailSection(
          title: 'Registration & Compliance',
          fields: [
            AdminDetailField('rc_number', 'RC Number', copyable: true),
            AdminDetailField('rc_upload_url', 'RC Document', type: AdminDetailFieldType.image),
            AdminDetailField('insurance_number', 'Insurance Number'),
            AdminDetailField('insurance_expiry_date', 'Insurance Expiry', type: AdminDetailFieldType.date),
            AdminDetailField('permit_type_display', 'Permit Type'),
            AdminDetailField('permit_expiry_date', 'Permit Expiry', type: AdminDetailFieldType.date),
          ],
        ),
        const AdminDetailSection(
          title: 'Transporter Information',
          fields: [
            AdminDetailField('transporter.id', 'Transporter ID', copyable: true),
            AdminDetailField('transporter.username', 'Transporter Name'),
            AdminDetailField('transporter.mobile', 'Transporter Mobile', type: AdminDetailFieldType.phone),
          ],
        ),
        const AdminDetailSection(
          title: 'Assignment Information',
          fields: [
            AdminDetailField('vehicle_status_display', 'Vehicle Status', type: AdminDetailFieldType.status),
            AdminDetailField('driver_name', 'Assigned Driver Name'),
            AdminDetailField('driver_phone_number', 'Assigned Driver Phone', type: AdminDetailFieldType.phone),
            AdminDetailField('driver_license_number', 'Driver License'),
          ],
        ),
        const AdminDetailSection(
          title: 'Metadata',
          fields: [
            AdminDetailField('created_at', 'Created At', type: AdminDetailFieldType.date),
            AdminDetailField('updated_at', 'Updated At', type: AdminDetailFieldType.date),
          ],
        ),
      ],
    ),
    'offers': AdminModuleConfig(
      key: 'offers',
      title: 'Offers',
      icon: Icons.local_offer_outlined,
      listEndpoint: '/api/offers/list/',
      titleKeys: const ['title', 'offer_item', 'product_title'],
      subtitleKeys: const ['status', 'amount', 'seller_name', 'category_name'],
      detailEndpoint: (id) => '/api/offers/$id/',
      filterParameter: 'status',
      filterOptions: const [
        'available',
        'interested',
        'buyer_confirmed',
        'seller_confirmed',
        'deal_confirmed',
        'out_of_stock',
      ],
      deleteEndpoint: (id) => '/api/offers/$id/delete/',
      detailSections: [
        const AdminDetailSection(
          title: 'Offer Information',
          fields: [
            AdminDetailField('id', 'Offer ID', copyable: true),
            AdminDetailField('title', 'Offer Title'),
            AdminDetailField('amount', 'Amount'),
            AdminDetailField('quantity', 'Quantity'),
            AdminDetailField('unit', 'Unit'),
            AdminDetailField('status', 'Status', type: AdminDetailFieldType.status),
          ],
        ),
        const AdminDetailSection(
          title: 'Product Details',
          fields: [
            AdminDetailField('product.title', 'Product Name'),
            AdminDetailField('product.category_name', 'Category'),
            AdminDetailField('product.brand_name', 'Brand'),
            AdminDetailField('product.description', 'Description'),
          ],
        ),
        const AdminDetailSection(
          title: 'Seller Information',
          fields: [
            AdminDetailField('seller.username', 'Seller Name'),
            AdminDetailField('seller.mobile', 'Seller Mobile', type: AdminDetailFieldType.phone),
            AdminDetailField('seller_name', 'Seller Name (Fallback)'),
          ],
        ),
        const AdminDetailSection(
          title: 'Buyer Information',
          fields: [
            AdminDetailField('buyer.username', 'Buyer Name'),
            AdminDetailField('buyer.mobile', 'Buyer Mobile', type: AdminDetailFieldType.phone),
          ],
        ),
        const AdminDetailSection(
          title: 'Metadata',
          fields: [
            AdminDetailField('created_at', 'Created At', type: AdminDetailFieldType.date),
            AdminDetailField('updated_at', 'Updated At', type: AdminDetailFieldType.date),
          ],
        ),
      ],
      customActions: [
        AdminCustomAction(
          title: 'View Interests',
          icon: Icons.people_alt_outlined,
          onPressed: (context, record) async {
            final result = await showModalBottomSheet<bool>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => OfferInterestsDialog(
                offerId: record['id'].toString(),
                offerTitle: (record['title'] ?? record['product_title'] ?? 'Offer').toString(),
              ),
            );
            return result == true; // refresh list if true
          },
        ),
      ],
    ),
    'buyer_requirements': AdminModuleConfig(
      key: 'buyer_requirements',
      title: 'Buyer Requirements',
      icon: Icons.request_quote_outlined,
      listEndpoint: '/api/buyer-requirements/',
      idKey: 'rfq_id',
      titleKeys: const ['title', 'rfq_id'],
      subtitleKeys: const ['status', 'buyer_name', 'category', 'required_quantity', 'target_price', 'quotation_count'],
      detailEndpoint: (id) => '/api/buyer-requirements/$id/',
      filterParameter: 'status',
      filterOptions: const ['open', 'negotiation_in_progress', 'fulfilled', 'closed', 'expired'],
      detailSections: [
        const AdminDetailSection(
          title: 'Requirement',
          fields: [
            AdminDetailField('rfq_id', 'RFQ ID', copyable: true),
            AdminDetailField('title', 'Title'),
            AdminDetailField('category', 'Category'),
            AdminDetailField('brand', 'Brand'),
            AdminDetailField('required_quantity', 'Quantity'),
            AdminDetailField('quantity_unit', 'Quantity Unit'),
            AdminDetailField('required_bag_count', 'Bags'),
            AdminDetailField('target_price', 'Target Price'),
            AdminDetailField('price_unit', 'Price Unit'),
            AdminDetailField('delivery_terms', 'Delivery Terms'),
            AdminDetailField('description', 'Description'),
            AdminDetailField('status', 'Status', type: AdminDetailFieldType.status),
            AdminDetailField('expiry_datetime', 'Expires', type: AdminDetailFieldType.date),
          ],
        ),
        const AdminDetailSection(
          title: 'Buyer & Branches',
          fields: [
            AdminDetailField('buyer_name', 'Buyer'),
            AdminDetailField('buyer_remark', 'Buyer Remark'),
            AdminDetailField('target_branches', 'Target Branches'),
          ],
        ),
        const AdminDetailSection(
          title: 'Quotations',
          fields: [
            AdminDetailField('quotation_count', 'Quotations Received'),
            AdminDetailField('created_at', 'Created At', type: AdminDetailFieldType.date),
          ],
        ),
      ],
      customActions: [
        adminPostAction(
          title: 'Close',
          icon: Icons.lock_outline,
          endpoint: (record) => '/api/buyer-requirements/${record['rfq_id']}/',
          action: 'close',
          confirmMessage: 'Sellers will no longer be able to send quotations.',
          destructive: true,
          isVisible: (record) => const ['open', 'negotiation_in_progress'].contains(recordStatus(record)),
        ),
      ],
    ),
    'buyer_offers': AdminModuleConfig(
      key: 'buyer_offers',
      title: 'Buyer Offers',
      icon: Icons.handshake_outlined,
      // Buyer offer requests waiting for the admin (web "Buyer Offers"), not contracts.
      listEndpoint: '/api/buyer-offers/',
      staticQuery: const {'tab': 'approvals'},
      titleKeys: const ['title', 'transaction_id'],
      subtitleKeys: const ['status', 'buyer_name', 'seller_name', 'requested_amount', 'requested_quantity'],
      detailEndpoint: (id) => '/api/buyer-offers/$id/',
      filterParameter: 'status',
      filterOptions: const [
        'requested',
        'negotiating',
        'seller_confirmed',
        'buyer_confirmed',
        'deal_confirmed',
        'rejected',
        'cancelled',
      ],
      detailSections: [
        const AdminDetailSection(
          title: 'Offer',
          fields: [
            AdminDetailField('transaction_id', 'Transaction ID', copyable: true),
            AdminDetailField('title', 'Title'),
            AdminDetailField('category', 'Category'),
            AdminDetailField('brand', 'Brand'),
            AdminDetailField('requested_quantity', 'Requested Quantity'),
            AdminDetailField('quantity_unit', 'Quantity Unit'),
            AdminDetailField('requested_amount', 'Requested Price'),
            AdminDetailField('amount_unit', 'Price Unit'),
            AdminDetailField('requested_bag_count', 'Bags'),
            AdminDetailField('latest_offered_amount', 'Latest Offered Price'),
            AdminDetailField('status', 'Status', type: AdminDetailFieldType.status),
          ],
        ),
        const AdminDetailSection(
          title: 'Parties',
          fields: [
            AdminDetailField('buyer_name', 'Buyer'),
            AdminDetailField('seller_name', 'Seller'),
            AdminDetailField('seller_branch_name', 'Seller Branch'),
            AdminDetailField('target_branches_list', 'Target Branches'),
            AdminDetailField('buyer_remark', 'Buyer Remark'),
            AdminDetailField('seller_remark', 'Seller Remark'),
          ],
        ),
        const AdminDetailSection(
          title: 'Confirmation',
          fields: [
            AdminDetailField('confirmed_by_admin_name', 'Confirmed By'),
            AdminDetailField('confirmed_branch_name', 'Confirmed Branch'),
            AdminDetailField('deal_confirmed_at', 'Confirmed At', type: AdminDetailFieldType.date),
            AdminDetailField('superadmin_remark', 'Admin Remark'),
            AdminDetailField('created_at', 'Created At', type: AdminDetailFieldType.date),
          ],
        ),
      ],
      customActions: [
        AdminCustomAction(
          title: 'Confirm Deal',
          icon: Icons.verified_outlined,
          isVisible: (record) => recordStatus(record) == 'buyer_confirmed',
          onPressed: confirmBuyerOffer,
        ),
      ],
    ),
    'offer_images': AdminModuleConfig(
      key: 'offer_images',
      title: 'Offer Images',
      icon: Icons.image_outlined,
      listEndpoint: '/api/product-images/',
      titleKeys: const ['product_title', 'title', 'id'],
      subtitleKeys: const ['product', 'is_primary', 'created_at'],
      createEndpoint: '/api/product-images/',
      deleteEndpoint: (id) => '/api/product-images/$id/',
      fields: const [
        AdminFieldConfig('product_id', 'Offer', required: true, optionsLoader: loadOfferOptions),
        AdminFieldConfig('image', 'Image', required: true, isFile: true),
      ],
      detailSections: [
        const AdminDetailSection(
          title: 'Media Details',
          fields: [
            AdminDetailField('id', 'Image ID', copyable: true),
            AdminDetailField('product_title', 'Offer'),
            AdminDetailField('product', 'Offer ID'),
            AdminDetailField('is_primary', 'Primary Image', type: AdminDetailFieldType.boolean),
          ],
        ),
        const AdminDetailSection(
          title: 'Preview',
          fields: [
            AdminDetailField('image_url', 'Image', type: AdminDetailFieldType.image),
          ],
        ),
        const AdminDetailSection(
          title: 'Metadata',
          fields: [
            AdminDetailField('created_at', 'Created At', type: AdminDetailFieldType.date),
          ],
        ),
      ],
    ),
    'offer_videos': AdminModuleConfig(
      key: 'offer_videos',
      title: 'Offer Videos',
      icon: Icons.video_library_outlined,
      listEndpoint: '/api/product-videos/',
      titleKeys: const ['product_title', 'title', 'id'],
      subtitleKeys: const ['product', 'created_at'],
      createEndpoint: '/api/product-videos/',
      deleteEndpoint: (id) => '/api/product-videos/$id/',
      fields: const [
        AdminFieldConfig('product_id', 'Offer', required: true, optionsLoader: loadOfferOptions),
        AdminFieldConfig('video', 'Video', required: true, isFile: true),
      ],
      detailSections: [
        const AdminDetailSection(
          title: 'Media Details',
          fields: [
            AdminDetailField('id', 'Video ID', copyable: true),
            AdminDetailField('product_title', 'Offer'),
            AdminDetailField('product', 'Offer ID'),
          ],
        ),
        const AdminDetailSection(
          title: 'Preview',
          fields: [
            AdminDetailField('video_url', 'Video', type: AdminDetailFieldType.video),
          ],
        ),
        const AdminDetailSection(
          title: 'Metadata',
          fields: [
            AdminDetailField('created_at', 'Created At', type: AdminDetailFieldType.date),
          ],
        ),
      ],
    ),
  };

  static AdminModuleConfig byKey(String key) => all[key]!;
}
