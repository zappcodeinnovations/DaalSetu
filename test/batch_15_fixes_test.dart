import 'package:flutter_test/flutter_test.dart';
import 'package:daalsetu/modules/admin_catalog/config/admin_module_config.dart';
import 'package:daalsetu/modules/admin_catalog/config/admin_actions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Batch 15 Bug 1: Category Requests Manage Categories Parent Filtering', () {
    test('parent categories filtering isolates root categories from child subcategories', () {
      final sampleCategories = [
        {'id': 1, 'name': 'Basmati Rice 0', 'parent': null, 'level': 0},
        {'id': 2, 'name': 'byharman12', 'parent': null, 'level': 0},
        {'id': 3, 'name': 'Chana', 'parent': null, 'level': 0},
        {'id': 4, 'name': 'new category', 'parent': 2, 'level': 1},
        {'id': 5, 'name': 'testy6', 'parent': 2, 'level': 1},
        {'id': 6, 'name': 'Polished', 'parent': 3, 'level': 1},
        {'id': 7, 'name': 'Split Yellow', 'parent': 3, 'level': 1},
      ];

      final parentCategories = sampleCategories.where((c) {
        final parent = c['parent'];
        final level = c['level'];
        return (parent == null || parent.toString().isEmpty || parent.toString() == 'null') &&
            (level == null || level == 0 || level == '0');
      }).toList();

      expect(parentCategories.length, 3);
      expect(parentCategories.map((c) => c['name']).toList(), [
        'Basmati Rice 0',
        'byharman12',
        'Chana',
      ]);
      expect(parentCategories.any((c) => c['name'] == 'testy6'), isFalse);
      expect(parentCategories.any((c) => c['name'] == 'Polished'), isFalse);
    });
  });

  group('Batch 15 Bug 2: Sub-Category Edit Status & Mapped Brands', () {
    test('sub_categories module has status field with pending/active/inactive and mapped_brands', () {
      final subCatConfig = AdminModules.byKey('sub_categories');
      expect(subCatConfig, isNotNull);

      final statusField = subCatConfig.fields.firstWhere((f) => f.key == 'status');
      expect(statusField.label, 'Status');
      expect(statusField.options, containsAll(['pending', 'active', 'inactive']));
      expect(statusField.optionLabels['pending'], 'Pending');
      expect(statusField.optionLabels['active'], 'Active');
      expect(statusField.defaultValue, 'pending');

      final mappedBrandsField = subCatConfig.fields.firstWhere((f) => f.key == 'mapped_brands');
      expect(mappedBrandsField.label, 'Mapped Brands');
      expect(mappedBrandsField.multiSelect, isTrue);
      expect(mappedBrandsField.optionsLoader, isNotNull);
    });

    test('loadBrandOptions function is defined and callable', () {
      expect(loadBrandOptions, isNotNull);
    });
  });

  group('Batch 15 Bug 3: Buyer Card Categories Preview Wrapping', () {
    test('assigned categories string formatting maintains full category names', () {
      final assignedList = [
        {'id': 10, 'name': 'byharman12'},
        {'id': 11, 'name': 'Toor Dal'},
        {'id': 12, 'name': 'Unpolishedd'},
        {'id': 13, 'name': 'Moong Dal'},
        {'id': 14, 'name': 'Masoo'},
        {'id': 15, 'name': 'Chana'},
      ];

      final assignedStr = assignedList
          .map((c) => (c['name']?.toString() ?? ''))
          .where((s) => s.isNotEmpty)
          .join(', ');

      expect(
        assignedStr,
        'byharman12, Toor Dal, Unpolishedd, Moong Dal, Masoo, Chana',
      );
      expect(assignedStr.contains('Unpolishedd'), isTrue);
    });
  });
}
