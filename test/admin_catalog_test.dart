import 'package:daalsetu/modules/admin_catalog/config/admin_actions.dart';
import 'package:daalsetu/modules/admin_catalog/config/admin_module_config.dart';
import 'package:daalsetu/modules/admin_catalog/model/admin_record.dart';
import 'package:daalsetu/modules/admin_catalog/repository/drawer_menu_service.dart';
import 'package:daalsetu/modules/admin_catalog/view/admin_record_form_screen.dart';
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

  for (final key in ['vehicles', 'brands', 'sub_categories', 'offer_images', 'drivers']) {
    testWidgets('$key form renders', (tester) async {
      await tester.pumpWidget(MaterialApp(home: AdminRecordFormScreen(config: AdminModules.byKey(key))));
      await tester.pump();
      expect(find.textContaining('Create'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }

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
