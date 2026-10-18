import 'package:daalsetu/modules/category/controller/category_controller.dart';
import 'package:daalsetu/modules/category/model/category_model.dart';
import 'package:daalsetu/modules/category/model/category_request_model.dart';
import 'package:daalsetu/modules/category/view/category_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class MockCategoryController extends CategoryController {
  @override
  void onInit() {
    super.onInit();
  }

  @override
  Future<void> fetchCategories() async {}
}

void main() {
  setUp(() {
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  group('Category Models Parsing', () {
    test('CategoryModel parses requestedAt and formats correctly', () {
      final cat = CategoryModel.fromJson({
        'id': 74,
        'category_name': 'Chana',
        'status': 'Approved',
        'requested_at': '2026-10-16T06:21:18.538795+05:30',
        'created_at': '2026-10-16T06:21:18.538795+05:30',
      });

      expect(cat.id, 74);
      expect(cat.categoryName, 'Chana');
      expect(cat.requestedAt, isNotNull);
      expect(cat.status, 'Approved');
    });

    test('CategoryRequestModel parses request details and timestamps', () {
      final req = CategoryRequestModel.fromJson({
        'id': 38,
        'status': 'approved',
        'buyer': {
          'id': 137,
          'name': 'Test Buyer',
        },
        'categories': [
          {'id': 69, 'category_name': 'Unpolishedd'},
          {'id': 72, 'category_name': 'Moong Dal'},
          {'id': 73, 'category_name': 'Masoo'},
        ],
        'request_note': 'Buyer requested category approval.',
        'requested_at': '2026-10-17T10:54:09.997452+05:30',
        'reviewed_by': {
          'id': 10,
          'name': 'Pradeep H Jhawar',
        },
        'reviewed_at': '2026-10-17T10:54:25.777788+05:30',
        'admin_comment': 'Approved by admin',
      });

      expect(req.id, 38);
      expect(req.status, 'approved');
      expect(req.categoryNames, ['Unpolishedd', 'Moong Dal', 'Masoo']);
      expect(req.requestedAt, isNotNull);
      expect(req.reviewedAt, isNotNull);
      expect(req.reviewerName, 'Pradeep H Jhawar');
      expect(req.adminComment, 'Approved by admin');
    });
  });

  group('CategoryPageView Widget UI', () {
    testWidgets('renders category cards with requested timestamp and Recent Requests tab', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = MockCategoryController();
      Get.put<CategoryController>(controller);

      final cat1 = CategoryModel.fromJson({
        'id': 74,
        'category_name': 'Chana',
        'status': 'Approved',
        'requested_at': '2026-10-16T06:21:18.538795+05:30',
      });
      controller.allCategories.assignAll([cat1]);
      controller.categories.assignAll([cat1]);

      final req1 = CategoryRequestModel.fromJson({
        'id': 38,
        'status': 'approved',
        'categories': [
          {'id': 69, 'category_name': 'Unpolishedd'},
          {'id': 72, 'category_name': 'Moong Dal'},
        ],
        'requested_at': '2026-10-17T10:54:09.997452+05:30',
      });
      controller.recentRequests.assignAll([req1]);

      await tester.pumpWidget(
        const GetMaterialApp(
          home: CategoryPageView(),
        ),
      );
      await tester.pumpAndSettle();

      // Check Tabs
      expect(find.text('My Categories'), findsOneWidget);
      expect(find.text('Recent Requests'), findsOneWidget);

      // Check Category Card
      expect(find.text('Chana'), findsOneWidget);
      expect(find.text('Approved'), findsOneWidget);
      expect(find.textContaining('Requested on'), findsOneWidget);

      // Switch to Recent Requests tab
      await tester.tap(find.text('Recent Requests'));
      await tester.pumpAndSettle();

      // Check Recent Request item
      expect(find.text('Unpolishedd, Moong Dal'), findsOneWidget);
      expect(find.text('APPROVED'), findsOneWidget);
    });
  });
}
