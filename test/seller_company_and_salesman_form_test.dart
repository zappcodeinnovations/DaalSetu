import 'package:daalsetu/modules/admin_catalog/config/admin_module_config.dart';
import 'package:daalsetu/modules/seller/company/controller/seller_company_controller.dart';
import 'package:daalsetu/modules/seller/company/model/seller_company_model.dart';
import 'package:daalsetu/modules/seller/company/view/add_company_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _Offline extends SellerCompanyController {
  @override
  void onInit() {}
}

void main() {
  tearDown(Get.reset);

  testWidgets('Register Company has the Number of Employees and Landmark fields, like the web', (tester) async {
    tester.view.physicalSize = const Size(900, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Get.put<SellerCompanyController>(_Offline());
    await tester.pumpWidget(const GetMaterialApp(home: AddCompanyView()));
    await tester.pump();
    expect(find.text('Number of Employees'), findsWidgets); // label (and hint)
    expect(find.text('Landmark'), findsWidgets);
  });

  test('the company form reads the two fields back when editing', () {
    final controller = _Offline();
    controller.populateFields(SellerCompanyModel.fromJson({
      'id': 3,
      'legal_name': 'Agro',
      'year_of_establishment': 2019,
      'number_of_employees': 25,
      'landmark': 'Near Bus Stand',
      'created_at': '2026-11-20T10:00:00Z',
      'updated_at': '2026-11-20T10:00:00Z',
    }));
    expect(controller.employeesController.text, '25');
    expect(controller.landmarkController.text, 'Near Bus Stand');
    controller.clearForm();
    expect(controller.employeesController.text, isEmpty);
    expect(controller.landmarkController.text, isEmpty);
  });

  test('Create Salesman: Branch Ref Code is pre-filled from the user\'s own branch (loader set)', () {
    final field = AdminModules.byKey('salesman').fields.firstWhere((f) => f.key == 'branch_ref_code');
    expect(field.defaultLoader, isNotNull);
  });
}
