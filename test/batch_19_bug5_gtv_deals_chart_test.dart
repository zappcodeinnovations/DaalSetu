import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:daalsetu/modules/dashboard/controller/dashboard_controller.dart';
import 'package:daalsetu/modules/dashboard/model/dashboard_model.dart';
import 'package:daalsetu/modules/dashboard/view/dashboard_page.dart';
import 'package:get/get.dart';

class _MockDashboardController extends DashboardController {
  @override
  void onInit() {
    // Prevent real network call during widget testing
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

  group('Bug 3 / Screenshot 5: GTV & Deals Chart X-Axis Overlap and Right-Edge Separation', () {
    test('computeVisibleLabelIndices prevents date label overlap on 1Y (12 months)', () {
      // 12 monthly data points: Dec 25, Jan 26, Feb 26, Mar 26, Apr 26, May 26, Jun 26, Jul 26, Aug 26, Sep 26, Oct 26, Nov 26
      final indices = AdminDashboardScreen.computeVisibleLabelIndices(12);

      // Must downsample to 4-5 well-spaced milestones instead of 12 crowded labels
      expect(indices.length, inInclusiveRange(4, 5));

      // Must always include start (0) and end (11) for clear time span
      expect(indices.contains(0), isTrue);
      expect(indices.contains(11), isTrue);

      // Every adjacent visible index must have a separation of at least 2 steps (no adjacent index collision)
      final sorted = indices.toList()..sort();
      for (int i = 0; i < sorted.length - 1; i++) {
        final diff = sorted[i + 1] - sorted[i];
        expect(diff, greaterThanOrEqualTo(2),
            reason: 'Adjacent visible dates must be separated by >= 2 steps to avoid horizontal text overlap');
      }
    });

    test('computeVisibleLabelIndices preserves all points for 7D and 1M', () {
      // 7D view (7 days)
      final sevenDays = AdminDashboardScreen.computeVisibleLabelIndices(7);
      expect(sevenDays.length, equals(7));

      // 1M view (4 weeks)
      final fourWeeks = AdminDashboardScreen.computeVisibleLabelIndices(4);
      expect(fourWeeks.length, equals(4));
    });

    testWidgets('chart renders with right-axis breathing space and without label collision',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = Get.put<_MockDashboardController>(_MockDashboardController());
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

      // Find the BarChart widget
      final barChartFinder = find.byType(BarChart);
      expect(barChartFinder, findsOneWidget);

      final barChart = tester.widget<BarChart>(barChartFinder);
      final titlesData = barChart.data.titlesData;

      // Verify that rightTitles reservedSize has been increased to 38 for breathing space
      expect(titlesData.rightTitles.sideTitles.reservedSize, equals(38.0));

      // Verify that the LineChart mirror also has reservedSize 38 for pixel-perfect alignment
      final lineChartFinder = find.byType(LineChart);
      expect(lineChartFinder, findsOneWidget);
      final lineChart = tester.widget<LineChart>(lineChartFinder);
      expect(lineChart.data.titlesData.rightTitles.sideTitles.reservedSize, equals(38.0));

      // Verify bottom titles are downsampled and visible on screen without all 12 overlapping
      expect(find.text('Dec 25'), findsOneWidget);
      expect(find.text('Nov 26'), findsOneWidget);
      // Intermediate non-milestone labels like Jan 26 or Feb 26 are omitted to prevent overlap
      expect(find.text('Jan 26'), findsNothing);
      expect(find.text('Feb 26'), findsNothing);
    });
  });
}
