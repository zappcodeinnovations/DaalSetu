import 'package:daalsetu/modules/admin_catalog/config/admin_actions.dart';
import 'package:daalsetu/modules/admin_catalog/config/admin_module_config.dart';
import 'package:daalsetu/modules/admin_catalog/view/admin_record_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<List<AdminOption>> _drivers() async => const [
      AdminOption('7', 'Prem (7585859594)', extras: {'phone': '7585859594', 'license': 'MH12202612453'}),
      AdminOption('8', 'Amit (9000000001)', extras: {'phone': '9000000001', 'license': 'MH14201111111'}),
    ];

void main() {
  test('the vehicle form has the driver phone and licence fields, filled from the chosen driver', () {
    final fields = {for (final f in AdminModules.byKey('vehicles').fields) f.key: f};
    expect(fields['assigned_driver_id'], isNotNull);
    expect(fields['driver_phone_number']!.derivedFrom, 'assigned_driver_id');
    expect(fields['driver_license_number']!.derivedFrom, 'assigned_driver_id');
  });

  testWidgets('picking a driver fills Driver Phone Number and Driver License Number, and they are not sent', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final config = AdminModuleConfig(
      key: 'vehicles_demo',
      title: 'Vehicles',
      icon: Icons.local_shipping_outlined,
      listEndpoint: '/api/vehicles/',
      titleKeys: const ['vehicle_number'],
      createEndpoint: '/api/vehicles/',
      fields: [
        const AdminFieldConfig('vehicle_number', 'Vehicle number'),
        AdminFieldConfig('assigned_driver_id', 'Assign driver', optionsLoader: _drivers),
        const AdminFieldConfig('driver_phone_number', 'Driver phone number', derivedFrom: 'assigned_driver_id', derivedKey: 'phone'),
        const AdminFieldConfig('driver_license_number', 'Driver license number', derivedFrom: 'assigned_driver_id', derivedKey: 'license'),
      ],
    );

    await tester.pumpWidget(MaterialApp(home: AdminRecordFormScreen(config: config)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Assign driver'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Prem (7585859594)').last);
    await tester.pumpAndSettle();

    expect(find.text('7585859594'), findsOneWidget);
    expect(find.text('MH12202612453'), findsOneWidget);
  });
}
