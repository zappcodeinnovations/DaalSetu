import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daalsetu/modules/contracts/model/contract_details_model.dart';
import 'package:daalsetu/modules/contracts/services/contract_pdf.dart';
import 'package:daalsetu/modules/contracts/view/contract_details_view.dart';
import 'package:daalsetu/modules/contracts/controller/contract_controller.dart';
import 'package:daalsetu/modules/dashboard/model/dashboard_model.dart';
import 'package:daalsetu/modules/dashboard/view/dashboard_page.dart';
import 'package:daalsetu/modules/dashboard/controller/dashboard_controller.dart';
import 'package:daalsetu/routes/app_routes.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';

class _MockDashboardNavCtrl extends DashboardController {}

class _MockContractController extends ContractController {
  @override
  Future<void> fetchContractDetail(int id) async {
    isLoading.value = false;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  group('Bug 1 & Bug 2: Downloaded Contract PDF Deal Section Parity', () {
    test('buildContractPdf hides Interest ID, removes redundant Quantity, and includes deal metrics with units', () async {
      final sampleContract = ContractDetailModel.fromJson({
        'id': 101,
        'contract_id': 'JBC2611239663',
        'product_title': 'toor daal',
        'product_category': 'pukhraj',
        'interest_id': 193,
        'deal_quantity': '100.200',
        'quantity_unit': 'qtl',
        'deal_amount': '45.00',
        'amount_unit': 'qtl',
        'trade_value': '4509.00000',
        'buyer_offer_amount': '45.00',
        'buyer_required_quantity': '100.200',
        'seller_quantity': '100.200',
        'deal_date': '23/11/2026 14:13',
        'bag_count': 334,
        'packing_weight_kg': '30.000',
        'buyer_id': 166,
        'buyer_unique_id': 'BUY-20261105-F9PJ',
        'buyer_name': 'rajesh kumar',
        'buyer_company': 'Test company',
        'buyer_mobile': '1234567891',
        'buyer_email': 'athawalehiral@gmail.com',
        'buyer_gst': '22ABCDE1234E1ZA',
        'seller_id': 165,
        'seller_mapped_id': 'SEL7C2A76102D',
        'seller_name': 'Umesh Rathor',
        'seller_company': 'Agrotech',
        'seller_mobile': '1234567890',
        'seller_email': 'hiral4nov2004@gmail.com',
        'seller_gst': '22ABCDE1234U1ZF',
      });

      final doc = buildContractPdf(
        sampleContract,
        'JBC2611239663',
        deflate: (bytes) => bytes,
      );
      final bytes = await doc.save();
      final pdfString = String.fromCharCodes(bytes);

      // Verify Interest ID row is NOT present
      expect(pdfString.contains('Interest ID'), isFalse,
          reason: 'Internal Interest ID must not be exposed in downloaded contract PDF');

      // Verify Trade Value is present
      expect(pdfString.contains('Trade') && pdfString.contains('Value'), isTrue,
          reason: 'Trade Value row must be present in Deal section');
      expect(pdfString.contains('4509.00000'), isTrue,
          reason: 'Trade Value amount must be present in Deal section');

      // Verify Total Deal Price is present
      expect(pdfString.contains('Total') && pdfString.contains('Price'), isTrue,
          reason: 'Total Deal Price row must be present in Deal section');

      // Verify Bag Count is present
      expect(pdfString.contains('Bag') && pdfString.contains('Count'), isTrue,
          reason: 'Bag Count row must be present in Deal section');
      expect(pdfString.contains('334'), isTrue,
          reason: 'Bag Count value must be present in Deal section');

      // Verify Packing Weight is present
      expect(pdfString.contains('Packing') && pdfString.contains('Weight'), isTrue,
          reason: 'Packing Weight row must be present in Deal section');
      expect(pdfString.contains('30.000') && pdfString.contains('kg'), isTrue,
          reason: 'Packing Weight value must be present in Deal section');

      // Verify Buyer Required Qty and Seller Quantity have 'qtl' unit
      expect(pdfString.contains('100.200') && pdfString.contains('qtl'), isTrue,
          reason: 'Quantity values must include qtl unit in Deal section');
    });
  });

  group('Bug 3: Dashboard GTV & Deals Chart Tooltip Layering & Contrast', () {
    testWidgets('chart Stack places LineChart behind BarChart so touch tooltips draw on top of line', (tester) async {
      final controller = Get.put<DashboardController>(_MockDashboardNavCtrl());
      controller.selectedGtvPeriod.value = '1Y';

      final sample1Y = GtvDealsChart(
        labels: [
          'Dec 25', 'Jan 26', 'Feb 26', 'Mar 26', 'Apr 26', 'May 26',
          'Jun 26', 'Jul 26', 'Aug 26', 'Sep 26', 'Oct 26', 'Nov 26'
        ],
        gtvValues: List.filled(12, 10000.0),
        dealsValues: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return AdminDashboardScreen().buildWebGtvDealsChartForTesting(
                  context,
                  sample1Y,
                  controller,
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the chart Stack that contains BarChart and LineChart
      final stacks = find.byType(Stack);
      expect(stacks, findsWidgets);

      bool foundChartStack = false;
      for (final stackElement in stacks.evaluate()) {
        final stackWidget = stackElement.widget as Stack;
        final hasLineChart = stackWidget.children.any((c) =>
            c is Positioned && c.child is IgnorePointer && (c.child as IgnorePointer).child is LineChart);
        final hasBarChart = stackWidget.children.any((c) => c is BarChart);

        if (hasLineChart && hasBarChart) {
          foundChartStack = true;
          expect(hasLineChart && hasBarChart, isTrue,
              reason: 'BarChart and LineChart must be synchronized inside chart Stack');
          break;
        }
      }
      expect(foundChartStack, isTrue, reason: 'GTV & Deals chart Stack must be present');
    });
  });

  group('Bug 4: Dashboard Branches Card Route Mapping', () {
    testWidgets('tapping Branches card navigates to AppRoutes.adminModule("branches")', (tester) async {
      final controller = Get.put<DashboardController>(_MockDashboardNavCtrl());
      controller.isLoading.value = false;
      controller.dashboardData.value = DashboardModel.fromJson({
        'kpis': {
          'branches': 1,
          'admins_active': 1,
        },
      });

      String? navigatedRoute;
      await tester.pumpWidget(
        GetMaterialApp(
          home: AdminDashboardScreen(),
          onGenerateRoute: (settings) {
            navigatedRoute = settings.name;
            return MaterialPageRoute(builder: (_) => Container());
          },
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      final branchesCardFinder = find.text('Branches');
      final scrollableFinder = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(branchesCardFinder, 200, scrollable: scrollableFinder);
      expect(branchesCardFinder, findsOneWidget);

      await tester.tap(branchesCardFinder);
      await tester.pump(const Duration(milliseconds: 300));

      expect(navigatedRoute, equals(AppRoutes.adminModule('branches')),
          reason: 'Branches card on Dashboard must navigate to Branch Master (branches), not branch_requests');
    });
  });

  group('Bug 5: Contract Details Hides Internal DB Integer User IDs', () {
    testWidgets('displays public buyer and seller codes and hides internal database IDs', (tester) async {
      final controller = Get.put<ContractController>(_MockContractController());
      final sampleContract = ContractDetailModel.fromJson({
        'id': 0,
        'contract_id': 'JBC2611239663',
        'product_title': 'toor daal',
        'product_category': 'pukhraj',
        'deal_quantity': '100.200',
        'quantity_unit': 'qtl',
        'deal_amount': '45.00',
        'amount_unit': 'qtl',
        'trade_value': '4509.00000',
        'buyer_id': 166,
        'buyer_unique_id': 'BUY-20261105-F9PJ',
        'buyer_name': 'rajesh kumar',
        'buyer_company': 'Test company',
        'seller_id': 165,
        'seller_mapped_id': 'SEL7C2A76102D',
        'seller_name': 'Umesh Rathor',
        'seller_company': 'Agrotech',
      });
      controller.contractDetail.value = sampleContract;
      controller.isLoading.value = false;

      await tester.pumpWidget(
        const GetMaterialApp(
          home: ContractDetailScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final scrollableFinder = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(find.text('Buyer'), 200, scrollable: scrollableFinder);
      await tester.pump(const Duration(milliseconds: 300));

      // Buyer public code is visible as "ID: BUY-20261105-F9PJ"
      expect(find.text('ID: BUY-20261105-F9PJ'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Seller'), 200, scrollable: scrollableFinder);
      await tester.pump(const Duration(milliseconds: 300));

      // Seller public code is visible as "ID: SEL7C2A76102D"
      expect(find.text('ID: SEL7C2A76102D'), findsOneWidget);

      // Internal database integer ID strings must NOT be present
      expect(find.text('ID: 166 | BUY-20261105-F9PJ'), findsNothing,
          reason: 'Internal buyer user ID 166 must not be exposed');
      expect(find.text('ID: 165 | SEL7C2A76102D'), findsNothing,
          reason: 'Internal seller user ID 165 must not be exposed');
    });
  });
}
