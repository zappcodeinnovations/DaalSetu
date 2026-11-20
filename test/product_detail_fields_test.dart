import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

// The web offer detail has no "Seller login" and no "Remaining bags" - only the remaining quantity.
void main() {
  test('the product detail screen does not show Seller login or Remaining bags', () {
    final lines = File('lib/modules/products/view/product_detail.dart').readAsLinesSync();
    final live = lines.where((l) => !l.trimLeft().startsWith('//')).join('\n');
    expect(live.contains("'Seller login'"), isFalse);
    expect(live.contains("'Remaining bags'"), isFalse);
    expect(live.contains("'Remaining quantity'"), isTrue);
  });
}
