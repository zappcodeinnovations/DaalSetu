import 'dart:io';

import 'package:daalsetu/widgets/confirm_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// App-wide rule: in every dialog the primary action (Confirm / Yes / Save) comes first
/// (left or top) and Cancel comes second.
void main() {
  testWidgets('confirmActions puts the primary button before Cancel', (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Get.defaultDialog(
                title: 'Leave Branch',
                middleText: 'Are you sure?',
                actions: confirmActions(confirmText: 'YES, LEAVE', onConfirm: () {}),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final confirmPos = tester.getTopLeft(find.text('YES, LEAVE'));
    final cancelPos = tester.getTopLeft(find.text('CANCEL'));
    expect(confirmPos.dx, lessThan(cancelPos.dx));
  });

  testWidgets('confirmActions: both buttons are exactly the same size and Cancel is a boxed button', (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Get.defaultDialog(
                title: 'Accept buyer interest?',
                middleText: 'This will move the negotiation to the next step.',
                actions: confirmActions(confirmText: 'ACCEPT', onConfirm: () {}),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final confirm = tester.getSize(find.widgetWithText(FilledButton, 'ACCEPT'));
    final cancel = tester.getSize(find.widgetWithText(OutlinedButton, 'CANCEL'));
    expect(cancel, confirm);
    expect(confirm.height, greaterThanOrEqualTo(44));
    // Even gap between the two, not touching and not far apart.
    final gap = tester.getTopLeft(find.widgetWithText(OutlinedButton, 'CANCEL')).dx -
        tester.getTopRight(find.widgetWithText(FilledButton, 'ACCEPT')).dx;
    expect(gap, inInclusiveRange(8, 14));
  });

  test('no dialog in lib/ lists Cancel before its primary action', () {
    final offenders = <String>[];
    final listStart = RegExp(
      r'''actions:\s*\[\s*(?:const\s+)?(?:TextButton|OutlinedButton)\((?:(?!\bactions:)[\s\S]){0,500}?['"](?:Cancel|CANCEL)['"]''',
    );
    for (final file in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      final text = file.readAsStringSync();
      for (final match in listStart.allMatches(text)) {
        // A list holding only a Cancel/Close button is fine; flag lists with another button after it.
        final after = text.substring(match.end, (match.end + 700).clamp(0, text.length));
        final end = after.indexOf(']');
        final rest = end == -1 ? after : after.substring(0, end);
        if (RegExp(r'(FilledButton|ElevatedButton|TextButton|OutlinedButton)\(').hasMatch(rest)) {
          final line = '\n'.allMatches(text.substring(0, match.start)).length + 1;
          offenders.add('${file.path}:$line');
        }
      }
    }
    expect(offenders, isEmpty, reason: 'Put the primary action first, Cancel last:\n${offenders.join('\n')}');
  });
}
