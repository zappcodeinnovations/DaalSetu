import 'package:daalsetu/modules/Auth/login/controller/login_controller.dart';
import 'package:daalsetu/modules/Auth/login/view/login_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  testWidgets('LoginScreen safely recovers when controller was previously closed/disposed',
      (WidgetTester tester) async {
    // 1. Initial pump of LoginScreen
    await tester.pumpWidget(
      const GetMaterialApp(
        home: LoginScreen(),
      ),
    );
    await tester.pump();

    // Verify controller is active
    expect(Get.isRegistered<LoginController>(), isTrue);
    final controller = Get.find<LoginController>();
    controller.usernameController.text = '9876543210';
    expect(controller.usernameController.text, '9876543210');

    // 2. Simulate route destruction / onClose lifecycle
    controller.onClose();

    // 3. Mount LoginScreen again (simulating logout or return to login)
    await tester.pumpWidget(
      const GetMaterialApp(
        home: LoginScreen(),
      ),
    );
    await tester.pump();

    // 4. Verify no assertion exception occurred
    expect(tester.takeException(), isNull);

    // 5. Verify the active controller has functional, non-disposed text controllers
    final activeController = Get.find<LoginController>();
    expect(() => activeController.usernameController.text = '9998887776',
        returnsNormally);
    expect(activeController.usernameController.text, '9998887776');
    expect(() => activeController.passwordController.text = 'secret123',
        returnsNormally);
    expect(activeController.passwordController.text, 'secret123');

    // Verify fields render properly on screen
    expect(find.text('Mobile number'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });
}
