import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// "4" for 4.0, "12.5" for 12.5 (never "4.0"): chart values are counts or amounts stored as doubles.
String chartValueLabel(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  final text = value.toStringAsFixed(2);
  return text.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
}

/// The tap tooltip of a bar chart, showing clean numbers. Without it fl_chart prints the raw double ("4.0").
BarTouchData cleanNumberBarTouch() => BarTouchData(
      touchTooltipData: BarTouchTooltipData(
        getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
          chartValueLabel(rod.toY),
          const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ),
    );
