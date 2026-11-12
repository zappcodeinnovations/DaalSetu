import 'package:daalsetu/modules/buyer/dashboard/controller/buyer_dashboard_controller.dart';
import 'package:daalsetu/modules/buyer/dashboard/view/buyer_dashboard_analytics.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _charts() => {
  'trend': {
    '7D': {
      'labels': ['Tue', 'Fri', 'Sat'],
      'spend': [1.0, 1.5, 2.0],
      'orders': [1, 2, 3],
    },
    '1M': {
      'labels': ['Wk 40', 'Wk 41'],
      'spend': [1.8, 2.5],
      'orders': [2, 5],
    },
    '3M': {
      'labels': ['Aug', 'Sep', 'Oct'],
      'spend': [1.0, 2.0, 3.0],
      'orders': [1, 2, 4],
    },
    '1Y': {
      'labels': ['Jan', 'Oct'],
      'spend': [2.0, 4.0],
      'orders': [3, 6],
    },
  },
  'suppliers': {
    'labels': ['1234567890'],
    'spend': [2.5],
  },
  'commodity_mix': {
    'labels': ['Polished', 'Chilka'],
    'volume': [174, 50.1],
  },
  'order_status': {
    'labels': ['Interested', 'Deal Confirmed'],
    'counts': [2, 1],
  },
  'transport': {
    'labels': ['In Transit', 'Delivered'],
    'counts': [1, 2],
  },
};

void main() {
  testWidgets('buyer analytics uses web-parity chart types and all labels', (
    tester,
  ) async {
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: BuyerDashboardAnalytics(
              charts: _charts(),
              transportTracking: const [],
              onRangeChanged: (value) => selected = value,
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('buyer-spend-orders-bars')), findsOneWidget);
    expect(find.byKey(const Key('buyer-spend-trend-line')), findsOneWidget);
    expect(find.byType(BarChart), findsOneWidget);
    expect(find.byType(LineChart), findsOneWidget);
    expect(
      find.byKey(const Key('buyer-commodity-polar-chart')),
      findsOneWidget,
    );
    expect(find.text('Supplier Spend (Top)'), findsOneWidget);
    expect(find.text('Commodity Mix (Volume)'), findsOneWidget);
    expect(find.text('Tue'), findsOneWidget);
    expect(find.text('Fri'), findsOneWidget);
    expect(find.text('Sat'), findsOneWidget);

    await tester.tap(find.text('1M'));
    await tester.pump();

    expect(selected, '1M');
    expect(find.text('Wk 40'), findsOneWidget);
    expect(find.text('Wk 41'), findsOneWidget);
  });

  test('range selection reloads every dashboard chart dataset', () async {
    final requestedRanges = <String?>[];
    final controller = BuyerDashboardController(
      categoryLoader: () async => [],
      dashboardLoader: ({range}) async {
        requestedRanges.add(range);
        return {
          'kpis': {'avg_price': '₹260.00/qtl'},
          'charts': {
            'active_range': range,
            'suppliers': {
              'labels': ['Supplier $range'],
              'spend': [2.5],
            },
            'commodity_mix': {
              'labels': ['Commodity $range'],
              'volume': [10],
            },
            'order_status': {
              'labels': ['Confirmed'],
              'counts': [1],
            },
            'transport': {
              'labels': ['Delivered'],
              'counts': [1],
            },
          },
          'recent_rfqs': [],
          'recent_orders': [],
          'transport_tracking': [],
        };
      },
    );

    await controller.setRange('3M');

    expect(requestedRanges, ['3M']);
    expect(controller.selectedRange.value, '3M');
    expect(controller.dashboardData.value?.charts['active_range'], '3M');
    expect(controller.dashboardData.value?.charts['commodity_mix']['labels'], [
      'Commodity 3M',
    ]);
  });
}
