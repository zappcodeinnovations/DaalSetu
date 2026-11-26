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
    // The server takes the Driver profile id (driver_profile_id); assigned_driver_id was a user id ("Invalid pk").
    expect(fields['assigned_driver_id'], isNull);
    expect(fields['driver_profile_id']!.dependsOn, 'transporter_id');
    expect(fields['driver_profile_id']!.sendEmptyAsNull, isTrue);
    expect(fields['driver_phone_number']!.derivedFrom, 'driver_profile_id');
    expect(fields['driver_license_number']!.derivedFrom, 'driver_profile_id');
    expect(assignedDriverIdOf({'assigned_driver_profile_id': 12, 'assigned_driver': 55}), 12);
  });

  testWidgets('the driver list follows the chosen transporter and is cleared when it changes', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final asked = <String>[];
    Future<List<AdminOption>> transporters() async => const [
          AdminOption('1', 'Fast Movers'),
          AdminOption('2', 'Road Kings'),
        ];
    Future<List<AdminOption>> driversOf(String transporter, String? vehicle) async {
      asked.add(transporter);
      if (transporter == '1') return const [AdminOption('7', 'Prem (7585859594)')];
      if (transporter == '2') return const [AdminOption('9', 'Ravi (9000000009)')];
      return const [];
    }

    final config = AdminModuleConfig(
      key: 'vehicles_demo',
      title: 'Vehicles',
      icon: Icons.local_shipping_outlined,
      listEndpoint: '/api/vehicles/',
      titleKeys: const ['vehicle_number'],
      createEndpoint: '/api/vehicles/',
      fields: [
        AdminFieldConfig('transporter_id', 'Transporter', optionsLoader: transporters),
        AdminFieldConfig('driver_profile_id', 'Assign driver', dependsOn: 'transporter_id', dependentOptionsLoader: driversOf),
      ],
    );

    await tester.pumpWidget(MaterialApp(home: AdminRecordFormScreen(config: config)));
    await tester.pumpAndSettle();
    expect(find.text('Select the Transporter first.'), findsOneWidget);

    await tester.tap(find.text('Transporter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fast Movers').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Assign driver'));
    await tester.pumpAndSettle();
    expect(find.text('Prem (7585859594)'), findsWidgets);
    expect(find.text('Ravi (9000000009)'), findsNothing);
    await tester.tap(find.text('Prem (7585859594)').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Fast Movers'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Road Kings').last);
    await tester.pumpAndSettle();
    // The other transporter's driver is no longer selected.
    expect(find.text('Prem (7585859594)'), findsNothing);
    expect(asked, ['', '1', '2']);
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
