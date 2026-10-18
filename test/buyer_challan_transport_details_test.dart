import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:daalsetu/modules/buyer/delivery_challan/controller/buyer_delivery_challan_controller.dart';
import 'package:daalsetu/modules/buyer/delivery_challan/model/buyer_delivery_challan_model.dart';
import 'package:daalsetu/modules/buyer/delivery_challan/view/buyer_delivery_challan_detail_view.dart';

class TestBuyerDeliveryChallanController extends BuyerDeliveryChallanController {
  @override
  void onInit() {
    super.onInit();
    // Skip network calls in widget tests
  }

  @override
  Future<void> fetchChallans({bool isRefresh = false}) async {
    // Skip network calls
  }

  @override
  Future<void> fetchChallanDetails(int challanId) async {
    // Skip network calls in widget test
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BuyerDeliveryChallan Transport Details Tests', () {
    late TestBuyerDeliveryChallanController controller;

    setUp(() {
      Get.reset();
      controller = Get.put<BuyerDeliveryChallanController>(TestBuyerDeliveryChallanController())
          as TestBuyerDeliveryChallanController;
    });

    tearDown(() {
      Get.reset();
    });

    test('BuyerDeliveryChallanModel.fromJson correctly parses driverLicenseNumber and fallbacks', () {
      final json1 = {
        'id': 73,
        'truck_number': 'TU31MB1234',
        'driver_name': 'gakshs',
        'driver_license_number': 'VSJSNSJSJ',
        'driver_mobile': '3546464944',
        'transporter_name_display': 'Transporter Test',
      };
      final m1 = BuyerDeliveryChallanModel.fromJson(json1);
      expect(m1.truckNumber, 'TU31MB1234');
      expect(m1.driverName, 'gakshs');
      expect(m1.driverLicenseNumber, 'VSJSNSJSJ');
      expect(m1.driverMobile, '3546464944');
      expect(m1.transporterNameDisplay, 'Transporter Test');

      // Test fallback to license_number
      final json2 = {
        'id': 74,
        'license_number': 'DL-998877',
      };
      final m2 = BuyerDeliveryChallanModel.fromJson(json2);
      expect(m2.driverLicenseNumber, 'DL-998877');

      // Test null string sanitization
      final json3 = {
        'id': 75,
        'driver_license_number': 'null',
        'driver_name': '  ',
      };
      final m3 = BuyerDeliveryChallanModel.fromJson(json3);
      expect(m3.driverLicenseNumber, isNull);
      expect(m3.driverName, isNull);
    });

    testWidgets('BuyerDeliveryChallanDetailView renders License Number field in Transport Details', (tester) async {
      final challan = BuyerDeliveryChallanModel(
        id: 73,
        challanNumber: 'DC-20261018-001',
        challanDate: '2026-10-18',
        truckNumber: 'TU31MB1234',
        driverName: 'gakshs',
        driverLicenseNumber: 'VSJSNSJSJ',
        driverMobile: '3546464944',
        transporterNameDisplay: 'Transporter Test',
        items: [],
      );

      controller.isDetailLoading.value = false;
      controller.currentChallan.value = challan;

      await tester.pumpWidget(
        GetMaterialApp(
          home: BuyerDeliveryChallanDetailView(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Transport Details'), findsOneWidget);
      expect(find.text('Truck No'), findsOneWidget);
      expect(find.text('TU31MB1234'), findsOneWidget);
      expect(find.text('Driver Name'), findsOneWidget);
      expect(find.text('gakshs'), findsOneWidget);
      expect(find.text('License Number'), findsOneWidget);
      expect(find.text('VSJSNSJSJ'), findsOneWidget);
      expect(find.text('Driver Mobile'), findsOneWidget);
      expect(find.text('3546464944'), findsOneWidget);
      expect(find.text('Transporter'), findsOneWidget);
      expect(find.text('Transporter Test'), findsOneWidget);
    });
  });
}
