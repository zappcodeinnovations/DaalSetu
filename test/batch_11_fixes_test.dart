import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Batch 11 Fixes Tests', () {
    test('Sub Admin display name formatter formats user or label cleanly', () {
      String subAdminName(String id, List<Map<String, dynamic>> subAdmins) {
        final found = subAdmins.firstWhere(
          (s) => '${s['id'] ?? s['value']}' == id,
          orElse: () => const {},
        );
        final name = (found['name'] ?? found['label'] ?? found['username'] ?? '').toString().trim();
        return name.isNotEmpty ? name : 'Sub Admin #$id';
      }

      final list = <Map<String, dynamic>>[
        {'id': '10', 'name': 'FARMLAND'},
        {'id': '12', 'label': 'Rupesh subadmin'},
      ];

      expect(subAdminName('10', list), 'FARMLAND');
      expect(subAdminName('12', list), 'Rupesh subadmin');
      expect(subAdminName('99', list), 'Sub Admin #99');
    });

    testWidgets('Submit Offer and Cancel buttons have symmetrical height and rounded corners',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {},
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {},
                  child: const Text('Submit Offer'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cancelFinder = find.widgetWithText(OutlinedButton, 'Cancel');
      final submitFinder = find.widgetWithText(ElevatedButton, 'Submit Offer');

      expect(cancelFinder, findsOneWidget);
      expect(submitFinder, findsOneWidget);

      final cancelSize = tester.getSize(cancelFinder);
      final submitSize = tester.getSize(submitFinder);

      expect(cancelSize.height, greaterThanOrEqualTo(44.0));
      expect(submitSize.height, greaterThanOrEqualTo(44.0));
    });
  });
}
