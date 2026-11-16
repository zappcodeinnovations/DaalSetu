import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:daalsetu/modules/transporter/drivers/view/transporter_drivers_view.dart';
import 'package:daalsetu/modules/transporter/drivers/view/transporter_driver_detail.dart';
import 'package:daalsetu/modules/transporter/drivers/view/transporter_driver_form.dart';
import 'package:daalsetu/modules/transporter/drivers/controller/transporter_driver_controller.dart';
import 'package:daalsetu/modules/transporter/drivers/model/driver_model.dart';
import 'package:daalsetu/widgets/hero_header.dart';

class _OfflineDriverController extends TransporterDriverController {
  @override
  Future<void> fetchDrivers() async {}
}

DriverModel _createMockDriver() {
  return DriverModel(
    id: 1,
    driverName: "Ramesh Kumar",
    phoneNumber: "9876543210",
    email: "ramesh@example.com",
    licenseNumber: "DL1420110012345",
    licenseExpiry: "2030-05-15",
    experience: 5,
    address: "Transport Nagar, Delhi",
    status: "active",
    statusDisplay: "Active",
    assignmentStatus: "unassigned",
    assignmentStatusDisplay: "Unassigned",
  );
}

void main() {
  setUp(() {
    Get.testMode = true;
    FlutterSecureStorage.setMockInitialValues({'user_role': 'transporter'});
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('TransporterDriversView renders HeroHeader, search, filters and register FAB', (tester) async {
    Get.put<TransporterDriverController>(_OfflineDriverController());
    tester.view.physicalSize = const Size(450, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(GetMaterialApp(home: TransporterDriversView()));
    await tester.pump();

    expect(find.byType(HeroHeader), findsOneWidget);
    expect(find.text('My Drivers'), findsOneWidget);
    expect(find.text('Register drivers and assign vehicles'), findsOneWidget);
    expect(find.text('Register Driver'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.textContaining('All'), findsOneWidget);
  });

  testWidgets('TransporterDriverDetail renders HeroHeader with edit action and driver info', (tester) async {
    Get.put<TransporterDriverController>(_OfflineDriverController());
    tester.view.physicalSize = const Size(450, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final driver = _createMockDriver();
    await tester.pumpWidget(GetMaterialApp(home: TransporterDriverDetail(driver: driver)));
    await tester.pump();

    expect(find.byType(HeroHeader), findsOneWidget);
    expect(find.text('Driver Details'), findsOneWidget);
    expect(find.text('Ramesh Kumar'), findsNWidgets(2)); // in header subtitle and in card
    expect(find.byTooltip('Edit'), findsOneWidget);
    expect(find.text('Personal & License Info'), findsOneWidget);
    expect(find.text('Vehicle Assignment'), findsOneWidget);
  });

  testWidgets('TransporterDriverForm renders HeroHeader and driver registration form fields', (tester) async {
    Get.put<TransporterDriverController>(_OfflineDriverController());
    tester.view.physicalSize = const Size(450, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(GetMaterialApp(home: const TransporterDriverForm()));
    await tester.pump();

    expect(find.byType(HeroHeader), findsOneWidget);
    expect(find.text('Register Driver'), findsNWidgets(2)); // in header and on submit button
    expect(find.text('Personal Details'), findsOneWidget);
    expect(find.text('License & Experience'), findsOneWidget);
    expect(find.text('Other Details'), findsOneWidget);
  });
}
