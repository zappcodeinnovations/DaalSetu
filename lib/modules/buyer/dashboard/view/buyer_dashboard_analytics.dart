import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../theme/glass_widgets.dart';

class BuyerDashboardAnalytics extends StatefulWidget {
  final Map<String, dynamic> charts;
  final List<dynamic> transportTracking;
  final String selectedRange;
  final bool isRangeLoading;
  final ValueChanged<String>? onRangeChanged;

  const BuyerDashboardAnalytics({
    super.key,
    required this.charts,
    required this.transportTracking,
    this.selectedRange = '7D',
    this.isRangeLoading = false,
    this.onRangeChanged,
  });

  @override
  State<BuyerDashboardAnalytics> createState() =>
      _BuyerDashboardAnalyticsState();
}

class _BuyerDashboardAnalyticsState extends State<BuyerDashboardAnalytics> {
  late String _range;

  @override
  void initState() {
    super.initState();
    _range = widget.selectedRange;
  }

  @override
  void didUpdateWidget(covariant BuyerDashboardAnalytics oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedRange != widget.selectedRange) {
      _range = widget.selectedRange;
    }
  }

  void _onSelectRange(String range) {
    setState(() => _range = range);
    widget.onRangeChanged?.call(range);
  }

  _ChartData _dataFor(Map<dynamic, dynamic>? raw, String valueKey) {
    final labels = raw?['labels'];
    final values = raw?[valueKey];
    final cleanLabels = labels is List
        ? labels.map((e) => e.toString()).toList()
        : <String>[];
    final cleanValues = values is List
        ? values
              .map(
                (e) => e is num
                    ? e.toDouble()
                    : double.tryParse(e.toString()) ?? 0,
              )
              .toList()
        : <double>[];
    final length = cleanLabels.length < cleanValues.length
        ? cleanLabels.length
        : cleanValues.length;
    return _ChartData(
      cleanLabels.take(length).toList(),
      cleanValues.take(length).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trendMap = widget.charts['trend'] is Map
        ? Map<dynamic, dynamic>.from(widget.charts['trend'])
        : <dynamic, dynamic>{};
    final selectedTrend = trendMap[_range] is Map
        ? Map<dynamic, dynamic>.from(trendMap[_range])
        : <dynamic, dynamic>{};
    final spend = _dataFor(selectedTrend, 'spend');
    final orders = _dataFor(selectedTrend, 'orders');
    final suppliers = _dataFor(_map(widget.charts['suppliers']), 'spend');
    final commodities = _dataFor(
      _map(widget.charts['commodity_mix']),
      'volume',
    );
    final orderStatus = _dataFor(_map(widget.charts['order_status']), 'counts');
    final transportStatus = _dataFor(
      _map(widget.charts['transport']),
      'counts',
    );

    return Column(
      children: [
        _trendCard(context, spend, orders),
        const SizedBox(height: 14),
        _supplierSpendHorizontalCard(
          context,
          'Supplier Spend (Top)',
          suppliers,
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 600;
            final cards = [
              _commodityMixRadialCard(
                context,
                'Commodity Mix (Volume)',
                commodities,
              ),
              // Same colours, in the same label order, as the buyer web panel.
              _donutCard(context, 'Order Status', orderStatus, const [
                Color(0xFF3BAA4A),
                Color(0xFFFFC107),
                Color(0xFFF4B400),
                Color(0xFFEF4444),
              ]),
              _donutCard(context, 'Transport Status', transportStatus, const [
                Color(0xFFFFC107),
                Color(0xFFF4B400),
                Color(0xFF3BAA4A),
                Color(0xFFEF4444),
              ]),
            ];
            if (!wide) {
              return Column(
                children: [
                  cards[0],
                  const SizedBox(height: 14),
                  cards[1],
                  const SizedBox(height: 14),
                  cards[2],
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 12),
                Expanded(child: cards[1]),
                const SizedBox(width: 12),
                Expanded(child: cards[2]),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        _trackingCard(context),
      ],
    );
  }

  Map<dynamic, dynamic>? _map(dynamic value) =>
      value is Map ? Map<dynamic, dynamic>.from(value) : null;

  /// Combination chart for Spend & Orders Trend matching web panel:
  /// - Bars for Orders (Teal/Green #34D399 / #20B28C)
  /// - Line with dots and subtle area under curve for Spend (₹ Lakhs) (Amber/Orange #F59E0B)
  /// - Displaying all active intervals (interval: 1 so Tue, Fri, Sat are all shown)
  Widget _trendCard(BuildContext context, _ChartData spend, _ChartData orders) {
    final hasData = spend.values.isNotEmpty || orders.values.isNotEmpty;
    final labels = spend.labels.isNotEmpty ? spend.labels : orders.labels;
    final count = labels.length;

    // Web panel y-axis for Spend is roughly 0.0 to 2.0 (left axis),
    // and Orders is 0 to 3.0 (right axis).
    double maxSpend = spend.values.fold<double>(
      0,
      (max, value) => value > max ? value : max,
    );
    double maxOrder = orders.values.fold<double>(
      0,
      (max, value) => value > max ? value : max,
    );
    if (maxSpend <= 0) maxSpend = 2.0;
    if (maxOrder <= 0) maxOrder = 3.0;

    // Ceil / round nicely
    // Round axes like the web chart: Spend 0..12 step 2, Orders 0..4 step 1
    // (x1.15 gave labels such as 8.2 / 13.7 and 0.8 / 2.3).
    final spendStep = _niceStep(maxSpend / 6);
    final spendMaxY = (maxSpend / spendStep).ceil() * spendStep;
    final ordersStep = _niceStep(maxOrder / 4);
    final ordersMaxY = (maxOrder / ordersStep).ceil() * ordersStep;
    // The Spend axis is drawn on the bar chart's Orders scale: one Spend step there.
    final spendStepOnBars = ordersMaxY * spendStep / spendMaxY;

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Spend & Orders Trend',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              for (final range in const ['7D', '1M', '3M', '1Y'])
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: InkWell(
                    onTap: () => _onSelectRange(range),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _range == range
                            ? const Color(0xFFF59E0B)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _range == range
                              ? const Color(0xFFF59E0B)
                              : Colors.grey.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        range,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _range == range ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (!hasData)
            const SizedBox(
              height: 180,
              child: Center(child: Text('No trend data available.')),
            )
          else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFF59E0B),
                          width: 2.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'Spend (₹ Lakhs)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 18),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFF34D399),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'Orders',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 190,
              child: Stack(
                children: [
                  // Layer 1: Bar chart for Orders
                  BarChart(
                    key: const Key('buyer-spend-orders-bars'),
                    BarChartData(
                      minY: 0,
                      maxY: ordersMaxY,
                      alignment: BarChartAlignment.spaceAround,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: spendStepOnBars,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.black.withValues(alpha: 0.04),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          axisNameWidget: const Padding(
                            padding: EdgeInsets.only(bottom: 2),
                            child: Text(
                              '₹ Lakhs',
                              style: TextStyle(fontSize: 8, color: Colors.grey),
                            ),
                          ),
                          axisNameSize: 12,
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            interval: spendStepOnBars,
                            getTitlesWidget: (value, _) {
                              // Spend value at this height of the Orders-scaled bar chart.
                              final spendEquiv = double.parse(
                                ((value / ordersMaxY) * spendMaxY).toStringAsFixed(2),
                              );
                              return Text(
                                spendEquiv == spendEquiv.roundToDouble()
                                    ? spendEquiv.toInt().toString()
                                    : spendEquiv.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                        ),
                        rightTitles: AxisTitles(
                          axisNameWidget: const Padding(
                            padding: EdgeInsets.only(bottom: 2),
                            child: Text(
                              'Orders',
                              style: TextStyle(fontSize: 8, color: Colors.grey),
                            ),
                          ),
                          axisNameSize: 12,
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 24,
                            interval: ordersStep,
                            getTitlesWidget: (value, _) => Text(
                              value == value.roundToDouble()
                                  ? value.toInt().toString()
                                  : value.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 26,
                            interval: 1, // Ensure all intervals (Tue, Fri, Sat, Wk 41) display
                            getTitlesWidget: (value, _) {
                              final index = value.toInt();
                              if (index < 0 ||
                                  index >= labels.length ||
                                  index != value) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  labels[index],
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: [
                        for (var index = 0; index < count; index++)
                          BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: index < orders.values.length
                                    ? orders.values[index]
                                    : 0,
                                color: const Color(0xFF34D399),
                                width: count == 1 ? 120 : 28,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),

                  // Layer 2: Line chart overlay for Spend
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 28,
                      right: 24,
                      top: 12,
                      bottom: 26,
                    ),
                    child: LineChart(
                      key: const Key('buyer-spend-trend-line'),
                      LineChartData(
                        // Bars use spaceAround (centres at (i + 0.5) / count), so the line
                        // spans -0.5..count-0.5 to put each point over its bar.
                        minX: -0.5,
                        maxX: count - 0.5,
                        minY: 0,
                        maxY: spendMaxY,
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        titlesData: const FlTitlesData(
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: [
                              for (var index = 0;
                                  index < spend.values.length;
                                  index++)
                                FlSpot(index.toDouble(), spend.values[index]),
                            ],
                            isCurved: count > 2,
                            // Never dip below 0 between points (the web line stays at 0).
                            preventCurveOverShooting: true,
                            color: const Color(0xFFF59E0B),
                            barWidth: 2.8,
                            isStrokeCapRound: true,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, i) =>
                                  FlDotCirclePainter(
                                radius: 4,
                                color: const Color(0xFFF59E0B),
                                strokeWidth: 1.5,
                                strokeColor: Colors.white,
                              ),
                            ),
                            belowBarData: BarAreaData(
                              show: count > 1,
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (widget.isRangeLoading)
                    Positioned.fill(
                      child: Container(
                        color: Colors.white.withValues(alpha: 0.4),
                        child: const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Horizontal Bar Chart for Supplier Spend (Top) matching web panel:
  /// - Card title: "Supplier Spend (Top)"
  /// - Supplier name/mobile on y-axis (left)
  /// - Horizontal bar (Cyan/Sky #38BDF8)
  /// - Horizontal x-axis baseline scaled from 0 to 2.5 with ticks: 0, 0.5, 1.0, 1.5, 2.0, 2.5
  Widget _supplierSpendHorizontalCard(
    BuildContext context,
    String title,
    _ChartData data,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Supplier Spend (Top)',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          if (data.values.isEmpty)
            const SizedBox(
              height: 120,
              child: Center(child: Text('No supplier spend data.')),
            )
          else ...[
            LayoutBuilder(
              builder: (context, constraints) {
                final maxVal = data.values.fold<double>(
                  0,
                  (max, v) => v > max ? v : max,
                );
                // Round steps like the web chart (0, 2, 4 ... 14), not 0, 2.9, 5.9 ...
                // About 4 steps like the web (0, 5, 10, 15 for a max of ~12).
                final step = maxVal > 2.5 ? _niceStep(maxVal / 4) : 0.5;
                final axisMax = maxVal > 2.5 ? (maxVal / step).ceil() * step : 2.5;
                final ticks = [
                  for (var t = 0.0; t <= axisMax + step / 2; t += step) double.parse(t.toStringAsFixed(2)),
                ];

                return Column(
                  children: [
                    for (var i = 0; i < data.labels.length; i++) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 82,
                              child: Text(
                                data.labels[i],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SizedBox(
                                height: 74,
                                child: Stack(
                                  children: [
                                    // Grid lines for intervals (0, 0.5, 1.0, 1.5, 2.0, 2.5)
                                    Positioned.fill(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          for (var t = 0; t < ticks.length; t++)
                                            Container(
                                              width: 1,
                                              height: double.infinity,
                                              color: Colors.grey.withValues(
                                                alpha: 0.18,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    // Horizontal Bar
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: FractionallySizedBox(
                                        widthFactor: (data.values[i] / axisMax)
                                            .clamp(0.0, 1.0),
                                        child: Container(
                                          height: 52,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF38BDF8),
                                            borderRadius:
                                                const BorderRadius.horizontal(
                                              right: Radius.circular(6),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    // Baseline scale ticks
                    Row(
                      children: [
                        const SizedBox(width: 90), // Match label column width + gap
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              for (final tick in ticks)
                                Text(
                                  tick == tick.roundToDouble()
                                      ? tick.toInt().toString()
                                      : tick.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  /// Polar-area / Concentric Radial Chart for Commodity Mix (Volume) matching web panel:
  /// - Card title: "Commodity Mix (Volume)"
  /// - Concentric circular rings with scale (20, 40, 60 ... 180)
  /// - Arc fills representing volumes in vibrant amber/gold
  /// - Legend with commodity names and volume values
  Widget _commodityMixRadialCard(
    BuildContext context,
    String title,
    _ChartData data,
  ) {
    final hasData = data.values.any((value) => value > 0);
    // Same order as the web polar-area chart.
    final colors = const [
      Color(0xFFF4B400),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFF8B5CF6),
      Color(0xFF06B6D4),
      Color(0xFF64748B),
    ];

    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          if (!hasData)
            const SizedBox(height: 130, child: Center(child: Text('No data')))
          else
            Row(
              children: [
                SizedBox(
                  width: 125,
                  height: 125,
                  child: CustomPaint(
                    key: const Key('buyer-commodity-polar-chart'),
                    painter: _PolarAreaPainter(
                      values: data.values,
                      colors: colors,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    children: [
                      for (var index = 0; index < data.labels.length; index++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.5),
                          child: Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: colors[index % colors.length],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  data.labels[index],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ),
                              Text(
                                _number(data.values[index]),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _donutCard(
    BuildContext context,
    String title,
    _ChartData data,
    List<Color> colors,
  ) {
    final hasData = data.values.any((value) => value > 0);
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          if (!hasData)
            const SizedBox(height: 112, child: Center(child: Text('No data')))
          else
            Row(
              children: [
                SizedBox(
                  width: 94,
                  height: 94,
                  child: PieChart(
                    PieChartData(
                      centerSpaceRadius: 27,
                      sectionsSpace: 2,
                      sections: [
                        for (var index = 0; index < data.values.length; index++)
                          if (data.values[index] > 0)
                            PieChartSectionData(
                              value: data.values[index],
                              color: colors[index % colors.length],
                              title: '',
                              radius: 19,
                            ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    children: [
                      for (var index = 0; index < data.labels.length; index++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: colors[index % colors.length],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  data.labels[index],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ),
                              Text(
                                _number(data.values[index]),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _trackingCard(BuildContext context) {
    final tracking = widget.transportTracking
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transport Tracking',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (tracking.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(child: Text('No transport tracking available.')),
            )
          else
            ...tracking.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.local_shipping_outlined),
                title: Text(
                  '${item['contract'] ?? '-'} • ${item['route'] ?? '-'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  'Transporter: ${item['transporter'] ?? '-'} • ${item['last_scan'] ?? '-'}',
                ),
                trailing: Text(
                  item['status']?.toString() ?? '-',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _number(num value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);
}

class _ChartData {
  final List<String> labels;
  final List<double> values;
  const _ChartData(this.labels, this.values);
}

/// Custom painter for web-matching polar-area / concentric radial volume chart
class _PolarAreaPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;

  _PolarAreaPainter({required this.values, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.45, size.height * 0.5);
    final maxRadius = math.min(size.width, size.height) * 0.46;

    final ringPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // Scale from the data (e.g. 500 ... 3,000) with radius linear in value, like
    // Chart.js polarArea; a fixed 0-180 scale clamped every large slice to full size.
    final maxValue = values.isEmpty ? 0.0 : values.reduce(math.max);
    final ringStep = maxValue > 0 ? _niceStep(maxValue / 6) : 20.0;
    final maxScale = maxValue > 0 ? (maxValue / ringStep).ceil() * ringStep : 180.0;
    final rings = [
      for (var r = ringStep; r <= maxScale + ringStep / 2; r += ringStep) r,
    ];

    // Draw concentric scale rings & labels
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (final ring in rings) {
      final r = (ring / maxScale) * maxRadius;
      canvas.drawCircle(center, r, ringPaint);

      textPainter.text = TextSpan(
        text: ring == ring.roundToDouble()
            ? NumberFormatShort.format(ring)
            : ring.toStringAsFixed(1),
        style: TextStyle(
          fontSize: 6.5,
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w500,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(center.dx - (textPainter.width / 2), center.dy - r - 1),
      );
    }

    if (values.isEmpty) return;

    // Draw polar area sectors
    final sectorAngle = (2 * math.pi) / values.length;
    for (var i = 0; i < values.length; i++) {
      final val = values[i];
      if (val <= 0) continue;
      final radius = ((val / maxScale).clamp(0.02, 1.0)) * maxRadius;
      final startAngle = -math.pi / 2 + (i * sectorAngle);

      final sectorPaint = Paint()
        ..color = colors[i % colors.length].withValues(alpha: 0.78)
        ..style = PaintingStyle.fill;

      final path = Path();
      path.moveTo(center.dx, center.dy);
      path.arcTo(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sectorAngle,
        false,
      );
      path.close();

      canvas.drawPath(path, sectorPaint);

      // Stroke outline for sector
      final borderPaint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawPath(path, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PolarAreaPainter oldDelegate) =>
      oldDelegate.values != values;
}

/// 1, 2, 2.5 or 5 x 10^n just above [raw]: axis steps like Chart.js picks.
double _niceStep(double raw) {
  if (raw <= 0) return 1;
  final magnitude = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
  for (final m in const [1.0, 2.0, 2.5, 5.0, 10.0]) {
    if (raw <= m * magnitude) return m * magnitude;
  }
  return 10 * magnitude;
}

/// Ring labels: "500", "1,000", "2,500".
class NumberFormatShort {
  static String format(double value) {
    final digits = value.toInt().toString();
    final out = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
      out.write(digits[i]);
    }
    return out.toString();
  }
}
