import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../theme/glass_widgets.dart';

class BuyerDashboardAnalytics extends StatefulWidget {
  final Map<String, dynamic> charts;
  final List<dynamic> transportTracking;

  const BuyerDashboardAnalytics({
    super.key,
    required this.charts,
    required this.transportTracking,
  });

  @override
  State<BuyerDashboardAnalytics> createState() =>
      _BuyerDashboardAnalyticsState();
}

class _BuyerDashboardAnalyticsState extends State<BuyerDashboardAnalytics> {
  String _range = '7D';

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
        _barCard(
          context,
          'Supplier Spend',
          '₹ Lakhs',
          suppliers,
          Colors.deepOrange,
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 600;
            final cards = [
              _donutCard(context, 'Commodity Mix', commodities, const [
                Colors.orange,
                Colors.teal,
                Colors.purple,
                Colors.blue,
                Colors.red,
              ]),
              _donutCard(context, 'Order Status', orderStatus, const [
                Colors.blue,
                Colors.orange,
                Colors.green,
                Colors.red,
              ]),
              _donutCard(context, 'Transport Status', transportStatus, const [
                Colors.amber,
                Colors.blue,
                Colors.green,
                Colors.red,
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

  Widget _trendCard(BuildContext context, _ChartData spend, _ChartData orders) {
    final hasData = spend.values.isNotEmpty || orders.values.isNotEmpty;
    final maxOrder = orders.values.fold<double>(
      0,
      (max, value) => value > max ? value : max,
    );
    final maxSpend = spend.values.fold<double>(
      0,
      (max, value) => value > max ? value : max,
    );
    final orderScale = maxOrder == 0 || maxSpend == 0 ? 1 : maxSpend / maxOrder;
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
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                ),
              ),
              for (final range in const ['7D', '1M', '3M', '1Y'])
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: ChoiceChip(
                    label: Text(range, style: const TextStyle(fontSize: 10)),
                    selected: _range == range,
                    onSelected: (_) => setState(() => _range = range),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (!hasData)
            const SizedBox(
              height: 170,
              child: Center(child: Text('No trend data available.')),
            )
          else ...[
            Row(
              children: const [
                _Legend(color: Colors.deepOrange, label: 'Spend (₹ Lakhs)'),
                SizedBox(width: 12),
                _Legend(color: Colors.blue, label: 'Orders'),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 160,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxSpend > 0 ? maxSpend / 4 : 1,
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: _titles(
                    context,
                    spend.labels.isNotEmpty ? spend.labels : orders.labels,
                  ),
                  lineBarsData: [
                    if (spend.values.isNotEmpty)
                      _line(spend.values, Colors.deepOrange),
                    if (orders.values.isNotEmpty)
                      _line(
                        orders.values
                            .map((value) => value * orderScale)
                            .toList(),
                        Colors.blue,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  LineChartBarData _line(List<double> values, Color color) => LineChartBarData(
    spots: [
      for (var index = 0; index < values.length; index++)
        FlSpot(index.toDouble(), values[index]),
    ],
    isCurved: true,
    color: color,
    barWidth: 3,
    dotData: const FlDotData(show: true),
  );

  Widget _barCard(
    BuildContext context,
    String title,
    String unit,
    _ChartData data,
    Color color,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
          Text(unit, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 10),
          if (data.values.isEmpty)
            const SizedBox(
              height: 150,
              child: Center(child: Text('No supplier spend data.')),
            )
          else
            SizedBox(
              height: 150,
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: _titles(context, data.labels),
                  barGroups: [
                    for (var index = 0; index < data.values.length; index++)
                      BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: data.values[index],
                            color: color,
                            width: 14,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
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

  FlTitlesData _titles(BuildContext context, List<String> labels) {
    final style = TextStyle(
      fontSize: 9,
      color: Theme.of(context).textTheme.bodySmall?.color,
    );
    return FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 28,
          getTitlesWidget: (value, _) => Text(_number(value), style: style),
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 24,
          getTitlesWidget: (value, _) {
            final index = value.toInt();
            if (index < 0 || index >= labels.length || index != value)
              return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                labels[index],
                style: style,
                overflow: TextOverflow.ellipsis,
              ),
            );
          },
        ),
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

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 10)),
    ],
  );
}
