import 'package:daalsetu/modules/transporter/company/controller/transporter_company_controller.dart';
import 'package:daalsetu/modules/transporter/dashboard/view/transporter_dashboard_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// No network in widget tests: the real controller would call the API and show a snackbar.
class _OfflineCompanyController extends TransporterCompanyController {
  @override
  Future<void> fetchCompanies() async {}
}

void main() {
  testWidgets('transporter dashboard has no shortcut grid; its links are in the drawer', (tester) async {
    Get.testMode = true;
    FlutterSecureStorage.setMockInitialValues({'user_role': 'transporter'});
    Get.put<TransporterCompanyController>(_OfflineCompanyController());
    tester.view.physicalSize = const Size(450, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(GetMaterialApp(home: TransporterDashboardView()));
    await tester.pump();

    // The six "Transporter Workspace" cards duplicated the bottom tabs and are gone.
    expect(find.text('Transporter Workspace'), findsNothing);

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('TRANSPORTER PANEL'), findsOneWidget);
    for (final item in ['Shipment Offers', 'My Deals', 'Drivers', 'Vehicles', 'Company', 'My Branches']) {
      expect(find.text(item), findsOneWidget, reason: item);
    }
  });
}
