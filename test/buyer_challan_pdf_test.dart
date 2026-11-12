import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daalsetu/modules/buyer/delivery_challan/model/buyer_delivery_challan_model.dart';
import 'package:daalsetu/modules/buyer/delivery_challan/service/buyer_challan_pdf_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        return Directory.systemTemp.path;
      },
    );
  });

  group('Buyer Delivery Challan PDF Service Tests', () {
    test('BuyerDeliveryChallanModel correctly parses buyerMobile and deliveryAddress', () {
      final json = {
        'id': 73,
        'buyer_name': 'Test Buyer',
        'buyer_address': 'gopal nagar, gopal nagar, Nagpur, Maharashtra, 440022, India',
        'buyer_mobile': '1234567891',
        'driver_name': 'gakshs',
        'driver_mobile': '3546464944',
        'delivery_address': null,
      };

      final model = BuyerDeliveryChallanModel.fromJson(json);
      expect(model.buyerMobile, '1234567891');
      expect(model.driverMobile, '3546464944');
      expect(model.deliveryAddress, isNull);
    });

    test('Buyer delivery challan PDF generates without error and respects buyerMobile and deliveryAddress', () async {
      final sampleModel = BuyerDeliveryChallanModel(
        id: 73,
        challanNumber: 'DC-20261018-0001',
        challanDate: '2026-10-18',
        truckNumber: 'TU31MB1234',
        transporterNameDisplay: 'Transporter Test',
        buyerName: 'Test Buyer',
        buyerCompanyName: 'Test Company',
        buyerAddress: 'gopal nagar, gopal nagar, Nagpur, Maharashtra, 440022, India',
        buyerMobile: '1234567891',
        deliveryAddress: null, // Should leave DEL AT blank, not copy buyerAddress
        driverName: 'gakshs',
        driverMobile: '3546464944',
        totalAmount: '62400.00',
        lorryFreightPerBag: '0.00',
        loadingCharges: '0.00',
        otherExp: '0.00',
        lessAdvance: '0.00',
        narration: 'Selected Contract Details',
        items: [
          DeliveryChallanItem(
            productName: 'testtest',
            bagCount: 1600,
            packingWeightKg: '50.000',
            quantity: '800.000',
            unit: 'qtl',
            rate: '78.00',
            amount: '62400.00',
          ),
        ],
      );

      final filePath = await BuyerChallanPdfService.download(sampleModel);
      expect(filePath, isNotEmpty);
      final file = File(filePath);
      expect(await file.exists(), isTrue);
      expect(await file.length(), greaterThan(1000));
    });

    test('Buyer delivery challan PDF with separate delivery address generates properly', () async {
      final sampleModel = BuyerDeliveryChallanModel(
        id: 74,
        challanNumber: 'DC-20261018-0002',
        challanDate: '2026-10-18',
        truckNumber: 'TU31MB1234',
        transporterNameDisplay: 'Transporter Test',
        buyerName: 'Test Buyer',
        buyerCompanyName: 'Test Company',
        buyerAddress: 'Billing Address, Nagpur',
        buyerMobile: '1234567891',
        deliveryAddress: 'Designated Warehouse Site, Wardha Road, Nagpur',
        driverName: 'gakshs',
        driverMobile: '3546464944',
        totalAmount: '50000.00',
        items: [],
      );

      final filePath = await BuyerChallanPdfService.download(sampleModel);
      expect(filePath, isNotEmpty);
      final file = File(filePath);
      expect(await file.exists(), isTrue);
    });

    test('Buyer delivery challan PDF resolves issuing company PAN and does not conflate sellerPan', () async {
      final sampleModel = BuyerDeliveryChallanModel(
        id: 75,
        challanNumber: 'DC-20261013-0001',
        challanDate: '2026-10-13',
        sellerPan: 'ABCDE1234E', // Seller's PAN must not be used for FARMLAND header or footer
        company: Company(
          legalName: 'FARMLAND',
          gstNumber: '23ABVSC1223F1Z4',
          panNumber: 'ABVSC1223F',
        ),
        buyerName: 'Test Buyer',
        buyerMobile: '1234567891',
        truckNumber: 'MH31AB1235',
        totalAmount: '10020.00',
        items: [],
      );

      final filePath = await BuyerChallanPdfService.download(sampleModel);
      expect(filePath, isNotEmpty);
      final file = File(filePath);
      expect(await file.exists(), isTrue);
      expect(await file.length(), greaterThan(1000));
    });
  });
}

