import 'package:flutter_test/flutter_test.dart';
import 'package:daalsetu/modules/seller/products/controller/seller_product_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Weight to Bag Calculation Logic Tests', () {
    late SellerProductController controller;

    setUp(() {
      controller = SellerProductController();
      controller.attachCalculationListeners();
    });

    test('Entering quantity calculates bag count based on default packing weight', () {
      controller.packingWeightController.text = '30';
      controller.quantityController.text = '100'; // 100 QTL = 10,000 kg

      // Expect ceil(10,000 / 30) = 334 bags
      expect(controller.bagCountController.text, '334');
      expect(controller.quantityController.text, '100');
    });

    test('Updating weight adjusts bag count without modifying quintal quantity', () {
      // 1. Enter 100 QTL
      controller.packingWeightController.text = '30';
      controller.quantityController.text = '100'; // 10,000 kg -> 334 bags
      expect(controller.bagCountController.text, '334');

      // 2. User updates packing weight to 50 kg/bag
      controller.packingWeightController.text = '50';

      // 3. Bags must dynamically adjust to 200 bags (10,000 / 50 = 200)
      expect(controller.bagCountController.text, '200');
      // 4. Quintal quantity must remain 100 QTL (not unexpectedly modified)
      expect(controller.quantityController.text, '100');

      // 5. User updates packing weight to 25 kg/bag
      controller.packingWeightController.text = '25';
      expect(controller.bagCountController.text, '400');
      expect(controller.quantityController.text, '100');
    });

    test('Updating bags adjusts packing weight when quantity is already present', () {
      // 1. Enter 100 QTL
      controller.packingWeightController.text = '50';
      controller.quantityController.text = '100'; // 10,000 kg -> 200 bags
      expect(controller.bagCountController.text, '200');

      // 2. User updates bags to 400
      controller.bagCountController.text = '400';

      // 3. Packing weight adjusts to 25 kg/bag (10,000 / 400 = 25)
      expect(controller.packingWeightController.text, '25');
      // 4. Quintal quantity remains 100 QTL
      expect(controller.quantityController.text, '100');
    });

    test('Switching quantity unit recalculates bags correctly', () {
      controller.packingWeightController.text = '50';
      controller.quantityController.text = '10'; // 10 QTL = 1,000 kg -> 20 bags
      expect(controller.bagCountController.text, '20');

      // Switch to TON: 10 TON = 10,000 kg -> 200 bags
      controller.setOfferUnit('ton');
      expect(controller.bagCountController.text, '200');
      expect(controller.quantityController.text, '10');
    });

    test('Entering bags and packing weight when quantity is empty calculates quantity', () {
      controller.clearForm();
      controller.quantityController.clear();
      controller.packingWeightController.clear();
      controller.bagCountController.clear();

      controller.packingWeightController.text = '50';
      controller.bagCountController.text = '200'; // 200 * 50 = 10,000 kg = 100 QTL

      expect(controller.quantityController.text, '100');
    });
  });
}
