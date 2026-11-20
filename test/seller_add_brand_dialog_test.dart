import 'package:daalsetu/modules/seller/masters/controller/seller_master_controller.dart';
import 'package:daalsetu/modules/seller/masters/view/seller_add_brand_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _FakeMasters extends SellerMasterController {
  @override
  void onInit() {}
}

void main() {
  testWidgets('Add Brand dialog opens with status and mapped categories', (tester) async {
    final controller = _FakeMasters();
    Get.put<SellerMasterController>(controller);
    controller.categoryTreeList.assignAll([
      {'id': 1, 'category_name': 'Toor Dal'},
      {'id': 2, 'category_name': 'Chana Dal'},
    ]);

    await tester.pumpWidget(GetMaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => Get.dialog(const SellerAddBrandDialog()),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Add Pulse Brand'), findsOneWidget);
    expect(find.text('Mapped Parent Categories'), findsOneWidget);
    expect(find.text('Toor Dal'), findsOneWidget);
    expect(find.text('CREATE BRAND'), findsOneWidget);

    // Ticking a category and the dialog still works.
    await tester.tap(find.text('Toor Dal'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    Get.reset();
  });
}
