import 'package:daalsetu/modules/admin_catalog/config/admin_module_config.dart';
import 'package:daalsetu/modules/admin_catalog/controller/admin_catalog_controller.dart';
import 'package:daalsetu/modules/admin_catalog/model/admin_record.dart';
import 'package:daalsetu/modules/admin_catalog/repository/admin_catalog_repository.dart';
import 'package:daalsetu/widgets/admin_common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class FakeAdminCatalogRepository extends AdminCatalogRepository {
  FakeAdminCatalogRepository(super.config);

  int fetchCallCount = 0;
  String? lastSearchParam;
  String? lastFilterParam;

  @override
  Future<AdminPageResult> fetch({
    required int page,
    required int pageSize,
    String search = '',
    String filter = '',
  }) async {
    fetchCallCount++;
    lastSearchParam = search;
    lastFilterParam = filter;

    final mockBrands = [
      const AdminRecord({'id': 1, 'brand_name': 'Tata Sampann', 'status': 'active'}),
      const AdminRecord({'id': 2, 'brand_name': 'Fortune', 'status': 'active'}),
      const AdminRecord({'id': 3, 'brand_name': 'Aashirvaad', 'status': 'pending'}),
    ];

    final filtered = mockBrands.where((b) {
      if (search.isNotEmpty && !b['brand_name'].toString().toLowerCase().contains(search.toLowerCase())) {
        return false;
      }
      if (filter.isNotEmpty && b['status'] != filter) {
        return false;
      }
      return true;
    }).toList();

    return AdminPageResult(
      records: filtered,
      total: filtered.length,
      hasNext: false,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Brand Master Search and Refresh Tests', () {
    late AdminModuleConfig brandConfig;
    late FakeAdminCatalogRepository repository;
    late AdminCatalogController controller;

    setUp(() {
      Get.reset();
      brandConfig = AdminModules.byKey('brands');
      repository = FakeAdminCatalogRepository(brandConfig);
      controller = AdminCatalogController(repository);
    });

    tearDown(() {
      Get.reset();
    });

    test('Brand Master controller initializes with empty search and loads all brands', () async {
      expect(controller.search.value, '');
      await controller.load();
      expect(repository.lastSearchParam, '');
      expect(controller.records.length, 3);
    });

    test('Searching updates search state and filters brand records', () async {
      controller.search.value = 'Tata';
      await controller.load(refresh: true);
      expect(repository.lastSearchParam, 'Tata');
      expect(controller.records.length, 1);
      expect(controller.records.first['brand_name'], 'Tata Sampann');
    });

    test('resetSearch resets search query to empty string', () {
      controller.search.value = 'Fortune';
      expect(controller.search.value, 'Fortune');
      controller.resetSearch();
      expect(controller.search.value, '');
    });

    test('load with resetSearch=true clears previous search and reloads full brand list', () async {
      // First perform a search
      controller.search.value = 'Fortune';
      await controller.load(refresh: true);
      expect(controller.records.length, 1);

      // Refresh with resetSearch=true
      await controller.load(refresh: true, resetSearch: true);
      expect(controller.search.value, '');
      expect(repository.lastSearchParam, '');
      expect(controller.records.length, 3);
    });

    test('Unrelated filters like status are preserved when search is reset', () async {
      controller.selectedFilter.value = 'active';
      controller.search.value = 'Fortune';
      await controller.load(refresh: true);
      expect(controller.records.length, 1);

      // Reset search only
      controller.resetSearch();
      await controller.load(refresh: true);
      expect(controller.search.value, '');
      expect(controller.selectedFilter.value, 'active');
      expect(repository.lastFilterParam, 'active');
      expect(controller.records.length, 2); // 2 active brands
    });

    testWidgets('AdminSearchBar renders controller value and clear button behavior', (tester) async {
      final textController = TextEditingController(text: 'Fortune');
      String currentSearch = 'Fortune';
      bool clearCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminSearchBar(
              controller: textController,
              hint: 'Search Brand Master',
              onChanged: (val) => currentSearch = val,
              onClear: () => clearCalled = true,
            ),
          ),
        ),
      );
      await tester.pump();

      // Clear icon button is present when text is not empty
      final clearButtonFinder = find.byIcon(Icons.clear_rounded);
      expect(clearButtonFinder, findsOneWidget);

      // Tap clear button
      await tester.tap(clearButtonFinder);
      await tester.pump();

      expect(textController.text, '');
      expect(currentSearch, '');
      expect(clearCalled, isTrue);
      // Clear icon disappears when text is cleared
      expect(find.byIcon(Icons.clear_rounded), findsNothing);
    });

    testWidgets('Simulated refresh clears search field and controller search', (tester) async {
      final textController = TextEditingController(text: 'Tata');
      controller.search.value = 'Tata';
      await controller.load(refresh: true);
      expect(controller.records.length, 1);

      // Simulating what _refresh() does on AppBar refresh / RefreshIndicator:
      textController.clear();
      controller.resetSearch();
      await controller.load(refresh: true);

      expect(textController.text, '');
      expect(controller.search.value, '');
      expect(repository.lastSearchParam, '');
      expect(controller.records.length, 3);
    });
  });
}
