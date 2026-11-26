import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:daalsetu/modules/dashboard/controller/dashboard_controller.dart';
import 'package:daalsetu/modules/dashboard/model/dashboard_model.dart';
import 'package:daalsetu/modules/dashboard/view/dashboard_page.dart';
import 'package:get/get.dart';

class _MockDashboardController extends DashboardController {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  group('Bug 3 / Screenshot 5: GTV & Deals Chart X-Axis Overlap and Right-Edge Separation', () {
    testWidgets('chart renders with baseline right-axis layout and all period labels',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = Get.put<_MockDashboardController>(_MockDashboardController());
      controller.selectedGtvPeriod.value = '7D';

      final sample7D = GtvDealsChart(
        labels: [
          '20 Nov', '21 Nov', '22 Nov', '23 Nov', '24 Nov', '25 Nov', '26 Nov'
        ],
        gtvValues: List.filled(7, 10000.0),
        dealsValues: [2, 0, 0, 1, 0, 0, 2],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return AdminDashboardScreen().buildWebGtvDealsChartForTesting(
                  context,
                  sample7D,
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

      // Verify that rightTitles reservedSize is baseline 32
      expect(titlesData.rightTitles.sideTitles.reservedSize, equals(32.0));

      // Verify that the LineChart mirror also has reservedSize 32 for pixel-perfect alignment
      final lineChartFinder = find.byType(LineChart);
      expect(lineChartFinder, findsOneWidget);
      final lineChart = tester.widget<LineChart>(lineChartFinder);
      expect(lineChart.data.titlesData.rightTitles.sideTitles.reservedSize, equals(32.0));

      // Verify bottom titles are rendered directly
      expect(find.text('20 Nov'), findsOneWidget);
      expect(find.text('26 Nov'), findsOneWidget);
    });
  });
}
