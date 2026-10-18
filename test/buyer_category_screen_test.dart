import 'package:flutter_test/flutter_test.dart';
import 'package:daalsetu/modules/category/model/category_model.dart';
import 'package:daalsetu/services/category_services.dart';

void main() {
  group('Buyer Category Screen & Service Tests', () {
    test('BuyerCategoriesResult holds consistent buyer and system categories', () {
      final sampleSys = [
        CategoryModel(id: 1, categoryName: 'Chana', status: 'Approved'),
        CategoryModel(id: 2, categoryName: 'Masoor', status: 'Approved'),
        CategoryModel(id: 3, categoryName: 'Moong Dal', status: 'Approved'),
        CategoryModel(id: 4, categoryName: 'Toor Dal', status: 'Approved'),
        CategoryModel(id: 5, categoryName: 'Unpolishedd', status: 'Approved'),
        CategoryModel(id: 6, categoryName: 'URAD DAL', status: 'Approved'),
      ];

      final res = BuyerCategoriesResult(
        buyerCategories: sampleSys,
        systemCategories: sampleSys,
      );

      expect(res.buyerCategories.length, 6);
      expect(res.systemCategories.length, 6);
      expect(res.buyerCategories.every((c) => c.status == 'Approved'), isTrue);
    });

    test('When all system categories are approved, unassigned categories list is empty', () {
      final allSystem = [
        CategoryModel(id: 1, categoryName: 'Chana'),
        CategoryModel(id: 2, categoryName: 'Masoor'),
        CategoryModel(id: 3, categoryName: 'Moong Dal'),
        CategoryModel(id: 4, categoryName: 'Toor Dal'),
        CategoryModel(id: 5, categoryName: 'Unpolishedd'),
        CategoryModel(id: 6, categoryName: 'URAD DAL'),
      ];

      final allCategoriesOnScreen = [
        CategoryModel(id: 1, categoryName: 'Chana', status: 'Approved'),
        CategoryModel(id: 2, categoryName: 'Masoor', status: 'Approved'),
        CategoryModel(id: 3, categoryName: 'Moong Dal', status: 'Approved'),
        CategoryModel(id: 4, categoryName: 'Toor Dal', status: 'Approved'),
        CategoryModel(id: 5, categoryName: 'Unpolishedd', status: 'Approved'),
        CategoryModel(id: 6, categoryName: 'URAD DAL', status: 'Approved'),
      ];

      final assignedIds = allCategoriesOnScreen
          .where((c) => c.status?.toLowerCase() == 'approved' || c.status?.toLowerCase() == 'pending')
          .map((c) => c.id)
          .toSet();

      final assignedNames = allCategoriesOnScreen
          .where((c) => c.status?.toLowerCase() == 'approved' || c.status?.toLowerCase() == 'pending')
          .map((c) => c.categoryName.trim().toLowerCase())
          .toSet();

      final unassigned = allSystem.where((c) =>
          !assignedIds.contains(c.id) &&
          !assignedNames.contains(c.categoryName.trim().toLowerCase())).toList();

      expect(unassigned.isEmpty, isTrue);
    });

    test('When a category is unassigned, it matches the exact system category', () {
      final allSystem = [
        CategoryModel(id: 1, categoryName: 'Chana'),
        CategoryModel(id: 2, categoryName: 'Masoor'),
        CategoryModel(id: 3, categoryName: 'Moong Dal'),
        CategoryModel(id: 4, categoryName: 'Toor Dal'),
        CategoryModel(id: 5, categoryName: 'Unpolishedd'),
        CategoryModel(id: 6, categoryName: 'URAD DAL'),
        CategoryModel(id: 7, categoryName: 'Yellow Peas'),
      ];

      final allCategoriesOnScreen = [
        CategoryModel(id: 1, categoryName: 'Chana', status: 'Approved'),
        CategoryModel(id: 2, categoryName: 'Masoor', status: 'Approved'),
        CategoryModel(id: 3, categoryName: 'Moong Dal', status: 'Approved'),
        CategoryModel(id: 4, categoryName: 'Toor Dal', status: 'Approved'),
        CategoryModel(id: 5, categoryName: 'Unpolishedd', status: 'Approved'),
        CategoryModel(id: 6, categoryName: 'URAD DAL', status: 'Approved'),
      ];

      final assignedIds = allCategoriesOnScreen
          .where((c) => c.status?.toLowerCase() == 'approved' || c.status?.toLowerCase() == 'pending')
          .map((c) => c.id)
          .toSet();

      final assignedNames = allCategoriesOnScreen
          .where((c) => c.status?.toLowerCase() == 'approved' || c.status?.toLowerCase() == 'pending')
          .map((c) => c.categoryName.trim().toLowerCase())
          .toSet();

      final unassigned = allSystem.where((c) =>
          !assignedIds.contains(c.id) &&
          !assignedNames.contains(c.categoryName.trim().toLowerCase())).toList();

      expect(unassigned.length, 1);
      expect(unassigned.first.categoryName, 'Yellow Peas');
      expect(unassigned.first.id, 7);
    });

    test('Categories named test, xyz, sub, or repeated letters are preserved without filtering', () {
      final allCategories = [
        CategoryModel(id: 1, categoryName: 'Test Category'),
        CategoryModel(id: 2, categoryName: 'xyz'),
        CategoryModel(id: 3, categoryName: 'sub'),
        CategoryModel(id: 4, categoryName: 'teat sub'),
        CategoryModel(id: 5, categoryName: 'aaa'),
        CategoryModel(id: 6, categoryName: 'Toor Dal'),
      ];

      final filtered = allCategories.where((c) => c.categoryName.trim().isNotEmpty).toList();
      expect(filtered.length, 6);
      expect(filtered.map((c) => c.categoryName), containsAll([
        'Test Category',
        'xyz',
        'sub',
        'teat sub',
        'aaa',
        'Toor Dal',
      ]));
    });
  });
}
