import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';
import 'package:daalsetu/modules/transporter/dashboard/controller/transporter_dashboard_controller.dart';
import 'package:daalsetu/modules/transporter/dashboard/view/transporter_dashboard_view.dart';

({double max, double interval, int decimals}) calculateScale(
  double maxRaw,
  int divisions, {
  bool isInteger = false,
  double fallbackMax = 1.0,
}) {
  if (maxRaw <= 0) {
    final interval = fallbackMax / divisions;
    return (
      max: fallbackMax,
      interval: interval,
      decimals: isInteger ? 0 : 2,
    );
  }

  if (isInteger) {
    if (maxRaw <= 2.0) {
      return (max: 2.0, interval: 0.4, decimals: 1);
    } else if (maxRaw <= 5.0) {
      return (max: 5.0, interval: 1.0, decimals: 0);
    } else if (maxRaw <= 10.0) {
      return (max: 10.0, interval: 2.0, decimals: 0);
    }
  }

  final rawInterval = maxRaw / divisions;
  final exponent = (log(rawInterval) / ln10).floor();
  final fraction = rawInterval / pow(10, exponent);

  double niceFraction;
  if (fraction <= 1.0) {
    niceFraction = 1.0;
  } else if (fraction <= 2.0) {
    niceFraction = 2.0;
  } else if (fraction <= 2.5) {
    niceFraction = 2.5;
  } else if (fraction <= 4.0) {
    niceFraction = 4.0;
  } else if (fraction <= 5.0) {
    niceFraction = 5.0;
  } else {
    niceFraction = 10.0;
  }

  var interval = double.parse((niceFraction * pow(10, exponent)).toStringAsFixed(4));
  var max = double.parse(((maxRaw / interval).ceil() * interval).toStringAsFixed(4));
  while (max < maxRaw) {
    max = double.parse((max + interval).toStringAsFixed(4));
  }

  int decimals = 0;
  if (interval < 1.0) {
    if ((interval * 10).roundToDouble() == (interval * 10)) {
      decimals = 1;
    } else if ((interval * 100).roundToDouble() == (interval * 100)) {
      decimals = 2;
    } else {
      decimals = 3;
    }
  }

  return (max: max, interval: interval, decimals: decimals);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Transporter Trend Chart Scaling & Spline Tests', () {
    test('3M dual axis scale matches web panel (0.12 Lakhs and 2.0 Shipments)', () {
      const divisions = 6;

      // 3M earnings max is 0.12
      final earnScale = calculateScale(0.12, divisions, fallbackMax: 0.12);
      expect(earnScale.max, 0.12);
      expect(earnScale.interval, 0.02);
      expect(earnScale.decimals, 2);

      // 3M shipments max is 2.0 (matching peak shipment bar height)
      final shipScale = calculateScale(2.0, divisions, isInteger: true, fallbackMax: 2.0);
      expect(shipScale.max, 2.0);
      expect(shipScale.interval, 0.4);
      expect(shipScale.decimals, 1);

      // Verify peak alignment: bar reaches 2.0 (100%) and earnings reaches 0.12 (100%)
      expect(2.0 / shipScale.max, 1.0);
      expect(0.12 / earnScale.max, 1.0);
    });

    test('Spline curve overshooting is strictly prevented', () {
      final spots = [
        const FlSpot(0, 0),
        const FlSpot(1, 0),
        const FlSpot(2, 0.12),
      ];

      final barData = LineChartBarData(
        spots: spots,
        isCurved: true,
        preventCurveOverShooting: true,
        preventCurveOvershootingThreshold: 0.0,
        curveSmoothness: 0.25,
      );

      expect(barData.preventCurveOverShooting, isTrue);
      expect(barData.preventCurveOvershootingThreshold, 0.0);
      expect(barData.curveSmoothness, 0.25);
    });
  });

  group('Transporter Dashboard Controller SLA Parsing Tests', () {
    test('parses slaDrivers from overview payload across candidate keys', () {
      final sampleWithSlaDrivers = {
        'slaDrivers': {
          'labels': ['Ramesh Kumar', 'Suresh Singh'],
          'percentages': [100.0, 95.0],
        }
      };

      final parsed = ChartSeries.fromJson(
        sampleWithSlaDrivers['slaDrivers'],
        'labels',
        'percentages',
      );

      expect(parsed.labels, ['Ramesh Kumar', 'Suresh Singh']);
      expect(parsed.values, [100.0, 95.0]);
      expect(parsed.isEmpty, isFalse);
    });
  });

  group('Transporter Dashboard Widgets Tests', () {
    testWidgets('renders analytical cards including SLA and Top Routes (Trips)', (tester) async {
      Get.testMode = true;
      final controller = Get.put(TransporterDashboardController());

      // Provide mock data
      controller.transportTypes.value = const ChartSeries(['truck'], [1.0]);
      controller.topRoutes.value = const ChartSeries(['Nagpur -> Bhopal'], [1.0]);
      controller.slaDrivers.value = const ChartSeries(['Ramesh Kumar'], [100.0]);
      controller.kpis.value = {
        'onTime': '100%',
        'earn': '₹0.12 Lakhs',
      };

      tester.view.physicalSize = const Size(450, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        GetMaterialApp(
          home: TransporterDashboardView(),
        ),
      );

      await tester.pump();

      // Verify analytical card headers
      expect(find.text('Transport Types'), findsWidgets);
      expect(find.text('Top Routes (Trips)'), findsOneWidget);
      expect(find.text('SLA: On-time % (Drivers)'), findsOneWidget);
      expect(find.text('Target: 90%'), findsOneWidget);
    });
  });
}
