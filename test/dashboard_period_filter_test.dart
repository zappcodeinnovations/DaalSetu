import 'package:daalsetu/utils/dashboard_filter.dart';
import 'package:daalsetu/widgets/dashboard_period_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(DashboardFilter.clear);

  test('the filter is added to every dashboard request in the API vocabulary', () {
    expect(DashboardFilter.apply('/api/seller/dashboard/'), '/api/seller/dashboard/');
    DashboardFilter.set(const DashboardFilterValue(period: 'this_month'));
    expect(DashboardFilter.apply('/api/seller/dashboard/'), '/api/seller/dashboard/?period=this_month');
    DashboardFilter.set(const DashboardFilterValue(month: '2026-10'));
    expect(DashboardFilter.apply('/api/buyer/dashboard/?range=7D'), '/api/buyer/dashboard/?range=7D&month=2026-10');
    DashboardFilter.set(DashboardFilterValue(from: DateTime(2026, 11, 1), to: DateTime(2026, 11, 19)));
    expect(
      DashboardFilter.apply('/api/admin/dashboard/?period=7d&timeframe=7d'),
      '/api/admin/dashboard/?timeframe=7d&date_from=2026-11-01&date_to=2026-11-19',
    );
  });

  test('labels are readable, dates dd/mm/yyyy', () {
    expect(DashboardFilterValue.none.label, 'All time');
    expect(const DashboardFilterValue(period: 'last_30_days').label, 'Last 30 days');
    expect(const DashboardFilterValue(month: '2026-10').label, 'October 2026');
    expect(DashboardFilterValue(from: DateTime(2026, 11, 1), to: DateTime(2026, 11, 19)).label, '01/11/2026 - 19/11/2026');
  });

  testWidgets('the bar shows the period, changing it reloads once, clearing reloads again', (tester) async {
    var reloads = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: DashboardPeriodBar(onChanged: () => reloads++))));
    expect(find.text('All time'), findsOneWidget);

    await tester.tap(find.text('Change'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Last 7 days'));
    await tester.pumpAndSettle();
    expect(DashboardFilter.current.value.period, 'last_7_days');
    expect(find.text('Last 7 days'), findsOneWidget);
    expect(reloads, 1);

    await tester.tap(find.byTooltip('Clear the filter'));
    await tester.pumpAndSettle();
    expect(DashboardFilter.current.value.isActive, isFalse);
    expect(reloads, 2);
  });
}
