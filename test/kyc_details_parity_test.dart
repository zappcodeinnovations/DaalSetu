import 'package:daalsetu/modules/admin_catalog/config/admin_module_config.dart';
import 'package:daalsetu/modules/admin_catalog/model/admin_record.dart';
import 'package:daalsetu/modules/admin_catalog/view/admin_record_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'access_token': 'dummy_token'});
  });

  testWidgets('User KYCs Details renders all parity fields including First Name, Last Name, Account Status, Timestamps, and Date Joined', (tester) async {
    final baseConfig = AdminModules.byKey('kyc');
    final testConfig = AdminModuleConfig(
      key: baseConfig.key,
      title: baseConfig.title,
      icon: baseConfig.icon,
      listEndpoint: baseConfig.listEndpoint,
      titleKeys: baseConfig.titleKeys,
      detailSections: baseConfig.detailSections,
    );

    const record = AdminRecord({
      'id': 138,
      'username': '1234567892',
      'name': 'Transporter Test',
      'first_name': 'Transporter',
      'last_name': 'Test',
      'mobile': '1234567892',
      'email': 'traspoter@gmail.com',
      'role': 'transporter',
      'is_active': true,
      'account_status': 'active',
      'date_joined': '2026-10-10T12:00:00Z',
      'kyc_status': 'approved',
      'kyc_submitted_at': '2026-10-10T14:30:00Z',
      'kyc_approved_at': '2026-10-11T10:00:00Z',
      'rejection_reason': null,
      'remarks': 'All verified',
    });

    await tester.pumpWidget(
      MaterialApp(
        home: AdminRecordDetailScreen(
          config: testConfig,
          record: record,
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify User Information fields
    expect(find.text('User ID'), findsOneWidget);
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('First Name'), findsOneWidget);
    expect(find.text('Last Name'), findsOneWidget);
    expect(find.text('Mobile Number'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Role'), findsOneWidget);
    expect(find.text('Account Status'), findsOneWidget);
    expect(find.text('Date Joined'), findsOneWidget);

    // Verify KYC Details fields
    expect(find.text('KYC Status'), findsOneWidget);
    expect(find.text('Submitted At'), findsOneWidget);
    expect(find.text('Approved At'), findsOneWidget);
    expect(find.text('Rejection Reason'), findsOneWidget);
    expect(find.text('Remarks'), findsOneWidget);
  });

  testWidgets('Name field displays synthesized full name rather than phone number username', (tester) async {
    final baseConfig = AdminModules.byKey('kyc');
    final testConfig = AdminModuleConfig(
      key: baseConfig.key,
      title: baseConfig.title,
      icon: baseConfig.icon,
      listEndpoint: baseConfig.listEndpoint,
      titleKeys: baseConfig.titleKeys,
      detailSections: baseConfig.detailSections,
    );

    // Simulated payload where name is missing or numeric phone, but first/last name exist
    const record = AdminRecord({
      'id': 138,
      'username': '1234567892',
      'name': '', // name is empty
      'first_name': 'Transporter',
      'last_name': 'Test',
      'mobile': '1234567892',
      'email': 'traspoter@gmail.com',
      'role': 'transporter',
      'is_active': true,
      'account_status': 'active',
      'date_joined': '2026-10-10T12:00:00Z',
      'kyc_status': 'approved',
    });

    await tester.pumpWidget(
      MaterialApp(
        home: AdminRecordDetailScreen(
          config: testConfig,
          record: record,
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Name must be 'Transporter Test', not the phone number
    expect(find.text('Transporter Test'), findsOneWidget);
    expect(find.text('Transporter'), findsOneWidget);
    expect(find.text('Test'), findsOneWidget);
  });
}

