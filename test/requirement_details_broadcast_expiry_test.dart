import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:daalsetu/modules/buyer/offers/controller/buyer_offer_detail_controller.dart';
import 'package:daalsetu/modules/buyer/offers/view/buyer_offer_details_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockBuyerOfferDetailController extends BuyerOfferDetailController {
  final Map<String, dynamic> mockData;
  MockBuyerOfferDetailController(this.mockData) {
    isLoading.value = false;
    offerDetails.value = mockData;
  }

  @override
  Future<void> fetchDetails(
    int id, {
    bool silent = false,
    bool preferBuyerOffer = false,
    bool preferBuyerRequirement = false,
    int? productId,
    int? interestId,
  }) async {
    isLoading.value = false;
    offerDetails.value = mockData;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Broadcast Expiry Formatting Tests', () {
    test('formats ISO datetime with timezone into web format dd MMM yyyy, hh:mm a', () {
      final dt = DateTime.parse("2026-10-22T13:52:00+05:30").toLocal();
      final formatted = DateFormat('dd MMM yyyy, hh:mm a').format(dt);
      expect(formatted, contains('2026'));
      expect(formatted, contains('Oct'));
      expect(formatted, contains('22'));
    });

    test('formats standard ISO string matching web display exactly', () {
      final dt = DateTime(2026, 10, 22, 13, 52);
      final formatted = DateFormat('dd MMM yyyy, hh:mm a').format(dt);
      expect(formatted, '22 Oct 2026, 01:52 PM');
    });
  });

  group('Buyer Requirement Details Screen Tests', () {
    testWidgets('renders Broadcast Expiry row in Requirement Details view', (tester) async {
      final mockData = {
        'id': 101,
        'rfq_id': 'RFQ-20261022-0050',
        'title': 'Need 50 bags of chana - test',
        'category_name': 'URAD DAL',
        'brand_name': 'Organic Tattva',
        'description': 'Need 50 bags of chana - test',
        'buyer_name': 'Test Buyer',
        'required_quantity': '500.000',
        'quantity_unit': 'qtl',
        'target_price': '500.00',
        'price_unit': 'qtl',
        'required_bag_count': 10000,
        'packing_weight_kg': '5.000',
        'status': 'closed',
        'expiry_datetime': '2026-10-22T13:52:00+05:30',
      };
      Get.put<BuyerOfferDetailController>(MockBuyerOfferDetailController(mockData));

      await tester.pumpWidget(
        const GetMaterialApp(
          home: BuyerOfferDetailsView(
            offerId: 101,
            preferBuyerOffer: false,
            preferBuyerRequirement: true,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text("Requirement Details"), findsOneWidget);
      expect(find.text("Product Specifications"), findsOneWidget);
      expect(find.text("Pricing & Inventory"), findsOneWidget);
      expect(find.text("Broadcast Expiry"), findsOneWidget);

      Get.reset();
    });
  });
}
