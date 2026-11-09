import 'package:daalsetu/modules/Auth/login/controller/login_controller.dart';
import 'package:daalsetu/modules/Auth/login/view/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  setUp(() {
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('LoginScreen password eye icon toggles visibility consecutively without getting stuck',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const GetMaterialApp(
        home: LoginScreen(),
      ),
    );
    await tester.pumpAndSettle();

    final controller = Get.find<LoginController>();
    expect(controller.isPasswordVisible.value, isFalse);

    // Find the toggle button
    final toggleFinder = find.byKey(const Key('login_password_visibility_toggle'));
    expect(toggleFinder, findsOneWidget);

    // Initial state: password field should have obscureText: true
    EditableText editableText() =>
        tester.widget<EditableText>(find.byType(EditableText).last);
    expect(editableText().obscureText, isTrue);

    // First tap: reveals password
    await tester.tap(toggleFinder);
    await tester.pumpAndSettle();
    expect(controller.isPasswordVisible.value, isTrue);
    expect(editableText().obscureText, isFalse);

    // Second tap: hides password again (verifies no stuck/intercepted tap)
    await tester.tap(toggleFinder);
    await tester.pumpAndSettle();
    expect(controller.isPasswordVisible.value, isFalse);
    expect(editableText().obscureText, isTrue);

    // Third tap: reveals password once more
    await tester.tap(toggleFinder);
    await tester.pumpAndSettle();
    expect(controller.isPasswordVisible.value, isTrue);
    expect(editableText().obscureText, isFalse);
  });

  testWidgets('LoginScreen preserves cursor position when toggling password visibility',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const GetMaterialApp(
        home: LoginScreen(),
      ),
    );
    await tester.pumpAndSettle();

    final controller = Get.find<LoginController>();
    final toggleFinder = find.byKey(const Key('login_password_visibility_toggle'));

    // Enter password text
    controller.passwordController.text = 'Secret1234';
    controller.passwordController.selection = const TextSelection.collapsed(offset: 10);

    // First tap: reveals password and verifies cursor is still at offset 10
    await tester.tap(toggleFinder);
    await tester.pumpAndSettle();
    expect(controller.passwordController.selection.baseOffset, 10);

    // Second tap: hides password and verifies cursor remains at offset 10
    await tester.tap(toggleFinder);
    await tester.pumpAndSettle();
    expect(controller.passwordController.selection.baseOffset, 10);
  });
}

