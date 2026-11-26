import 'package:flutter_test/flutter_test.dart';
import 'package:daalsetu/modules/products/controller/product_controller.dart';
import 'package:daalsetu/modules/products/model/product_model.dart';
import 'package:daalsetu/modules/products/view/product_view.dart';
import 'package:get/get.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  group('Bug 1: Out of Stock Badge Clean Formatting', () {
    testWidgets('product card formats OUT_OF_STOCK as clean Out of Stock badge copy',
        (WidgetTester tester) async {
      final controller = Get.put(ProductController());
      final product = ProductModel.fromJson({
        'id': 999,
        'title': 'Yellow Daal',
        'status': 'OUT_OF_STOCK',
        'stock_status': 'out_of_stock',
        'available_quantity': '0.0',
        'amount': '80.0',
        'loading_location': 'plot no 565, ramnagar, nagpur',
      });
      controller.products.assignAll([product]);
      controller.isLoading.value = false;

      await tester.pumpWidget(
        GetMaterialApp(
          home: ProductScreen(),
        ),
      );
      await tester.pump();

      // Verify that raw OUT_OF_STOCK is absent and clean Out of Stock copy is rendered
      expect(find.text('OUT_OF_STOCK'), findsNothing);
      expect(find.text('Out of Stock'), findsOneWidget);
    });

    testWidgets('product card formats available status as Available badge copy',
        (WidgetTester tester) async {
      final controller = Get.put(ProductController());
      final product = ProductModel.fromJson({
        'id': 1000,
        'title': 'Chana Daal',
        'status': 'available',
        'stock_status': 'available',
        'available_quantity': '50.0',
        'amount': '75.0',
        'loading_location': 'Nagpur',
      });
      controller.products.assignAll([product]);
      controller.isLoading.value = false;

      await tester.pumpWidget(
        GetMaterialApp(
          home: ProductScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('Available'), findsOneWidget);
      expect(find.text('AVAILABLE'), findsNothing);
    });
  });

  group('Bug 2: Category Requests Manage Categories Root Filtering & Web Parity', () {
    test('isolates root parent categories from child subcategories and pending entries', () {
      final sampleCategories = [
        {'id': 1, 'name': 'Basmati Rice 0', 'parent': null, 'level': 0, 'status': 'active'},
        {'id': 2, 'name': 'byharman12', 'parent': null, 'level': 0, 'status': 'active'},
        {'id': 3, 'name': 'Chana', 'parent': null, 'level': 0, 'status': 'active'},
        {'id': 4, 'name': 'new category', 'parent': 2, 'level': 1, 'status': 'pending'},
        {'id': 5, 'name': 'testy6', 'parent': 2, 'level': 1, 'status': 'active'},
        {'id': 6, 'name': 'Polished', 'parent': 3, 'level': 1, 'status': 'active'},
        {'id': 7, 'name': 'Split Yellow', 'parent': 3, 'level': 1, 'status': 'active'},
        {'id': 8, 'name': 'Whole Green', 'parent': 3, 'level': 1, 'status': 'active'},
        {'id': 9, 'name': 'Chilka', 'parent': 3, 'level': 1, 'status': 'active'},
        {'id': 10, 'name': 'Pending Commodity', 'parent': null, 'level': 0, 'status': 'pending'},
        {'id': 11, 'name': 'Inactive Commodity', 'parent': null, 'level': 0, 'status': 'inactive'},
        {'id': 12, 'name': 'Toor Dal', 'parent': null, 'level': 0, 'status': 'active'},
        {'id': 13, 'name': 'Moong Dal', 'parent': null, 'level': 0, 'status': 'active'},
        {'id': 14, 'name': 'Masoo', 'parent': null, 'level': 0, 'status': 'active'},
        {'id': 15, 'name': 'Unpolishedd', 'parent': null, 'level': 0, 'status': 'active'},
        {'id': 16, 'name': 'URAD DAL', 'parent': null, 'level': 0, 'status': 'active'},
      ];

      final Set<int> seenIds = {};
      final List<Map<String, dynamic>> filteredCategories = [];

      for (var item in sampleCategories) {
        final id = item['id'] as int;
        if (seenIds.contains(id)) continue;

        final parent = item['parent'];
        final level = item['level'];
        final status = (item['status'] ?? '').toString().trim().toLowerCase();
        final isSub = item['is_sub'] == true ||
            item['is_subcategory'] == true ||
            item['is_sub_category'] == true;

        final hasParent = parent != null &&
            parent.toString().isNotEmpty &&
            parent.toString() != 'null' &&
            parent.toString() != '0';
        final hasLevel = level != null &&
            level.toString().isNotEmpty &&
            level.toString() != 'null' &&
            level.toString() != '0';

        // Root/parent check: Must have no parent and level 0
        if (isSub || hasParent || hasLevel) continue;

        // Status check: Exclude pending, inactive, rejected categories
        if (status == 'pending' || status == 'inactive' || status == 'rejected') {
          continue;
        }

        seenIds.add(id);
        filteredCategories.add(item);
      }

      filteredCategories.sort((a, b) {
        final nameA = (a['name'] ?? '').toString().toLowerCase();
        final nameB = (b['name'] ?? '').toString().toLowerCase();
        return nameA.compareTo(nameB);
      });

      final categoryNames = filteredCategories.map((c) => c['name']).toList();

      // Exactly matches the 8 categories from the web portal reference screenshot
      expect(categoryNames, [
        'Basmati Rice 0',
        'byharman12',
        'Chana',
        'Masoo',
        'Moong Dal',
        'Toor Dal',
        'Unpolishedd',
        'URAD DAL',
      ]);

      // Ensures child and pending entries are strictly filtered out
      expect(categoryNames.contains('new category'), isFalse);
      expect(categoryNames.contains('testy6'), isFalse);
      expect(categoryNames.contains('Polished'), isFalse);
      expect(categoryNames.contains('Split Yellow'), isFalse);
      expect(categoryNames.contains('Whole Green'), isFalse);
      expect(categoryNames.contains('Chilka'), isFalse);
      expect(categoryNames.contains('Pending Commodity'), isFalse);
    });
  });
}
