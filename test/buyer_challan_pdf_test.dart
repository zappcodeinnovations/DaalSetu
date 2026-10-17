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

  test('Buyer delivery challan PDF generates without error', () async {
    final sampleModel = BuyerDeliveryChallanModel(
      id: 1,
      challanNumber: 'DC-20261017-001',
      challanDate: '2026-10-17',
      truckNumber: 'MH-31-AB-1234',
      transporterNameDisplay: 'Fast Cargo Transporters',
      buyerName: 'Rohit Enterprises',
      buyerAddress: 'Plot 45, MIDC Hingna Road, Nagpur, Maharashtra 440028',
      driverName: 'Ramesh Kumar',
      driverMobile: '9876543210',
      totalAmount: '150000.00',
      lorryFreightPerBag: '5000.00',
      loadingCharges: '1200.00',
      otherExp: '300.00',
      lessAdvance: '10000.00',
      narration: 'Prompt Delivery Requirement',
      items: [
        DeliveryChallanItem(
          productName: 'Chana Desi',
          bagCount: 100,
          packingWeightKg: '50',
          quantity: '50.000',
          unit: 'QTL',
          rate: '3000.00',
          amount: '150000.00',
        ),
      ],
    );

    // Call download with openShareSheet false to get the generated file path
    final filePath = await BuyerChallanPdfService.download(sampleModel);
    expect(filePath, isNotEmpty);
    final file = File(filePath);
    expect(await file.exists(), isTrue);
    expect(await file.length(), greaterThan(1000));
  });
}
