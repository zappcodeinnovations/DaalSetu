import 'package:flutter/foundation.dart';

import 'app_date.dart';

/// The dashboards' global date filter (same vocabulary as the web and the API):
/// `?period=today|yesterday|this_week|last_7_days|last_30_days|this_month|last_month|this_year`,
/// `?month=YYYY-MM` or `?date_from=YYYY-MM-DD&date_to=YYYY-MM-DD`. No filter = the dashboard's usual figures.
@immutable
class DashboardFilterValue {
  const DashboardFilterValue({this.period, this.month, this.from, this.to});

  final String? period;
  final String? month;
  final DateTime? from;
  final DateTime? to;

  static const none = DashboardFilterValue();

  bool get isActive => period != null || month != null || (from != null && to != null);

  /// Query parameters for the API.
  Map<String, String> get params {
    if (from != null && to != null) {
      return {'date_from': AppDate.apiDate(from!), 'date_to': AppDate.apiDate(to!)};
    }
    if (month != null) return {'month': month!};
    if (period != null) return {'period': period!};
    return const {};
  }

  String get label {
    if (from != null && to != null) return '${AppDate.fromDateTime(from!)} - ${AppDate.fromDateTime(to!)}';
    if (month != null) {
      final parts = month!.split('-');
      final monthNumber = parts.length == 2 ? int.tryParse(parts[1]) ?? 0 : 0;
      const names = [
        '', 'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December',
      ];
      return monthNumber >= 1 && monthNumber <= 12 ? '${names[monthNumber]} ${parts[0]}' : month!;
    }
    return quickRanges[period] ?? 'All time';
  }

  static const quickRanges = <String, String>{
    'today': 'Today',
    'yesterday': 'Yesterday',
    'this_week': 'This week',
    'last_7_days': 'Last 7 days',
    'last_30_days': 'Last 30 days',
    'this_month': 'This month',
    'last_month': 'Last month',
    'this_year': 'This year',
  };
}

/// One filter for all the dashboards of the app session; every dashboard request goes through [apply].
class DashboardFilter {
  DashboardFilter._();

  static final ValueNotifier<DashboardFilterValue> current = ValueNotifier(DashboardFilterValue.none);

  static void set(DashboardFilterValue value) => current.value = value;

  static void clear() => current.value = DashboardFilterValue.none;

  /// Adds the active filter to [endpoint]. The filter replaces a `period` already on the endpoint (the trend
  /// charts' own range keeps using `range` / `timeframe`).
  static String apply(String endpoint, {DashboardFilterValue? value}) {
    final filter = value ?? current.value;
    if (!filter.isActive) return endpoint;
    final uri = Uri.parse(endpoint);
    final query = Map<String, String>.from(uri.queryParameters)
      ..remove('period')
      ..remove('month')
      ..remove('date_from')
      ..remove('date_to')
      ..addAll(filter.params);
    return uri.replace(queryParameters: query).toString();
  }
}
