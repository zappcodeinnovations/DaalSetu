import 'package:daalsetu/modules/category/controller/category_controller.dart';
import 'package:daalsetu/modules/category/model/category_model.dart';
import 'package:daalsetu/modules/category/view/category_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _Fake extends CategoryController {
  List<int> sent = [];

  @override
  Future<void> fetchCategories() async {}

  @override
  Future<bool> sendForApproval({List<int>? categoryIds, String? categoryName, String? note}) async {
    sent = categoryIds ?? [];
    return true;
  }
}

void main() {
  setUp(Get.reset);
  tearDown(Get.reset);

  testWidgets('requestable categories are listed on the page itself; ticking and sending needs no sheet', (tester) async {
    final controller = _Fake();
    Get.put<CategoryController>(controller);
    controller.systemCategories.assignAll([
      CategoryModel.fromJson({'id': 1, 'category_name': 'Chana', 'status': 'active'}),
      CategoryModel.fromJson({'id': 2, 'category_name': 'Moong Dal', 'status': 'active'}),
      CategoryModel.fromJson({'id': 3, 'category_name': 'Toor Dal', 'status': 'active'}),
    ]);
    controller.allCategories.assignAll([
      CategoryModel.fromJson({'id': 3, 'category_name': 'Toor Dal', 'status': 'Approved'}),
    ]);

    await tester.pumpWidget(const GetMaterialApp(home: CategoryPageView()));
    await tester.pump(const Duration(milliseconds: 300));

    // On the page, right away: the two not-yet-requested categories (Toor Dal is already approved).
    expect(find.text('Chana'), findsOneWidget);
    expect(find.text('Moong Dal'), findsOneWidget);
    expect(find.byType(CheckboxListTile), findsNWidgets(2));
    expect(find.textContaining('SEND FOR APPROVAL'), findsOneWidget);

    await tester.tap(find.text('Chana'));
    await tester.tap(find.text('Moong Dal'));
    await tester.pump();
    expect(find.text('SEND FOR APPROVAL (2)'), findsOneWidget);

    await tester.tap(find.text('SEND FOR APPROVAL (2)'));
    await tester.pump();
    expect(controller.sent.toSet(), {1, 2});
    expect(controller.selectedRequestIds, isEmpty);
  });
}
