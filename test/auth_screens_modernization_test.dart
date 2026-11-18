import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:daalsetu/modules/Auth/forgot_password/view/forgot_password_page.dart';
import 'package:daalsetu/modules/Auth/register/view/register_page.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('ForgotPasswordScreen renders branding, Pulse Trading Platform badge, and form cleanly', (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: ForgotPasswordScreen(),
      ),
    );
    await tester.pump();

    expect(find.text("DaalSetu"), findsOneWidget);
    expect(find.text("Pulse Trading Platform"), findsOneWidget);
    expect(find.text("Reset Password"), findsOneWidget);
    expect(find.text("SEND PASSWORD"), findsOneWidget);
    expect(find.text("Back to Sign In"), findsOneWidget);
  });

  testWidgets('RegisterScreen renders branding, Pulse Trading Platform badge, and registration fields', (tester) async {
    await tester.pumpWidget(
      const GetMaterialApp(
        home: RegisterScreen(),
      ),
    );
    await tester.pump();

    expect(find.text("DaalSetu"), findsWidgets);
    expect(find.text("Pulse Trading Platform"), findsWidgets);
    expect(find.text("Create Account"), findsWidgets);
    expect(find.textContaining("First Name"), findsOneWidget);
    expect(find.textContaining("Last Name"), findsOneWidget);
    expect(find.textContaining("Email"), findsOneWidget);
    expect(find.textContaining("Mobile"), findsOneWidget);
  });
}
