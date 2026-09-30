import 'package:flutter/material.dart';
import 'package:daalsetu/modules/admin_catalog/view/assign_vehicle_dialog.dart';
import 'package:daalsetu/modules/admin_catalog/view/offer_interests_dialog.dart';
import 'package:daalsetu/modules/admin_catalog/config/admin_detail_config.dart';

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

  bool get canCreate => createEndpoint != null && fields.isNotEmpty;
  bool get canEdit => updateEndpoint != null && fields.isNotEmpty;
  bool get canDelete => deleteEndpoint != null;
}

class AdminModules {
  AdminModules._();

  static const userFields = [
    AdminFieldConfig('username', 'Name', required: true),
    AdminFieldConfig('mobile', 'Mobile number', required: true, numeric: true),
    AdminFieldConfig('email', 'Email'),
    AdminFieldConfig(
      'role',
      'Role',
      required: true,
      options: ['buyer', 'seller', 'transporter', 'salesman', 'admin'],
    ),
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
    ),
    'salesman': AdminModuleConfig(
      key: 'salesman',
      title: 'Salesman',
      icon: Icons.support_agent_outlined,
      listEndpoint: '/api/users/',
      staticQuery: const {'role': 'salesman'},
      titleKeys: const ['username', 'name', 'mobile'],
      subtitleKeys: const ['mobile', 'email', 'is_active'],
      detailEndpoint: (id) => '/api/users/$id/',
      createEndpoint: '/api/users/create/',
      updateEndpoint: (id) => '/api/users/$id/update/',
      deleteEndpoint: (id) => '/api/users/$id/delete/',
      fields: const [
        AdminFieldConfig('username', 'Name', required: true),
        AdminFieldConfig('mobile', 'Mobile number', required: true, numeric: true),
        AdminFieldConfig('email', 'Email'),
        AdminFieldConfig('role', 'Role', hiddenValue: 'salesman'),
      ],
      detailSections: userDetailSections,
      clientFilter: (item) =>
          (item['role'] ?? '').toString().toLowerCase() == 'salesman',
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
    ),
    'category_requests': AdminModuleConfig(
      key: 'category_requests',
      title: 'Category Requests',
      icon: Icons.pending_actions_outlined,
      listEndpoint: '/api/categories/',
      titleKeys: const ['name', 'category_name'],
      subtitleKeys: const ['status', 'requested_by', 'created_at'],
      detailEndpoint: (id) => '/api/categories/$id/',
      detailSections: [
        const AdminDetailSection(
          title: 'Request Information',
          fields: [
            AdminDetailField('id', 'Request ID', copyable: true),
            AdminDetailField('name', 'Category Name'),
            AdminDetailField('description', 'Description'),
            AdminDetailField('status', 'Request Status', type: AdminDetailFieldType.status),
            AdminDetailField('is_approved', 'Approved', type: AdminDetailFieldType.boolean),
          ],
        ),
        const AdminDetailSection(
          title: 'Requested By',
          fields: [
            AdminDetailField('requested_by.username', 'Name'),
            AdminDetailField('requested_by.mobile', 'Mobile', type: AdminDetailFieldType.phone),
            AdminDetailField('requested_by.role', 'Role'),
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
      clientFilter: (item) {
        final status = (item['status'] ?? '').toString().toLowerCase();
        return item['is_approved'] == false ||
            status == 'pending' ||
            status == 'requested';
      },
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
      listEndpoint: '/api/brands/dashboard/',
      titleKeys: const ['brand_name', 'name'],
      subtitleKeys: const ['category_name', 'is_active'],
      detailSections: [
        const AdminDetailSection(
          title: 'Brand Information',
          fields: [
            AdminDetailField('id', 'Brand ID', copyable: true),
            AdminDetailField('brand_name', 'Brand Name'),
            AdminDetailField('category_name', 'Category Name'),
            AdminDetailField('is_active', 'Active Status', type: AdminDetailFieldType.boolean),
          ],
        ),
        const AdminDetailSection(
          title: 'Media',
          fields: [
            AdminDetailField('image', 'Brand Image', type: AdminDetailFieldType.image),
          ],
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
        AdminFieldConfig('transporter_id', 'Transporter ID', required: true, numeric: true,),
        AdminFieldConfig('driver_name', 'Driver name', required: true),
        AdminFieldConfig('phone_number', 'Phone number', required: true, numeric: true,),
        AdminFieldConfig('email', 'Email'),
        AdminFieldConfig('license_number', 'License number', required: true),
        AdminFieldConfig('license_expiry', 'License expiry (YYYY-MM-DD)', isDate: true),
        AdminFieldConfig('experience', 'Experience', numeric: true),
        AdminFieldConfig('address', 'Address', multiline: true),
        AdminFieldConfig('status', 'Status', options: ['active', 'inactive'], defaultValue: 'active',),
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
      subtitleKeys: const ['vehicle_type', 'capacity', 'driver_name'],
      detailEndpoint: (id) => '/api/vehicles/$id/',
      filterParameter: 'vehicle_status',
      filterOptions: const ['available', 'assigned', 'maintenance', 'inactive'],
      createEndpoint: '/api/vehicles/',
      updateEndpoint: (id) => '/api/vehicles/$id/',
      deleteEndpoint: (id) => '/api/vehicles/$id/',
      fields: const [
        AdminFieldConfig('transporter_id', 'Transporter ID', required: true, numeric: true,),
        AdminFieldConfig('vehicle_number', 'Vehicle number', required: true),
        AdminFieldConfig('vehicle_type', 'Vehicle type', required: true),
        AdminFieldConfig('vehicle_brand', 'Vehicle brand'),
        AdminFieldConfig('model_name', 'Model name'),
        AdminFieldConfig('manufacturing_year', 'Manufacturing year', numeric: true,),
        AdminFieldConfig('fuel_type', 'Fuel type', options: ['diesel', 'petrol', 'cng', 'electric'],),
        AdminFieldConfig('load_capacity_tons', 'Capacity (tons)'),
        AdminFieldConfig('body_type', 'Body type'),
        AdminFieldConfig('number_of_axles', 'Number of axles', numeric: true),
        AdminFieldConfig('rc_number', 'RC number'),
        AdminFieldConfig('insurance_number', 'Insurance number'),
        AdminFieldConfig('insurance_expiry_date', 'Insurance expiry (YYYY-MM-DD)', isDate: true),
        AdminFieldConfig('permit_type', 'Permit type'),
        AdminFieldConfig('permit_expiry_date', 'Permit expiry (YYYY-MM-DD)', isDate: true),
        AdminFieldConfig('vehicle_status', 'Status', options: ['available', 'assigned', 'maintenance', 'inactive'], defaultValue: 'available',),
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
      listEndpoint: '/api/rfqs/',
      titleKeys: const ['title', 'commodity', 'product_name', 'rfq_id'],
      subtitleKeys: const ['status', 'quantity', 'buyer_name', 'created_at'],
      detailEndpoint: (id) => '/api/rfqs/$id/',
      filterParameter: 'status',
      filterOptions: const ['open', 'quoted', 'accepted', 'closed'],
      detailSections: [
        const AdminDetailSection(
          title: 'Requirement Information',
          fields: [
            AdminDetailField('rfq_id', 'RFQ ID', copyable: true),
            AdminDetailField('id', 'Database ID', copyable: true),
            AdminDetailField('title', 'Title'),
            AdminDetailField('commodity', 'Commodity'),
            AdminDetailField('product_name', 'Product Name'),
            AdminDetailField('quantity', 'Quantity Requested'),
            AdminDetailField('status', 'Status', type: AdminDetailFieldType.status),
          ],
        ),
        const AdminDetailSection(
          title: 'Buyer Information',
          fields: [
            AdminDetailField('buyer_name', 'Buyer Name'),
            AdminDetailField('buyer.username', 'Username'),
            AdminDetailField('buyer.mobile', 'Mobile', type: AdminDetailFieldType.phone),
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
    'buyer_offers': AdminModuleConfig(
      key: 'buyer_offers',
      title: 'Buyer Offers',
      icon: Icons.handshake_outlined,
      listEndpoint: '/api/mobile/contracts/',
      titleKeys: const ['product_title', 'contract_id'],
      subtitleKeys: const [
        'status',
        'display_buyer_id',
        'deal_amount',
        'deal_quantity',
      ],
      detailEndpoint: (id) => '/api/mobile/contracts/$id/',
      filterParameter: 'status',
      filterOptions: const ['active', 'pending', 'completed', 'cancelled'],
      detailSections: [
        const AdminDetailSection(
          title: 'Contract Details',
          fields: [
            AdminDetailField('contract_id', 'Contract ID', copyable: true),
            AdminDetailField('id', 'Database ID', copyable: true),
            AdminDetailField('product_title', 'Product Title'),
            AdminDetailField('deal_amount', 'Deal Amount'),
            AdminDetailField('deal_quantity', 'Deal Quantity'),
            AdminDetailField('status', 'Contract Status', type: AdminDetailFieldType.status),
          ],
        ),
        const AdminDetailSection(
          title: 'Party Information',
          fields: [
            AdminDetailField('display_buyer_id', 'Buyer ID', copyable: true),
            AdminDetailField('buyer_name', 'Buyer Name'),
            AdminDetailField('seller_name', 'Seller Name'),
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
    'offer_images': AdminModuleConfig(
      key: 'offer_images',
      title: 'Offer Images',
      icon: Icons.image_outlined,
      listEndpoint: '/api/product-images/',
      titleKeys: const ['title', 'product_title', 'image_name', 'id'],
      subtitleKeys: const ['product', 'created_at', 'image_url'],
      deleteEndpoint: (id) => '/api/product-images/$id/',
      detailSections: [
        const AdminDetailSection(
          title: 'Media Details',
          fields: [
            AdminDetailField('id', 'Image ID', copyable: true),
            AdminDetailField('title', 'Title'),
            AdminDetailField('product_title', 'Product Title'),
            AdminDetailField('image_name', 'Image Name'),
            AdminDetailField('product', 'Product ID'),
          ],
        ),
        const AdminDetailSection(
          title: 'Preview',
          fields: [
            AdminDetailField('image_url', 'Image URL', type: AdminDetailFieldType.image),
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
      titleKeys: const ['title', 'product_title', 'video_name', 'id'],
      subtitleKeys: const ['product', 'created_at', 'video_url'],
      deleteEndpoint: (id) => '/api/product-videos/$id/',
      detailSections: [
        const AdminDetailSection(
          title: 'Media Details',
          fields: [
            AdminDetailField('id', 'Video ID', copyable: true),
            AdminDetailField('title', 'Title'),
            AdminDetailField('product_title', 'Product Title'),
            AdminDetailField('video_name', 'Video Name'),
            AdminDetailField('product', 'Product ID'),
          ],
        ),
        const AdminDetailSection(
          title: 'Preview',
          fields: [
            AdminDetailField('video_url', 'Video URL', type: AdminDetailFieldType.video),
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
