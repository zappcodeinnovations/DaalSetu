import 'package:daalsetu/modules/seller/products/controller/seller_product_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a comma decimal is read as a decimal (iOS keypads), not as "not a number"', () {
    expect(SellerProductController.parseDecimalInput('12,5'), 12.5);
    expect(SellerProductController.parseDecimalInput(' 30 '), 30);
    expect(SellerProductController.parseDecimalInput('abc'), isNull);
  });

  test('bags follow the quantity and the packing weight, whichever way it is typed', () {
    final controller = SellerProductController();
    controller.attachCalculationListeners();
    controller.packingWeightController.text = '25,5'; // comma decimal
    controller.setOfferUnit('kg');
    controller.quantityController.text = '1020';
    expect(controller.bagCountController.text, '40'); // 1020 / 25.5

    controller.packingWeightController.text = '50';
    expect(controller.bagCountController.text, '21'); // ceil(1020 / 50)
  });
}
