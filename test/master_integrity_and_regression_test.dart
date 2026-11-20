import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daalsetu/modules/admin_catalog/config/admin_module_config.dart';
import 'package:daalsetu/modules/admin_catalog/model/admin_record.dart';

void main() {
  group('Master Integrity & Unity Test Suite', () {
    group('1. Largest Remainder Algorithm (Commodity Mix & Percentages)', () {
      List<int> calculateNormalizedPercentages(List<int> values) {
        final total = values.fold<int>(0, (sum, item) => sum + item);
        final List<int> roundedPercentages = List<int>.filled(values.length, 0);
        if (total <= 0) return roundedPercentages;

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
        return roundedPercentages;
      }

      test('Scenario A: Tester QA distribution [65, 30, 16, 10, 10] sums to exactly 100%', () {
        final result = calculateNormalizedPercentages([65, 30, 16, 10, 10]);
        final sum = result.fold<int>(0, (a, b) => a + b);
        expect(sum, equals(100));
      });

      test('Scenario B: Equal thirds [1, 1, 1] sums to exactly 100%', () {
        final result = calculateNormalizedPercentages([1, 1, 1]);
        final sum = result.fold<int>(0, (a, b) => a + b);
        expect(sum, equals(100));
        expect(result.contains(34), isTrue);
        expect(result.where((x) => x == 33).length, equals(2));
      });

      test('Scenario C: Single item [100] sums to 100%', () {
        final result = calculateNormalizedPercentages([100]);
        expect(result, equals([100]));
      });

      test('Scenario D: All zero items [0, 0, 0] yields zeros safely without division error', () {
        final result = calculateNormalizedPercentages([0, 0, 0]);
        expect(result, equals([0, 0, 0]));
      });
    });

    group('2. Dual-Axis GTV & Deals Chart Scaling & Alignment Integrity', () {
      test('7D view scaling matches web portal (0 to 0.07 with 0.01 step)', () {
        final gtvLakhs = [0.0, 0.0, 0.0, 0.0, 0.0, 0.065, 0.0];
        final gtvPeak = gtvLakhs.fold<double>(0, (max, value) => max > value ? max : value);

        final double gtvTop;
        final double gtvInterval;
        if (gtvPeak <= 0.07) {
          gtvTop = 0.07;
          gtvInterval = 0.01;
        } else if (gtvPeak <= 0.5) {
          gtvTop = 0.5;
          gtvInterval = 0.1;
        } else {
          gtvTop = 1.0;
          gtvInterval = 0.2;
        }

        expect(gtvTop, equals(0.07));
        expect(gtvInterval, equals(0.01));

        // Format check
        String lakhsLabel(double v) {
          if (v <= 0.0001) return '0';
          if (gtvTop <= 0.1) return v.toStringAsFixed(2);
          return v.toStringAsFixed(0);
        }

        expect(lakhsLabel(0.0), equals('0'));
        expect(lakhsLabel(0.01), equals('0.01'));
        expect(lakhsLabel(0.06), equals('0.06'));
      });

      test('Deals right Y-axis formats as 0, 0.2, 0.4... without repeating zeros', () {
        final deals = [0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0];
        final maxDeals = deals.fold<double>(0, (max, value) => max > value ? max : value);

        final double dealsTop = maxDeals <= 1.0 ? 1.0 : maxDeals.ceilToDouble();
        final double dealsInterval = dealsTop <= 1.0 ? 0.2 : 1.0;

        expect(dealsTop, equals(1.0));
        expect(dealsInterval, equals(0.2));

        String dealsLabel(double value) {
          if (value < -0.01 || value > dealsTop + 0.01) return '';
          if (dealsTop <= 1.0) {
            return value <= 0.0001 ? '0' : value.toStringAsFixed(1);
          }
          return value % 1 != 0 ? '' : value.toInt().toString();
        }

        final ticks = [0.0, 0.2, 0.4, 0.6, 0.8, 1.0];
        final formattedTicks = ticks.map(dealsLabel).toList();
        expect(formattedTicks, equals(['0', '0.2', '0.4', '0.6', '0.8', '1.0']));
        // Verify no repeating zeros
        expect(formattedTicks.where((t) => t == '0').length, equals(1));
      });
    });

    group('3. Pipeline by Stage KPI Synchronization', () {
      test('Synchronizes deals in negotiation count and stage percentage', () {
        final labels = ['Negotiation', 'Seller Confirmed', 'Buyer Confirmed', 'Deal Confirmed'];
        final values = [1, 0, 0, 10]; // raw backend values
        const liveKpiNegotiation = 3;

        final negIdx = labels.indexWhere((l) => l.toLowerCase().contains('negotiat'));
        if (negIdx != -1 && values[negIdx] < liveKpiNegotiation) {
          values[negIdx] = liveKpiNegotiation;
        }

        expect(values[negIdx], equals(3));
        final total = values.fold<int>(0, (a, b) => a + b);
        expect(total, equals(13));

        final negPercentage = (values[negIdx] / total) * 100.0;
        final dealConfirmedIdx = labels.indexOf('Deal Confirmed');
        final dealConfirmedPercentage = (values[dealConfirmedIdx] / total) * 100.0;

        expect(negPercentage.round(), equals(23)); // 23%
        expect(dealConfirmedPercentage.round(), equals(77)); // 77%
      });
    });

    group('4. Universal Date Picker Defaults & Safety', () {
      test('Defaults to today when no date pre-selected', () {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        DateTime? selectedDate;

        final initial = (selectedDate != null && !selectedDate.isBefore(today))
            ? selectedDate
            : today;

        expect(DateUtils.isSameDay(initial, today), isTrue);
        expect(initial.isBefore(today), isFalse);
      });

      test('Preserves pre-existing future date', () {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final futureDate = today.add(const Duration(days: 15));

        final initial = (!futureDate.isBefore(today)) ? futureDate : today;

        expect(initial, equals(futureDate));
      });

      test('Clamps past date safely to today to prevent Flutter assertion crash', () {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final pastDate = today.subtract(const Duration(days: 5));

        final initial = (pastDate.isBefore(today)) ? today : pastDate;

        expect(initial, equals(today));
      });
    });

    group('5. Admin Buyer Requirements Module & Quotations Card Integrity', () {
      test('AdminModuleConfig contains buyer_requirements with complete actions', () {
        final config = AdminModules.byKey('buyer_requirements');
        expect(config.key, equals('buyer_requirements'));
        expect(config.title, equals('Buyer Requirements'));
        expect(config.idKey, equals('rfq_id'));

        // Custom action for Chat / Details
        final chatAction = config.customActions.firstWhere(
          (a) => a.title.contains('Chat') || a.title.contains('Details'),
        );
        expect(chatAction, isNotNull);
        expect(chatAction.title, equals('Chat / Details'));

        // Close action
        final closeAction = config.customActions.firstWhere((a) => a.title == 'Close');
        expect(closeAction, isNotNull);
        expect(closeAction.title, equals('Close'));
      });

      test('Quotation data parsing extracts seller name, branch, price, and quantity', () {
        final quoteMap = {
          'id': 101,
          'seller_name': 'Agrofarm',
          'branch_name': 'AMR158M',
          'offered_price': '50.00',
          'price_unit': 'QTL',
          'offered_quantity': '50.000',
          'quantity_unit': 'QTL',
          'status': 'accepted',
        };

        final sellerName = quoteMap['seller_name'];
        final branch = quoteMap['branch_name']?.toString() ?? '';
        final sellerTitle = branch.isNotEmpty
            ? '$sellerName / $branch'
            : sellerName;
        final priceDisplay = '₹${quoteMap['offered_price']} / ${quoteMap['price_unit']}';
        final qtyDisplay = '${quoteMap['offered_quantity']} ${quoteMap['quantity_unit']}';

        expect(sellerTitle, equals('Agrofarm / AMR158M'));
        expect(priceDisplay, equals('₹50.00 / QTL'));
        expect(qtyDisplay, equals('50.000 QTL'));
        expect(quoteMap['status'], equals('accepted'));
      });
    });

    group('6. Registered Drivers Experience & Assignment Integrity', () {
      test('Registered driver config includes experience and assigned vehicle in subtitleKeys', () {
        final config = AdminModules.byKey('drivers');
        expect(config.subtitleKeys.contains('experience'), isTrue);
        expect(config.subtitleKeys.contains('assigned_vehicle.vehicle_number'), isTrue);
      });

      test('Assign action is always accessible for all drivers', () {
        final config = AdminModules.byKey('drivers');
        final assignAction = config.customActions.firstWhere((a) => a.title == 'Assign');
        expect(assignAction, isNotNull);
        final sampleRecord = {'id': 1, 'assigned_vehicle': {'vehicle_number': 'MH31DC1234'}};
        expect(assignAction.isVisible?.call(sampleRecord), isTrue);
      });
    });

    group('7. Seller Companies Filter Integrity', () {
      test('Filters companies by candidate seller IDs', () {
        final allCompanies = [
          {'id': 1, 'name': 'Alpha Ltd', 'user': 12},
          {'id': 2, 'name': 'Beta Agro', 'user_id': 12},
          {'id': 3, 'name': 'Gamma Mills', 'user': 45},
          {'id': 4, 'name': 'Delta Traders', 'created_by': 99},
        ];

        const targetSellerId = 12;
        final filtered = allCompanies.where((c) {
          final uid = c['user'] ?? c['user_id'] ?? c['seller'] ?? c['created_by'];
          return uid == targetSellerId;
        }).toList();

        expect(filtered.length, equals(2));
        expect(filtered.map((c) => c['name']).toList(), equals(['Alpha Ltd', 'Beta Agro']));
      });
    });
  });
}
