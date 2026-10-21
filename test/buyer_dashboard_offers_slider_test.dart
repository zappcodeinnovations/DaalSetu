import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daalsetu/modules/buyer/dashboard/controller/buyer_dashboard_controller.dart';
import 'package:daalsetu/modules/buyer/dashboard/view/buyer_dashboard_view.dart';
import 'package:daalsetu/modules/buyer/offers/model/buyer_offer_model.dart';
import 'package:daalsetu/modules/profile/controller/profile_controller.dart';
import 'package:daalsetu/modules/buyer/offers/controller/buyer_offers_controller.dart';
import 'package:daalsetu/modules/products/view/product_detail.dart';
import 'package:daalsetu/modules/buyer/offers/view/buyer_offer_details_view.dart';

class MockProfileController extends ProfileController {}

class MockBuyerOffersController extends BuyerOffersController {
  MockBuyerOffersController({required super.offerType});

  @override
  Future<void> fetchOffers({bool isRefresh = false}) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.reset();
    Get.put<ProfileController>(MockProfileController());
    for (final tag in ['all', 'today', 'pending', 'previous']) {
      Get.put<BuyerOffersController>(
        MockBuyerOffersController(offerType: tag),
        tag: tag,
      );
    }
  });

  tearDown(() {
    Get.reset();
  });

  group('BuyerDashboardController.filterValidOffers', () {
    test('excludes out-of-stock items', () {
      final items = [
        {
          'id': 1,
          'title': 'Out of Stock Dal',
          'amount': '1500',
          'available_quantity': '0.000',
          'remaining_bag_count': 0,
          'status': 'out_of_stock',
        },
        {
          'id': 2,
          'title': 'Valid In Stock Dal',
          'amount': '2500',
          'available_quantity': '50.000',
          'status': 'active',
        },
      ];

      final filtered = BuyerDashboardController.filterValidOffers(items);
      expect(filtered.length, 1);
      expect(filtered.first.id, 2);
      expect(filtered.first.title, 'Valid In Stock Dal');
    });

    test('excludes expired deals', () {
      final items = [
        {
          'id': 10,
          'title': 'Expired Special Deal',
          'amount': '3000',
          'available_quantity': '100.000',
          'status': 'deal_expired',
          'is_expired': true,
        },
        {
          'id': 11,
          'title': 'Valid Active Deal',
          'amount': '3200',
          'available_quantity': '120.000',
          'status': 'active',
          'is_expired': false,
        },
      ];

      final filtered = BuyerDashboardController.filterValidOffers(items);
      expect(filtered.length, 1);
      expect(filtered.first.id, 11);
      expect(filtered.first.title, 'Valid Active Deal');
    });

    test('excludes deals whose expiry date has passed, whatever field or format', () {
      final now = DateTime.now();
      final past = now.subtract(const Duration(days: 2));
      final future = now.add(const Duration(days: 2));
      String dmy(DateTime d) =>
          '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
      Map<String, dynamic> offer(int id, Map<String, dynamic> expiry) => {
            'id': id,
            'title': 'Deal $id',
            'amount': '1000',
            'available_quantity': '10.000',
            'status': 'active',
            ...expiry,
          };

      final items = [
        offer(1, {'broadcast_expiry': past.toIso8601String()}),
        offer(2, {'expires_at': past.toUtc().toIso8601String()}),
        offer(3, {'deal_expiry_datetime': dmy(past)}),
        offer(4, {'rfq': {'expiry_datetime': past.toIso8601String()}}),
        offer(5, {'broadcast_expiry_datetime': future.toIso8601String()}),
        // A date without a time stays valid until the end of that day.
        offer(6, {'expiry_date': now.toIso8601String().substring(0, 10)}),
        offer(7, {}),
      ];

      final ids = BuyerDashboardController.filterValidOffers(items).map((o) => o.id);
      expect(ids, [5, 6, 7]);
    });

    test('drops a deal whose expiry passes after it was loaded', () {
      final offer = BuyerOfferModel(
        id: 30,
        title: 'Just Expired',
        status: 'active',
        isActive: true,
        expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
      );
      expect(offer.hasExpired, isTrue);
      expect(BuyerDashboardController.filterValidOffers([offer]), isEmpty);
    });

    test('excludes inactive and rejected items', () {
      final items = [
        {
          'id': 20,
          'title': 'Inactive Offer',
          'amount': '1000',
          'available_quantity': '10.000',
          'is_active': false,
          'status': 'inactive',
        },
        {
          'id': 21,
          'title': 'Rejected Offer',
          'amount': '1000',
          'available_quantity': '10.000',
          'status': 'rejected',
        },
        {
          'id': 22,
          'title': 'Clean Active Offer',
          'amount': '1000',
          'available_quantity': '10.000',
          'status': 'active',
          'is_active': true,
        },
      ];

      final filtered = BuyerDashboardController.filterValidOffers(items);
      expect(filtered.length, 1);
      expect(filtered.first.id, 22);
    });

    test('accepts BuyerOfferModel instances directly and deduplicates', () {
      final offer1 = BuyerOfferModel(
        id: 101,
        title: 'Chana Bold',
        requestedAmount: '4500',
        availableQuantity: '20.000',
        status: 'active',
        isActive: true,
      );
      final offer1Duplicate = BuyerOfferModel(
        id: 101,
        title: 'Chana Bold',
        requestedAmount: '4500',
        availableQuantity: '20.000',
        status: 'active',
        isActive: true,
      );
      final offer2 = BuyerOfferModel(
        id: 102,
        title: 'Moong Mogar',
        requestedAmount: '7200',
        availableQuantity: '15.000',
        status: 'active',
        isActive: true,
      );

      final filtered = BuyerDashboardController.filterValidOffers([
        offer1,
        offer1Duplicate,
        offer2,
      ]);
      expect(filtered.length, 2);
      expect(filtered[0].title, 'Chana Bold');
      expect(filtered[1].title, 'Moong Mogar');
    });
  });

  group('BuyerOffersCarouselSlider Widget', () {
    testWidgets('renders empty-state fallback when offers list is empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: BuyerOffersCarouselSlider(
                offers: const [],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('ACTIVE REQUIREMENTS & DEALS'), findsOneWidget);
      expect(find.text('Looking for Bulk Commodities?'), findsOneWidget);
      expect(find.text('Post Requirement'), findsOneWidget);
      expect(find.text('Browse Offers'), findsOneWidget);
    });

    testWidgets('renders single card when 1 valid offer is present', (
      tester,
    ) async {
      final singleOffer = BuyerOfferModel(
        id: 501,
        productId: 501,
        title: 'Premium Toor Dal',
        displayTitle: 'Premium Toor Dal',
        displayPrice: '₹8,400.00/QTL',
        displayQuantity: '25.000 QTL',
        status: 'active',
        isActive: true,
      );

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: BuyerOffersCarouselSlider(
                offers: [singleOffer],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('ACTIVE OFFER'), findsOneWidget);
      expect(find.text('Premium Toor Dal'), findsOneWidget);
      expect(find.text('₹8,400.00/QTL'), findsOneWidget);
      expect(find.text('Available: 25.000 QTL'), findsOneWidget);
      expect(find.text('View Details'), findsOneWidget);
      // No PageView for a single item
      expect(find.byType(PageView), findsNothing);
    });

    testWidgets(
      'renders carousel slider with PageView and dots for multiple offers',
      (tester) async {
        final offers = [
          BuyerOfferModel(
            id: 601,
            productId: 601,
            title: 'Chana Desi',
            displayTitle: 'Chana Desi',
            displayPrice: '₹5,100.00/QTL',
            displayQuantity: '40.000 QTL',
            status: 'active',
            isActive: true,
          ),
          BuyerOfferModel(
            id: 602,
            productId: 602,
            title: 'Urad White',
            displayTitle: 'Urad White',
            displayPrice: '₹7,800.00/QTL',
            displayQuantity: '15.000 QTL',
            status: 'active',
            isActive: true,
          ),
          BuyerOfferModel(
            id: 603,
            isRfq: true,
            title: 'Masoor Dal Bulk',
            displayTitle: 'Masoor Dal Bulk',
            displayPrice: '₹6,200.00/QTL',
            displayQuantity: '100.000 QTL',
            status: 'open',
            isActive: true,
          ),
        ];

        await tester.pumpWidget(
          GetMaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: BuyerOffersCarouselSlider(
                  offers: offers,
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        // PageView exists for multiple offers
        expect(find.byType(PageView), findsOneWidget);
        // First slide is displayed
        expect(find.text('Chana Desi'), findsOneWidget);
        expect(find.text('1 / 3'), findsOneWidget);
        expect(find.text('₹5,100.00/QTL'), findsOneWidget);

        // Swipe to next slide
        await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Second slide is now visible
        expect(find.text('Urad White'), findsOneWidget);
        expect(find.text('2 / 3'), findsOneWidget);
      },
    );

    testWidgets('tapping View Details navigates to ProductDetailScreen for product offer', (
      tester,
    ) async {
      final offer = BuyerOfferModel(
        id: 701,
        productId: 701,
        title: 'Kabuli Chana Dollar',
        displayTitle: 'Kabuli Chana Dollar',
        displayPrice: '₹11,000.00/QTL',
        displayQuantity: '30.000 QTL',
        status: 'active',
        isActive: true,
      );

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: BuyerOffersCarouselSlider(
                offers: [offer],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final viewDetailsFinder = find.text('View Details');
      expect(viewDetailsFinder, findsOneWidget);

      await tester.tap(viewDetailsFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(ProductDetailScreen), findsOneWidget);
    });

    testWidgets('tapping View Details navigates to BuyerOfferDetailsView for RFQ', (
      tester,
    ) async {
      final rfqOffer = BuyerOfferModel(
        id: 801,
        isRfq: true,
        title: 'Requirement for Moong Dal',
        displayTitle: 'Requirement for Moong Dal',
        displayPrice: '₹7,000.00/QTL',
        displayQuantity: '200.000 QTL',
        status: 'open',
        isActive: true,
      );

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: BuyerOffersCarouselSlider(
                offers: [rfqOffer],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final viewDetailsFinder = find.text('View Details');
      expect(viewDetailsFinder, findsOneWidget);

      await tester.tap(viewDetailsFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(BuyerOfferDetailsView), findsOneWidget);
    });
  });

  group('BuyerDashboardController offers loading integration', () {
    test('populates activeOffers from offersLoader while filtering out invalid deals', () async {
      final rawMockOffers = [
        {
          'id': 901,
          'title': 'Out of stock item',
          'amount': '1000',
          'available_quantity': '0.000',
          'status': 'out_of_stock',
        },
        {
          'id': 902,
          'title': 'Expired item',
          'amount': '2000',
          'available_quantity': '10.000',
          'status': 'deal_expired',
        },
        {
          'id': 903,
          'title': 'Valid Active Deal 1',
          'amount': '3000',
          'available_quantity': '50.000',
          'status': 'active',
          'is_active': true,
        },
        {
          'id': 904,
          'title': 'Valid Active Deal 2',
          'amount': '4000',
          'available_quantity': '80.000',
          'status': 'active',
          'is_active': true,
        },
      ];

      final controller = BuyerDashboardController(
        dashboardLoader: ({range}) async => {
          'kpis': {},
          'charts': {},
          'recent_rfqs': [],
          'recent_orders': [],
          'transport_tracking': [],
        },
        categoryLoader: () async => [],
        offersLoader: () async => rawMockOffers,
      );

      await controller.fetchDashboardData();

      expect(controller.activeOffers.length, 2);
      expect(controller.activeOffers[0].id, 903);
      expect(controller.activeOffers[0].title, 'Valid Active Deal 1');
      expect(controller.activeOffers[1].id, 904);
      expect(controller.activeOffers[1].title, 'Valid Active Deal 2');
    });
  });
}
