import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:daalsetu/modules/users/view/add_user_screen.dart';
import 'package:daalsetu/modules/users/controller/add_user_controller.dart';
import 'package:daalsetu/modules/admin_catalog/config/admin_module_config.dart';
import 'package:daalsetu/modules/admin_catalog/view/admin_record_form_screen.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  group('User Creation Form Reset Tests', () {
    testWidgets('AddUserScreen resets all fields clean upon resetForm', (tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(
          home: AddUserScreen(),
        ),
      );
      await tester.pump();

      final stateFinder = find.byType(AddUserScreen);
      expect(stateFinder, findsOneWidget);
      final state = tester.state<AddUserScreenState>(stateFinder);

      // 1. Simulate entering data in all fields
      state.firstNameController.text = 'Rajesh';
      state.lastNameController.text = 'Sharma';
      state.mobileController.text = '9876543210';
      state.emailController.text = 'rajesh@example.com';
      state.passwordController.text = 'Secret123';
      state.branchController.text = 'NAG622M';
      state.panController.text = 'ABCDE1234F';
      state.gstController.text = '27ABCDE1234F1Z5';
      state.selectedRole.value = 'seller';
      state.selectedGender.value = 'male';

      expect(state.firstNameController.text, 'Rajesh');
      expect(state.lastNameController.text, 'Sharma');
      expect(state.mobileController.text, '9876543210');
      expect(state.emailController.text, 'rajesh@example.com');
      expect(state.passwordController.text, 'Secret123');
      expect(state.branchController.text, 'NAG622M');
      expect(state.panController.text, 'ABCDE1234F');
      expect(state.gstController.text, '27ABCDE1234F1Z5');
      expect(state.selectedRole.value, 'seller');
      expect(state.selectedGender.value, 'male');

      // 2. Trigger resetForm
      state.resetForm();

      // 3. Verify all fields are wiped completely clean
      expect(state.firstNameController.text, isEmpty);
      expect(state.lastNameController.text, isEmpty);
      expect(state.mobileController.text, isEmpty);
      expect(state.emailController.text, isEmpty);
      expect(state.passwordController.text, isEmpty);
      expect(state.branchController.text, isEmpty);
      expect(state.panController.text, isEmpty);
      expect(state.gstController.text, isEmpty);
      expect(state.selectedRole.value, 'buyer');
      expect(state.selectedGender.value, isEmpty);
      expect(state.panImage.value, isNull);
      expect(state.gstImage.value, isNull);
    });

    testWidgets('AddUserController reset method clears tag selection and loading state', (tester) async {
      final controller = Get.put(AddUserController());
      controller.selectedTagId.value = 5;
      controller.isLoading.value = true;

      controller.reset();

      expect(controller.selectedTagId.value, isNull);
      expect(controller.isLoading.value, isFalse);
    });

    testWidgets('AdminRecordFormScreen resetForm wipes controllers clean for user fields', (tester) async {
      const customUserConfig = AdminModuleConfig(
        key: 'users',
        title: 'User Management',
        icon: Icons.people,
        listEndpoint: '/api/users/',
        titleKeys: ['username', 'name'],
        createEndpoint: '/api/users/create/',
        fields: [
          AdminFieldConfig('first_name', 'First name', required: true),
          AdminFieldConfig('last_name', 'Last name'),
          AdminFieldConfig('mobile', 'Mobile number', required: true, numeric: true),
          AdminFieldConfig('email', 'Email', required: true),
          AdminFieldConfig('branch_code', 'Branch code'),
        ],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminRecordFormScreen(config: customUserConfig),
        ),
      );
      await tester.pump();

      final formState = tester.state(find.byType(AdminRecordFormScreen)) as dynamic;

      // Populate text controllers
      formState.controllers['first_name']?.text = 'Amit';
      formState.controllers['last_name']?.text = 'Patel';
      formState.controllers['mobile']?.text = '9998887776';
      formState.controllers['email']?.text = 'amit@example.com';
      formState.controllers['branch_code']?.text = 'BHO01';

      expect(formState.controllers['first_name']?.text, 'Amit');
      expect(formState.controllers['mobile']?.text, '9998887776');
      expect(formState.controllers['branch_code']?.text, 'BHO01');

      // Trigger resetForm
      formState.resetForm();

      // Verify wiped clean
      expect(formState.controllers['first_name']?.text, isEmpty);
      expect(formState.controllers['last_name']?.text, isEmpty);
      expect(formState.controllers['mobile']?.text, isEmpty);
      expect(formState.controllers['email']?.text, isEmpty);
      expect(formState.controllers['branch_code']?.text, isEmpty);
    });
  });
}
