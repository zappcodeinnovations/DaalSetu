import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Create Brokerage Bill Line Rate UI Tests', () {
    testWidgets('Line brokerage rate input has clean label, no counter text, and length limiting formatter', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Line brokerage rate (optional)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(10),
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    decoration: const InputDecoration(
                      hintText: 'Enter line rate',
                      filled: true,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Verify label is cleanly rendered above the input
      expect(find.text('Line brokerage rate (optional)'), findsOneWidget);
      expect(find.text('Enter line rate'), findsOneWidget);

      // Verify there is NO counter text (such as "0/10" or "1/10")
      expect(find.text('0/10'), findsNothing);
      expect(find.text('1/10'), findsNothing);

      // Test typing input
      await tester.enterText(find.byType(TextFormField), '15.50');
      await tester.pump();

      expect(controller.text, '15.50');
      expect(find.text('5/10'), findsNothing); // Counter must remain absent
    });
  });
}
