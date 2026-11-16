import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:daalsetu/modules/transporter/vehicles/view/transporter_vehicles_view.dart';
import 'package:daalsetu/modules/transporter/vehicles/view/transporter_vehicle_detail.dart';
import 'package:daalsetu/modules/transporter/vehicles/view/transporter_vehicle_form.dart';
import 'package:daalsetu/modules/transporter/vehicles/controller/transporter_vehicle_controller.dart';
import 'package:daalsetu/modules/transporter/vehicles/model/vehicle_model.dart';
import 'package:daalsetu/widgets/hero_header.dart';

class _OfflineVehicleController extends TransporterVehicleController {
  @override
  Future<void> fetchVehicles() async {}
}

VehicleModel _createMockVehicle() {
  return VehicleModel(
    id: 1,
    vehicleNumber: "MH31AB1234",
    vehicleType: "Truck",
    vehicleBrand: "tata",
    vehicleBrandDisplay: "Tata",
    fuelType: "diesel",
    loadCapacityTons: "25",
    bodyType: "open_body",
    bodyTypeDisplay: "Open Body",
    vehicleStatus: "available",
    vehicleStatusDisplay: "Available",
    modelName: "Prima",
    manufacturingYear: 2022,
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

  testWidgets('TransporterVehiclesView renders HeroHeader, search, filters and add FAB', (tester) async {
    Get.put<TransporterVehicleController>(_OfflineVehicleController());
    tester.view.physicalSize = const Size(450, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(GetMaterialApp(home: const TransporterVehiclesView()));
    await tester.pump();

    expect(find.byType(HeroHeader), findsOneWidget);
    expect(find.text('My Vehicles'), findsOneWidget);
    expect(find.text('Manage your registered fleet & drivers'), findsOneWidget);
    expect(find.text('Add Vehicle'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.textContaining('All'), findsOneWidget);
  });

  testWidgets('TransporterVehicleDetail renders HeroHeader with edit and delete actions and specs', (tester) async {
    Get.put<TransporterVehicleController>(_OfflineVehicleController());
    tester.view.physicalSize = const Size(450, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final vehicle = _createMockVehicle();
    await tester.pumpWidget(GetMaterialApp(home: TransporterVehicleDetail(vehicle: vehicle)));
    await tester.pump();

    expect(find.byType(HeroHeader), findsOneWidget);
    expect(find.text('Vehicle Details'), findsOneWidget);
    expect(find.text('MH31AB1234'), findsNWidgets(2)); // in header subtitle and in card
    expect(find.byTooltip('Edit'), findsOneWidget);
    expect(find.byTooltip('Delete'), findsOneWidget);
    expect(find.text('Basic Information'), findsOneWidget);
    expect(find.text('Specifications'), findsOneWidget);
    expect(find.text('Assigned Driver'), findsOneWidget);
  });

  testWidgets('TransporterVehicleForm renders HeroHeader and vehicle registration form fields', (tester) async {
    Get.put<TransporterVehicleController>(_OfflineVehicleController());
    tester.view.physicalSize = const Size(450, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(GetMaterialApp(home: const TransporterVehicleForm()));
    await tester.pump();

    expect(find.byType(HeroHeader), findsOneWidget);
    expect(find.text('Register Vehicle'), findsNWidgets(2)); // in header and on submit button
    expect(find.text('Basic Information'), findsOneWidget);
    expect(find.text('Specifications'), findsOneWidget);
    expect(find.text('Documents'), findsOneWidget);
    expect(find.text('Status'), findsOneWidget);
  });
}
