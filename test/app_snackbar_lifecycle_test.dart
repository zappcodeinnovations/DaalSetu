import 'package:daalsetu/utils/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  tearDown(Get.reset);

  testWidgets(
    'rapid messages during navigation use an initialized native snackbar',
    (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () {
                  AppSnackbar.showError(message: 'First error');
                  AppSnackbar.showSuccess(message: 'Saved successfully');
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const Scaffold(body: Text('Details')),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Details'), findsOneWidget);
      expect(find.text('Saved successfully'), findsOneWidget);
      expect(find.text('First error'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'message from initial widget build is deferred safely and keeps action',
    (tester) async {
      var acted = false;
      var shown = false;
      await tester.pumpWidget(
        GetMaterialApp(
          home: Builder(
            builder: (_) {
              if (!shown) {
                shown = true;
                AppSnackbar.showInfo(
                  message: 'Requirement updated',
                  actionLabel: 'View',
                  onAction: () => acted = true,
                );
              }
              return const Scaffold(body: Text('Requirements'));
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Requirement updated'), findsOneWidget);
      await tester.tap(find.text('View'));
      await tester.pumpAndSettle();
      expect(acted, isTrue);
      expect(tester.takeException(), isNull);
    },
  );
}
