import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:daalsetu/modules/transporter/company/view/transporter_company_view.dart';
import 'package:daalsetu/modules/transporter/company/view/transporter_company_detail.dart';
import 'package:daalsetu/modules/transporter/company/view/transporter_company_form.dart';
import 'package:daalsetu/modules/transporter/company/controller/transporter_company_controller.dart';
import 'package:daalsetu/modules/transporter/company/model/company_model.dart';
import 'package:daalsetu/widgets/hero_header.dart';

class _OfflineCompanyController extends TransporterCompanyController {
  @override
  Future<void> fetchCompanies() async {}
}

CompanyModel _createMockCompany() {
  return CompanyModel(
    id: 1,
    legalName: "DaalSetu Logistics Ltd",
    isPrimary: true,
    companyType: "Private Limited",
    yearOfEstablishment: 2020,
    numberOfEmployees: 50,
    gstNumber: "27AABCS1429B1ZB",
    panNumber: "AABCS1429B",
    addressLine1: "101, Cargo Complex",
    city: "Nagpur",
    state: "Maharashtra",
    pincode: "440001",
    country: "India",
    isVerified: true,
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

  testWidgets('TransporterCompanyView renders HeroHeader and register FAB', (tester) async {
    Get.put<TransporterCompanyController>(_OfflineCompanyController());
    tester.view.physicalSize = const Size(450, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(GetMaterialApp(home: TransporterCompanyView()));
    await tester.pump();

    expect(find.byType(HeroHeader), findsOneWidget);
    expect(find.text('My Companies'), findsOneWidget);
    expect(find.text('Manage your registered transport entities'), findsOneWidget);
    expect(find.text('Register Company'), findsOneWidget);
  });

  testWidgets('TransporterCompanyDetail renders HeroHeader with company and address info', (tester) async {
    Get.put<TransporterCompanyController>(_OfflineCompanyController());
    tester.view.physicalSize = const Size(450, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final company = _createMockCompany();
    await tester.pumpWidget(GetMaterialApp(home: TransporterCompanyDetail(company: company)));
    await tester.pump();

    expect(find.byType(HeroHeader), findsOneWidget);
    expect(find.text('Company Details'), findsOneWidget);
    expect(find.text('DaalSetu Logistics Ltd'), findsNWidgets(2)); // in header subtitle and in card
    expect(find.text('PRIMARY COMPANY'), findsOneWidget);
    expect(find.text('Company Information'), findsOneWidget);
    expect(find.text('Address Information'), findsOneWidget);
  });

  testWidgets('TransporterCompanyForm renders HeroHeader and company registration form fields', (tester) async {
    Get.put<TransporterCompanyController>(_OfflineCompanyController());
    tester.view.physicalSize = const Size(450, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(GetMaterialApp(home: const TransporterCompanyForm()));
    await tester.pump();

    expect(find.byType(HeroHeader), findsOneWidget);
    expect(find.text('Register Company'), findsNWidgets(2)); // in header and on submit button
    expect(find.text('Basic Details'), findsOneWidget);
    expect(find.text('Tax Information'), findsOneWidget);
    expect(find.text('Address'), findsOneWidget);
  });
}
