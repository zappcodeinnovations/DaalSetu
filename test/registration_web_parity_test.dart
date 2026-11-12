import 'package:daalsetu/modules/Auth/register/controller/register_controller.dart';
import 'package:daalsetu/modules/Auth/register/view/register_page.dart';
import 'package:daalsetu/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  test('registration payload matches the web/API contract', () {
    final controller = RegisterController();
    addTearDown(controller.dispose);
    controller.firstNameController.text = 'Test';
    controller.lastNameController.text = 'Buyer';
    controller.emailController.text = 'buyer@example.com';
    controller.mobileController.text = '9876543210';
    controller.companyNameController.text = 'Test Trading';
    controller.branchCodeController.text = ' ama462m ';
    controller.passwordController.text = 'password123';
    controller.confirmPasswordController.text = 'password123';
    controller.selectedRole = 'buyer';
    controller.selectedGender = 'male';

    expect(controller.buildFields(), {
      'mobile': '9876543210',
      'email': 'buyer@example.com',
      'first_name': 'Test',
      'last_name': 'Buyer',
      'company_name': 'Test Trading',
      'role': 'buyer',
      'branch_code': 'AMA462M',
      'gender': 'male',
      'password': 'password123',
      'confirm_password': 'password123',
    });
  });

  testWidgets('mobile registration renders the same fields as web', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      GetMaterialApp(theme: AppTheme.lightTheme, home: const RegisterScreen()),
    );
    await tester.pump();

    expect(find.text('Create Account'), findsNWidgets(2));
    expect(find.byType(TextFormField), findsNWidgets(8));
    expect(find.byType(DropdownButtonFormField<String>), findsNWidgets(2));
    final hints = tester
        .widgetList<TextField>(find.byType(TextField))
        .map((field) => field.decoration?.hintText)
        .whereType<String>()
        .toSet();
    expect(
      hints,
      containsAll(<String>{
        'Enter first name',
        'Enter last name',
        'Enter email address',
        'Enter 10-digit mobile number',
        'Enter company name',
        'Enter branch code',
        'Minimum 8 characters',
        'Confirm password',
      }),
    );
    expect(
      find.text('Already have an account? Sign in', findRichText: true),
      findsOneWidget,
    );
    expect(find.textContaining('PAN'), findsNothing);
    expect(find.textContaining('GST'), findsNothing);
    expect(find.textContaining('Date of Birth'), findsNothing);
  });
}
