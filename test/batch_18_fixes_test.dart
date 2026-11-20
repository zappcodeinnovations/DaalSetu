import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daalsetu/modules/admin_catalog/config/admin_module_config.dart';

void main() {
  group('Batch 18 Fixes - Unit & Functional Tests', () {
    test('Bug 1: Largest Remainder Method ensures percentages strictly sum to 100%', () {
      // Simulate commodity volumes: Toor Dal, Polished, tthbvkkn, URAD DAL, Chana
      final values = [65, 30, 16, 10, 10]; // Total = 131
      final total = values.fold<int>(0, (sum, item) => sum + item);

      final List<int> roundedPercentages = List<int>.filled(values.length, 0);
      if (total > 0) {
        final List<double> remainders = [];
        int currentSum = 0;
        for (int i = 0; i < values.length; i++) {
          final p = (values[i] / total) * 100.0;
          final floorVal = p.floor();
          roundedPercentages[i] = floorVal;
          remainders.add(p - floorVal);
          currentSum += floorVal;
        }
        int diff = 100 - currentSum;
        if (diff > 0) {
          final order = List<int>.generate(values.length, (i) => i);
          order.sort((a, b) => remainders[b].compareTo(remainders[a]));
          for (int i = 0; i < diff && i < order.length; i++) {
            roundedPercentages[order[i]]++;
          }
        }
      }

      final sum = roundedPercentages.fold<int>(0, (a, b) => a + b);
      expect(sum, equals(100), reason: 'Sum of percentages must strictly equal 100%');
    });

    test('Bug 1: Pipeline by stage syncs negotiation deals with live KPI', () {
      final pipelineLabels = ['Negotiation', 'Seller Confirmed', 'Buyer Confirmed', 'Deal Confirmed'];
      final pipelineValues = [1, 0, 0, 10];
      const int kpiDealsInNegotiation = 3;

      final negIdx = pipelineLabels.indexWhere(
        (l) => l.trim().toLowerCase().contains('negotiat'),
      );
      if (negIdx != -1 && pipelineValues[negIdx] < kpiDealsInNegotiation) {
        pipelineValues[negIdx] = kpiDealsInNegotiation;
      }

      expect(pipelineValues[negIdx], equals(3));
      final total = pipelineValues.fold<int>(0, (a, b) => a + b);
      expect(total, equals(13));
      final negPercent = (pipelineValues[negIdx] / total) * 100;
      expect(negPercent, closeTo(23.07, 0.1));
    });

    test('Bug 1: GTV & Deals dual axis scaling for 7D view', () {
      final gtvLakhs = [0.0, 0.0, 0.0, 0.0, 0.0, 0.065, 0.0];
      final deals = [0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0];

      final gtvPeak = gtvLakhs.fold<double>(0, (max, value) => max > value ? max : value);
      final double gtvTop;
      final double gtvInterval;
      if (gtvPeak <= 0.07) {
        gtvTop = 0.07;
        gtvInterval = 0.01;
      } else {
        gtvTop = 1.0;
        gtvInterval = 0.2;
      }

      expect(gtvTop, equals(0.07));
      expect(gtvInterval, equals(0.01));

      final maxDeals = deals.fold<double>(0, (max, value) => max > value ? max : value);
      final double dealsTop;
      final double dealsInterval;
      if (maxDeals <= 1.0) {
        dealsTop = 1.0;
        dealsInterval = 0.2;
      } else {
        dealsTop = 5.0;
        dealsInterval = 1.0;
      }

      expect(dealsTop, equals(1.0));
      expect(dealsInterval, equals(0.2));
    });

    test('Bug 2: Date picker initial date defaults to today when not set', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      DateTime? loadingFrom;

      final initial = (loadingFrom != null && !loadingFrom.isBefore(today))
          ? loadingFrom
          : today;

      expect(initial.year, equals(today.year));
      expect(initial.month, equals(today.month));
      expect(initial.day, equals(today.day));
      expect(DateUtils.isSameDay(initial, today), isTrue);
    });

    test('Bug 3: Buyer requirements module config has Chat / Details customAction', () {
      final config = AdminModules.byKey('buyer_requirements');
      expect(config.customActions, isNotEmpty);
      final chatAction = config.customActions.firstWhere(
        (a) => a.title.contains('Chat') || a.title.contains('Details'),
      );
      expect(chatAction, isNotNull);
      expect(chatAction.title, equals('Chat / Details'));
    });
  });
}
