import 'package:daalsetu/modules/seller/branches/model/seller_branch_model.dart';
import 'package:daalsetu/modules/seller/products/controller/seller_product_controller.dart';
import 'package:daalsetu/modules/seller/products/view/add_product_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _Offline extends SellerProductController {
  @override
  void onInit() {}
}

Future<_Offline> _open(WidgetTester tester, {required List<SellerBranchModel> branches}) async {
  tester.view.physicalSize = const Size(900, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final controller = Get.put<SellerProductController>(_Offline()) as _Offline;
  controller.branches.assignAll(branches);
  controller.selectedBranchIds.addAll(branches.map((b) => b.id!));
  await tester.pumpWidget(const GetMaterialApp(home: AddProductView()));
  await tester.pump();
  return controller;
}

void main() {
  branchListTests();
  tearDown(Get.reset);

  testWidgets('a seller in no branch sees why, and a Join a branch button', (tester) async {
    await _open(tester, branches: []);
    expect(find.byKey(const Key('no-branch-notice')), findsOneWidget);
    expect(find.text('Join a branch'), findsOneWidget);
    expect(find.text('Visible in Branches'), findsOneWidget);
  });

  testWidgets('a seller with no registered company is told so, with a Register company button', (tester) async {
    final controller = await _open(tester, branches: []);
    controller.companiesLoaded.value = true; // the list was read and is empty
    await tester.pump();
    expect(find.byKey(const Key('no-company-notice')), findsOneWidget);
    expect(find.text('Register company'), findsOneWidget);
  });

  testWidgets('no company notice while the company list has not been read yet', (tester) async {
    await _open(tester, branches: []);
    expect(find.byKey(const Key('no-company-notice')), findsNothing);
  });

  testWidgets('a seller with branches picks among them', (tester) async {
    await _open(tester, branches: [SellerBranchModel(id: 1, locationName: 'Nagpur'), SellerBranchModel(id: 2, locationName: 'Amalner')]);
    expect(find.byKey(const Key('no-branch-notice')), findsNothing);
    expect(find.text('Nagpur'), findsOneWidget);
    expect(find.text('Amalner'), findsOneWidget);
  });
}

void branchListTests() {
  test('Create Offer lists the primary branch AND the other branches (the API keeps them apart)', () {
    final branches = allSellerBranches({
      'primary_branch': {'id': 1, 'branch_code': 'AMR158M', 'location_name': 'Amalner'},
      'my_branches': [
        {'id': 2, 'branch_code': 'NGP001', 'location_name': 'Nagpur'},
        {'id': 1, 'branch_code': 'AMR158M', 'location_name': 'Amalner'}, // a repeat is listed once
      ],
    });
    expect(branches.map((b) => b.id), [1, 2]);
  });

  test('a seller with only a primary branch still gets it', () {
    expect(allSellerBranches({'primary_branch': {'id': 5, 'location_name': 'Only'}, 'my_branches': []}).map((b) => b.id), [5]);
    expect(allSellerBranches({'primary_branch': null, 'my_branches': []}), isEmpty);
  });
}
