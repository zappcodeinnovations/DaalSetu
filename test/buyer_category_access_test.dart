import 'dart:convert';
import 'package:daalsetu/services/category_services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(
    () => FlutterSecureStorage.setMockInitialValues({'access_token': 'test'}),
  );

  Future<BuyerCategoriesResult> load(Map<String, dynamic> data) =>
      http.runWithClient(
        CategoryService.fetchBuyerCategoryData,
        () => MockClient(
          (_) async =>
              http.Response(jsonEncode({'success': true, 'data': data}), 200),
        ),
      );

  const catalog = [
    {'id': 1, 'category_name': 'Chana', 'status': 'active'},
    {
      'id': 2,
      'category_name': 'Moong',
      'status': 'approved',
      'is_approved': true,
    },
    {'id': 3, 'category_name': 'Toor'},
  ];

  test(
    'new buyer has no approved categories but can choose from the system catalog',
    () async {
      final result = await load({
        'all_categories': catalog,
        'assigned_category_ids': [],
        'pending_category_ids': [],
        'requests': [],
      });
      expect(result.buyerCategories, isEmpty);
      expect(result.systemCategories.length, 3);
      expect(result.requests, isEmpty);
    },
  );

  test(
    'only buyer-specific approved and pending ids appear in My Categories',
    () async {
      final result = await load({
        'all_categories': catalog,
        'assigned_category_ids': [1],
        'pending_category_ids': [3],
        'requests': [],
      });
      expect(result.buyerCategories.map((c) => c.id), [1, 3]);
      expect(result.buyerCategories.map((c) => c.status), [
        'Approved',
        'Pending',
      ]);
    },
  );

  test(
    'old approved request history cannot restore a removed assignment',
    () async {
      final result = await load({
        'all_categories': catalog,
        'assigned_category_ids': [],
        'pending_category_ids': [],
        'requests': [
          {
            'id': 5,
            'status': 'approved',
            'categories': [catalog.first],
          },
        ],
      });
      expect(result.buyerCategories, isEmpty);
      expect(result.requests.length, 1);
    },
  );

  test(
    'a category active in the global catalog is not a buyer approval',
    () async {
      final result = await load({
        'all_categories': [catalog.first],
        'requests': [],
      });
      expect(result.buyerCategories, isEmpty);
      expect(result.systemCategories.length, 1);
    },
  );
}
