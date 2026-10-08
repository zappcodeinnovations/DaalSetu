import 'package:daalsetu/modules/admin_catalog/config/admin_actions.dart';
import 'package:daalsetu/modules/admin_catalog/config/admin_module_config.dart';
import 'package:daalsetu/modules/admin_catalog/model/admin_record.dart';
import 'package:daalsetu/modules/admin_catalog/repository/drawer_menu_service.dart';
import 'package:daalsetu/modules/admin_catalog/view/admin_contract_history_screen.dart';
import 'package:daalsetu/modules/admin_catalog/view/admin_record_form_screen.dart';
import 'package:daalsetu/modules/seller/challans/model/seller_challan_model.dart';
import 'package:daalsetu/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('every admin module config builds', () {
    expect(AdminModules.all.keys, containsAll(['category_requests', 'sub_categories', 'buyer_offers', 'brands']));
    expect(AdminModules.byKey('buyer_offers').listEndpoint, '/api/buyer-offers/');
    expect(AdminModules.byKey('category_requests').listEndpoint, '/api/buyer-categories/');
    expect(AdminModules.byKey('brands').canCreate, isTrue);
    expect(AdminModules.byKey('offer_images').canCreate, isTrue);
  });

  test('vehicle choices match the backend', () {
    final fields = {for (final f in AdminModules.byKey('vehicles').fields) f.key: f};
    expect(fields['vehicle_status']!.options, ['available', 'busy', 'maintenance', 'inactive']);
    expect(fields['vehicle_brand']!.options, contains('bharatbenz'));
    expect(fields['transporter_id']!.optionsLoader, isNotNull);
    expect(AdminModules.byKey('vehicles').filterOptions, isNot(contains('assigned')));
  });

  test('buyer requirements use rfq_id in item URLs', () {
    final config = AdminModules.byKey('buyer_requirements');
    const record = AdminRecord({'id': 7, 'rfq_id': 'RFQ-20261008-9951'});
    expect(config.recordId(record), 'RFQ-20261008-9951');
    expect(config.detailEndpoint!(config.recordId(record)), '/api/buyer-requirements/RFQ-20261008-9951/');
  });

  test('display values read nested API objects', () {
    expect(adminDisplayValue({'id': 3, 'name': 'parity-buyer', 'mobile': '9400000003'}), 'parity-buyer');
    expect(adminDisplayValue([{'id': 1, 'category_name': 'Toor Daal'}, {'id': 2, 'category_name': 'Moong'}]), 'Toor Daal, Moong');
    expect(adminDisplayValue(null), '');
  });

  test('approve / reject only show for pending category requests', () {
    final actions = AdminModules.byKey('category_requests').customActions;
    expect(actions.map((a) => a.title), ['Approve', 'Reject']);
    expect(actions.first.isVisible!({'status': 'pending'}), isTrue);
    expect(actions.first.isVisible!({'status': 'approved'}), isFalse);
  });

  test('branch request config uses review APIs and pending-only actions', () {
    final config = AdminModules.byKey('branch_requests');
    expect(config.listEndpoint, '/api/admin/branch-requests/');
    expect(config.filterOptions, ['pending', 'approved', 'rejected']);
    expect(config.customActions.map((action) => action.title), ['Approve', 'Reject']);
    expect(config.customActions.first.isVisible!({'status': 'pending'}), isTrue);
    expect(config.customActions.first.isVisible!({'status': 'approved'}), isFalse);
  });

  test('branch master sends exactly one admin using web-compatible endpoints', () {
    final config = AdminModules.byKey('branches');
    final fields = {for (final field in config.fields) field.key: field};
    expect(config.createEndpoint, '/api/branch/create/');
    expect(config.updateEndpoint!('12'), '/api/branch/update/12/');
    expect(config.deleteEndpoint!('12'), '/api/branch/delete/12/');
    expect(config.updateMethod, AdminRequestMethod.post);
    expect(fields['assigned_admin_ids']!.required, isTrue);
    expect(fields['assigned_admin_ids']!.singleSelectAsList, isTrue);
    expect(fields['assigned_admin_ids']!.optionsLoader, isNotNull);
    expect(fields['is_active']!.sendAsBoolean, isTrue);
  });

  test('branch drawer permissions match backend access rules', () async {
    final sections = await DrawerMenuService().fetchMenu();
    final branchSection = sections.singleWhere((section) => section.sectionTitle == 'BRANCHES');
    final items = {for (final item in branchSection.items) item.key: item};
    expect(items['branch_requests']!.isVisibleFor('admin'), isTrue);
    expect(items['branch_requests']!.isVisibleFor('sub_admin'), isFalse);
    expect(items['branches']!.isVisibleFor('admin'), isFalse);
    expect(items['branches']!.isVisibleFor('super_admin'), isTrue);
    expect(items['branch_settings']!.route, AppRoutes.adminBranchSettings);
  });

  test('consignments use workflow APIs and server action permissions', () {
    final config = AdminModules.byKey('consignments');
    expect(config.listEndpoint, '/api/consignments/');
    expect(config.detailEndpoint!('31'), '/api/consignments/31/');
    expect(config.filterParameter, 'workflow_status');
    expect(config.filterOptions, ['pending', 'ready', 'dispatch', 'received']);
    expect(config.customActions.map((action) => action.title), ['View Bids', 'Ready for Loading', 'Mark Received']);
    expect(config.customActions[1].isVisible!({'can_mark_ready': true}), isTrue);
    expect(config.customActions[1].isVisible!({'can_mark_ready': false}), isFalse);
    expect(config.customActions[2].isVisible!({'can_mark_received': true}), isTrue);
  });

  test('deals drawer exposes consignments and contract history', () async {
    final sections = await DrawerMenuService().fetchMenu();
    final deals = sections.singleWhere((section) => section.sectionTitle == 'DEALS');
    final items = {for (final item in deals.items) item.key: item};
    expect(items['consignments']!.route, AppRoutes.adminModule('consignments'));
    expect(items['contract_history']!.route, AppRoutes.adminContractHistory);
  });

  test('accounting drawer and billing company module use brokerage APIs', () async {
    final config = AdminModules.byKey('billing_companies');
    expect(config.listEndpoint, '/api/admin/billing-companies/');
    expect(config.createEndpoint, '/api/admin/billing-companies/');
    expect(config.updateEndpoint!('9'), '/api/admin/billing-companies/9/');
    expect(config.deleteEndpoint!('9'), '/api/admin/billing-companies/9/');
    final fields = {for (final field in config.fields) field.key: field};
    expect(fields['company_id']!.createOnly, isTrue);
    expect(fields['company_id']!.optionsLoader, isNotNull);
    expect(fields['logo']!.isFile, isTrue);
    expect(fields['authorized_signature']!.isFile, isTrue);

    final sections = await DrawerMenuService().fetchMenu();
    final accounting = sections.singleWhere((section) => section.sectionTitle == 'ACCOUNTING');
    final items = {for (final item in accounting.items) item.key: item};
    expect(items['brokerage_bills']!.route, AppRoutes.adminBrokerageBills);
    expect(items['brokerage_bills']!.isVisibleFor('admin'), isTrue);
    expect(items['brokerage_bills']!.isVisibleFor('sub_admin'), isFalse);
    expect(items['billing_companies']!.isVisibleFor('super_admin'), isTrue);
  });

  test('seller challan retains the complete item summary from the API', () {
    final challan = SellerChallanModel.fromJson({
      'id': 42,
      'challan_number': 'DC-42',
      'company': {'legal_name': 'DaalSetu Foods'},
      'items': [
        {'product_name': 'Toor Dal', 'bag_count': 10},
        {'product_name': 'Moong Dal', 'bag_count': 15},
      ],
    });
    expect(challan.companyName, 'DaalSetu Foods');
    expect(challan.totalBags, 25);
    expect(challan.itemSummary, 'Toor Dal, Moong Dal');
    expect(challan.raw['challan_number'], 'DC-42');
  });

  test('settings modules expose policy pages and role-aware navigation', () async {
    final policy = AdminModules.byKey('policy_sections');
    final fields = {for (final field in policy.fields) field.key: field};
    expect(policy.listEndpoint, '/api/admin/policy-sections/');
    expect(policy.updateEndpoint!('4'), '/api/admin/policy-sections/4/');
    expect(policy.filterOptions, containsAll(['privacy_policy', 'terms_conditions', 'disclaimer', 'refund_policy']));
    expect(fields['content']!.multiline, isTrue);
    expect(fields['is_active']!.sendAsBoolean, isTrue);

    final sections = await DrawerMenuService().fetchMenu();
    final settings = sections.singleWhere((section) => section.sectionTitle == 'SETTINGS');
    final items = {for (final item in settings.items) item.key: item};
    expect(items['sub_admins']!.route, AppRoutes.adminModule('salesman'));
    expect(items['roles']!.route, AppRoutes.adminRoles);
    expect(items['permissions_matrix']!.route, AppRoutes.adminPermissionsMatrix);
    expect(items['permissions_matrix']!.isVisibleFor('super_admin'), isTrue);
    expect(items['permissions_matrix']!.isVisibleFor('admin'), isFalse);
    expect(items['policy_sections']!.isVisibleFor('admin'), isTrue);
  });

  for (final key in ['vehicles', 'brands', 'sub_categories', 'offer_images', 'drivers']) {
    testWidgets('$key form renders', (tester) async {
      await tester.pumpWidget(MaterialApp(home: AdminRecordFormScreen(config: AdminModules.byKey(key))));
      await tester.pump();
      expect(find.textContaining('Create'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('contract history screen renders its loading state', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AdminContractHistoryScreen()));
    await tester.pump();
    expect(find.text('Contract History'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('editing a vehicle keeps its backend values', (tester) async {
    const record = AdminRecord({
      'id': 1,
      'transporter': {'id': 4, 'username': 'parity-transporter'},
      'vehicle_number': 'MH31AB4321',
      'vehicle_brand': 'bharatbenz',
      'vehicle_status': 'busy',
      'number_of_axles': 2,
    });
    await tester.pumpWidget(MaterialApp(home: AdminRecordFormScreen(config: AdminModules.byKey('vehicles'), record: record)));
    await tester.pump();
    expect(find.text('MH31AB4321'), findsOneWidget);
    expect(find.text('BharatBenz'), findsOneWidget);
    expect(find.text('Busy'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
