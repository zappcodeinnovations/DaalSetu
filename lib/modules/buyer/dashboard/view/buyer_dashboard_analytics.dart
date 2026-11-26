import 'package:daalsetu/widgets/chart_tooltips.dart';
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

  Widget _buildAnalyticsEmptyState({
    required BuildContext context,
    required IconData icon,
    required String message,
    double height = 110,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      height: height,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE65100).withValues(alpha: isDark ? 0.15 : 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: const Color(0xFFE65100),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                          color: _range == range ? Colors.white : (isDark ? const Color(0xFFCBD5E1) : Colors.black87),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (!hasData)
            _buildAnalyticsEmptyState(
              context: context,
              icon: Icons.trending_up_rounded,
              message: 'No trend data available for this period',
              height: 140,
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
                      barTouchData: cleanNumberBarTouch(),
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
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isDark ? const Color(0xFFCBD5E1) : Colors.black87,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
            _buildAnalyticsEmptyState(
              context: context,
              icon: Icons.storefront_outlined,
              message: 'No supplier spend recorded for this period',
              height: 100,
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
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? const Color(0xFFCBD5E1) : Colors.black87,
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
                                    color: isDark ? const Color(0xFF94A3B8) : Colors.grey[600],
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
            _buildAnalyticsEmptyState(
              context: context,
              icon: Icons.pie_chart_outline_rounded,
              message: 'No commodity volume recorded yet',
              height: 100,
            )
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
            _buildAnalyticsEmptyState(
              context: context,
              icon: Icons.donut_large_rounded,
              message: 'No $title data recorded for this period',
              height: 95,
            )
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
                            valuePieSection(
                              value: data.values[index],
                              total: data.values.fold<double>(0, (a, b) => a + b),
                              color: colors[index % colors.length],
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tracking = widget.transportTracking
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Text(
            'Transport Tracking',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
        ),
        if (tracking.isEmpty)
          GlassCard(
            padding: const EdgeInsets.all(14),
            child: _buildAnalyticsEmptyState(
              context: context,
              icon: Icons.local_shipping_outlined,
              message: 'No active shipments to track',
              height: 80,
            ),
          )
        else
          ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tracking.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = tracking[index];
              final contract = (item['contract'] ?? '').toString().trim();
              final route = (item['route'] ?? '').toString().trim();
              final transporter = (item['transporter'] ?? '').toString().trim();
              final lastScan = (item['last_scan'] ?? '').toString().trim();
              final status = (item['status'] ?? 'Delivered').toString().trim();
              final statusLower = status.toLowerCase();

              Color statusColor = const Color(0xFF10B981); // Green Delivered
              Color statusBg = isDark
                  ? const Color(0xFF064E3B).withValues(alpha: 0.35)
                  : const Color(0xFFD1FAE5);

              if (statusLower.contains('transit')) {
                statusColor = const Color(0xFF3B82F6); // Blue
                statusBg = isDark
                    ? const Color(0xFF1E3A8A).withValues(alpha: 0.35)
                    : const Color(0xFFDBEAFE);
              } else if (statusLower.contains('pickup') ||
                  statusLower.contains('due') ||
                  statusLower.contains('pending')) {
                statusColor = const Color(0xFFF59E0B); // Amber
                statusBg = isDark
                    ? const Color(0xFF78350F).withValues(alpha: 0.35)
                    : const Color(0xFFFEF3C7);
              } else if (statusLower.contains('cancel') ||
                  statusLower.contains('delay')) {
                statusColor = const Color(0xFFEF4444); // Red
                statusBg = isDark
                    ? const Color(0xFF7F1D1D).withValues(alpha: 0.35)
                    : const Color(0xFFFEE2E2);
              }

              final headerTitle = [
                if (contract.isNotEmpty) contract,
                if (route.isNotEmpty) route,
              ].join(' • ');

              final subtitleText = [
                if (transporter.isNotEmpty) 'Transporter: $transporter',
                if (lastScan.isNotEmpty) lastScan,
              ].join(' • ');

              return GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.local_shipping_outlined,
                        size: 20,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  contract.isNotEmpty ? contract : 'Shipment Tracking',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.5,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                decoration: BoxDecoration(
                                  color: statusBg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: statusColor.withValues(alpha: 0.3),
                                    width: 0.8,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: statusColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      status,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: statusColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (route.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              route,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            subtitleText.isNotEmpty ? subtitleText : 'Status update pending',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.5,
                              color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
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
    // About four rings: six left their labels stacked on top of each other.
    final ringStep = maxValue > 0 ? _niceStep(maxValue / 4) : 20.0;
    final maxScale = maxValue > 0 ? (maxValue / ringStep).ceil() * ringStep : 180.0;
    final rings = [
      for (var r = ringStep; r <= maxScale + ringStep / 2; r += ringStep) r,
    ];

    // Concentric scale rings (labels are drawn after the sectors, on top).
    for (final ring in rings) {
      canvas.drawCircle(center, (ring / maxScale) * maxRadius, ringPaint);
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

      // The slice's own volume on it (the web shows the number on the chart point).
      final label = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(
          text: chartValueLabel(val),
          style: const TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            shadows: [Shadow(color: Colors.black54, blurRadius: 2)],
          ),
        ),
      )..layout();
      final mid = startAngle + sectorAngle / 2;
      final labelRadius = math.max(radius * 0.62, label.width * 0.75);
      if (radius > label.width * 0.9) {
        label.paint(
          canvas,
          Offset(
            center.dx + math.cos(mid) * labelRadius - label.width / 2,
            center.dy + math.sin(mid) * labelRadius - label.height / 2,
          ),
        );
      }
    }

    // Ring labels above the sectors on a light pill, skipping any that would
    // touch the previous one, so the numbers never overlap or hide.
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final pillPaint = Paint()..color = Colors.white.withValues(alpha: 0.85);
    double? lastTop;
    for (final ring in rings.reversed) {
      final r = (ring / maxScale) * maxRadius;
      textPainter.text = TextSpan(
        text: ring == ring.roundToDouble()
            ? NumberFormatShort.format(ring)
            : ring.toStringAsFixed(1),
        style: TextStyle(
          fontSize: 7,
          color: Colors.grey.shade800,
          fontWeight: FontWeight.w600,
        ),
      );
      textPainter.layout();
      final top = center.dy - r - textPainter.height / 2;
      if (lastTop != null && top < lastTop + textPainter.height + 2) continue;
      final offset = Offset(center.dx - textPainter.width / 2, top);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(offset.dx - 2, offset.dy, textPainter.width + 4, textPainter.height),
          const Radius.circular(3),
        ),
        pillPaint,
      );
      textPainter.paint(canvas, offset);
      lastTop = top;
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
