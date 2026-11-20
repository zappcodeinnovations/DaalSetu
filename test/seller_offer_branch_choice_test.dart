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
  tearDown(Get.reset);

  testWidgets('a seller in no branch sees why, and a Join a branch button', (tester) async {
    await _open(tester, branches: []);
    expect(find.byKey(const Key('no-branch-notice')), findsOneWidget);
    expect(find.text('Join a branch'), findsOneWidget);
    expect(find.text('Visible in Branches'), findsOneWidget);
  });

  testWidgets('a seller with branches picks among them', (tester) async {
    await _open(tester, branches: [SellerBranchModel(id: 1, locationName: 'Nagpur'), SellerBranchModel(id: 2, locationName: 'Amalner')]);
    expect(find.byKey(const Key('no-branch-notice')), findsNothing);
    expect(find.text('Nagpur'), findsOneWidget);
    expect(find.text('Amalner'), findsOneWidget);
  });
}
