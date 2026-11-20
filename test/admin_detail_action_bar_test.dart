import 'package:daalsetu/modules/admin_catalog/config/admin_module_config.dart';
import 'package:daalsetu/modules/admin_catalog/model/admin_record.dart';
import 'package:daalsetu/modules/admin_catalog/view/admin_record_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final kyc = AdminModules.byKey('kyc');
  setUp(() => SharedPreferences.setMockInitialValues({'access_token': 'dummy_token'}));

  for (final status in ['pending', 'approved', 'rejected']) {
    testWidgets('User KYC details ($status) have Approve and Reject buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AdminRecordDetailScreen(
            // The real KYC config, without its detail URL (no network in a widget test): the list row is the detail.
            config: AdminModuleConfig(
              key: kyc.key,
              title: kyc.title,
              icon: kyc.icon,
              listEndpoint: kyc.listEndpoint,
              titleKeys: kyc.titleKeys,
              detailSections: kyc.detailSections,
              customActions: kyc.customActions,
            ),
            record: AdminRecord({'id': 175, 'name': 'Test User', 'role': 'buyer', 'kyc_status': status}),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.widgetWithText(ElevatedButton, 'Approve'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Reject'), findsOneWidget);
    });
  }
}
