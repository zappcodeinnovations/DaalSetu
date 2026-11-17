import 'package:daalsetu/modules/Auth/choose_panel/view/choose_panel_screen.dart';
import 'package:daalsetu/modules/Auth/login/model/login_model.dart';
import 'package:daalsetu/utils/app_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// Buyer & Seller account: one login, pick a panel, switch without logging out.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppPreferences role for a Buyer & Seller account', () {
    test('acts as the active panel, defaulting to seller', () async {
      FlutterSecureStorage.setMockInitialValues({
        'user_role': 'both_sellerandbuyer',
        'account_role': 'both_sellerandbuyer',
        'active_panel': 'buyer',
      });
      expect(await AppPreferences.getRole(), 'buyer');
      expect(await AppPreferences.getAccountRole(), 'both_sellerandbuyer');
      expect(await AppPreferences.isCombinedAccount(), isTrue);

      await AppPreferences.setActivePanel('seller');
      expect(await AppPreferences.getRole(), 'seller');

      FlutterSecureStorage.setMockInitialValues({
        'user_role': 'both_sellerandbuyer',
        'account_role': 'both_sellerandbuyer',
      });
      expect(await AppPreferences.getRole(), AppPreferences.defaultPanel);
    });

    test('single-role accounts keep their role', () async {
      FlutterSecureStorage.setMockInitialValues({'user_role': 'buyer', 'account_role': 'buyer'});
      expect(await AppPreferences.getRole(), 'buyer');
      expect(await AppPreferences.isCombinedAccount(), isFalse);
      // an older session that stored only the role
      FlutterSecureStorage.setMockInitialValues({'user_role': 'transporter'});
      expect(await AppPreferences.getRole(), 'transporter');
      expect(await AppPreferences.getAccountRole(), 'transporter');
    });

    test('logout clears the panel keys', () async {
      FlutterSecureStorage.setMockInitialValues({
        'user_role': 'both_sellerandbuyer',
        'account_role': 'both_sellerandbuyer',
        'active_panel': 'buyer',
        'access_token': 't',
      });
      await AppPreferences.logout();
      expect(await AppPreferences.getActivePanel(), isNull);
      expect(await AppPreferences.getAccountRole(), isNull);
    });
  });

  test('login response carries the panel fields', () {
    final user = LoginUser.fromJson({
      'id': 1,
      'username': 'both',
      'role': 'both_sellerandbuyer',
      'kyc_status': 'approved',
      'status': 'active',
      'account_status': 'active',
      'account_role': 'both_sellerandbuyer',
      'active_panel': 'buyer',
      'requires_panel_selection': true,
    });
    expect(user.accountRole, 'both_sellerandbuyer');
    expect(user.activePanel, 'buyer');
    expect(user.requiresPanelSelection, isTrue);

    final plain = LoginUser.fromJson({'id': 2, 'username': 'b', 'role': 'buyer'});
    expect(plain.accountRole, 'buyer');
    expect(plain.requiresPanelSelection, isFalse);
  });

  testWidgets('the choose-panel screen offers the Buyer and Seller panels and marks the last used one', (tester) async {
    FlutterSecureStorage.setMockInitialValues({
      'user_role': 'both_sellerandbuyer',
      'account_role': 'both_sellerandbuyer',
      'active_panel': 'seller',
    });
    await tester.pumpWidget(const GetMaterialApp(home: ChoosePanelScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Buyer Panel'), findsOneWidget);
    expect(find.text('Seller Panel'), findsOneWidget);
    expect(find.byKey(const Key('choose-panel-buyer')), findsOneWidget);
    expect(find.byKey(const Key('choose-panel-seller')), findsOneWidget);
    expect(find.text('Last used'), findsOneWidget);
    expect(find.text('Log out'), findsOneWidget);
    final buyerCard = tester.getRect(find.byKey(const Key('choose-panel-buyer')));
    final sellerCard = tester.getRect(find.byKey(const Key('choose-panel-seller')));
    expect(sellerCard.top, greaterThan(buyerCard.bottom));
    expect(buyerCard.left, sellerCard.left);
    expect(buyerCard.width, sellerCard.width);
    Get.reset();
  });

  testWidgets('panel choices scroll on a small phone with larger text', (tester) async {
    FlutterSecureStorage.setMockInitialValues({'active_panel': 'seller'});
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(GetMaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.6)),
        child: child!,
      ),
      home: const ChoosePanelScreen(),
    ));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('choose-panel-seller')),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('choose-panel-seller')).hitTestable(), findsOneWidget);
    expect(find.text('Log out').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    Get.reset();
  });
}
