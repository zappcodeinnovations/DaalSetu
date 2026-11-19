import 'package:daalsetu/modules/admin_catalog/config/admin_module_config.dart';
import 'package:daalsetu/modules/seller/categories/view/seller_category_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Inactive categories get a blocked icon and grey colour, not the pending look', () {
    expect(categoryStatusIcon('inactive'), Icons.block);
    expect(categoryStatusColor('inactive'), Colors.grey);
    expect(categoryStatusIcon('active'), Icons.check_circle_outline);
    expect(categoryStatusColor('pending'), Colors.orange);
    expect(categoryStatusColor('rejected'), Colors.red);
  });

  test('admin category and sub-category forms offer the four statuses', () {
    for (final key in ['categories', 'sub_categories']) {
      final module = AdminModules.all[key]!;
      final status = module.fields.firstWhere((f) => f.key == 'status');
      expect(status.options, ['active', 'pending', 'inactive', 'rejected']);
      expect(status.optionLabels['inactive'], 'Inactive');
    }
  });
}
