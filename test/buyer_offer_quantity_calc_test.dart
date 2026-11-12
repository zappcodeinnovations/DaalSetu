import 'package:flutter_test/flutter_test.dart';
import 'package:daalsetu/modules/buyer/offers/model/buyer_offer_model.dart';

void main() {
  group('BuyerOfferModel Quantity Calculation & Data Binding Tests', () {
    test('Calculates 20.100 QTL for "toor angar" (67 bags * 30 kg / 100) when available_quantity is 0.000', () {
      final json = {
        'id': 1,
        'title': 'toor angar',
        'bags': 67,
        'packing': '30.000',
        'available_quantity': '0.000',
        'price': '1000.00',
        'unit': 'QTL',
      };

      final offer = BuyerOfferModel.fromJson(json);

      expect(offer.availableQuantity, '20.100');
      expect(offer.displayQuantity, '20.100 QTL');
      expect(offer.isOutOfStock, false);
    });

    test('Calculates 660.000 QTL for "dal" (2200 bags * 30 kg / 100) when available_quantity is 0', () {
      final json = {
        'id': 2,
        'title': 'dal',
        'bags': 2200,
        'packing': 30,
        'available_quantity': 0,
        'price': '99.00',
        'unit': 'QTL',
      };

      final offer = BuyerOfferModel.fromJson(json);

      expect(offer.availableQuantity, '660.000');
      expect(offer.displayQuantity, '660.000 QTL');
      expect(offer.isOutOfStock, false);
    });

    test('Preserves direct quantity_qtl or positive available_quantity when provided', () {
      final json = {
        'id': 3,
        'title': 'testing',
        'bags': 16667,
        'packing': '30.000',
        'quantity_qtl': '5000.100',
        'available_quantity': '5000.100',
        'price': '10000.00',
      };

      final offer = BuyerOfferModel.fromJson(json);

      expect(offer.availableQuantity, '5000.100');
      expect(offer.displayQuantity, '5000.100 QTL');
      expect(offer.isOutOfStock, false);
    });

    test('Detects true out of stock when bags and quantity are both 0', () {
      final json = {
        'id': 4,
        'title': 'empty item',
        'bags': 0,
        'packing': '30.000',
        'available_quantity': '0.000',
      };

      final offer = BuyerOfferModel.fromJson(json);

      expect(offer.availableQuantity, '0.000');
      expect(offer.displayQuantity, '0.000 QTL');
      expect(offer.isOutOfStock, true);
    });
  });
}
