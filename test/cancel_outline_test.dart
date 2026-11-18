import 'package:daalsetu/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

/// Every "Cancel" in a dialog is an outlined button in the brand orange, not bare text.
void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  for (final dark in [false, true]) {
    testWidgets('Cancel in a confirm dialog has an orange outline (${dark ? 'dark' : 'light'})', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Accept buyer interest?'),
                    actions: [
                      FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Accept')),
                      OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                    ],
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final cancel = find.widgetWithText(OutlinedButton, 'Cancel');
      expect(cancel, findsOneWidget);
      final side = tester.widget<OutlinedButton>(cancel).style?.side ?? Theme.of(tester.element(cancel)).outlinedButtonTheme.style?.side;
      expect(side?.resolve({})?.color, AppTheme.secondaryOrange);
      expect(side?.resolve({})?.width, greaterThan(0.5));
    });
  }
}
