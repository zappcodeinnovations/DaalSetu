import 'package:daalsetu/utils/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  testWidgets('an error is a centred popup, shown once even if repeated', (tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: Scaffold(body: SizedBox())));
    AppSnackbar.snackbar('Error', 'Failed to remove GST Certificate.', backgroundColor: Colors.red);
    AppSnackbar.snackbar('Error', 'Failed to remove GST Certificate.', backgroundColor: Colors.red);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('app-error-dialog')), findsOneWidget);
    expect(find.text('Failed to remove GST Certificate.'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('app-error-dialog')), findsNothing);
  });

  testWidgets('a success message stays a small snackbar (no popup)', (tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: Scaffold(body: SizedBox())));
    AppSnackbar.snackbar('Success', 'Profile updated', backgroundColor: Colors.green);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('app-error-dialog')), findsNothing);
    expect(find.text('Profile updated'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
  });
}
