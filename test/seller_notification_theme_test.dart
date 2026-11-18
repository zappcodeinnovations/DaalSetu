import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:daalsetu/modules/seller/notifications/view/seller_notification_view.dart';
import 'package:daalsetu/modules/seller/notifications/controller/seller_notification_controller.dart';
import 'package:daalsetu/modules/seller/notifications/model/notification_model.dart';
import 'package:daalsetu/theme/app_theme.dart';

void main() {
  setUp(() {
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('SellerNotificationView renders dark mode cards with high contrast text and proper background', (tester) async {
    final controller = Get.put(SellerNotificationController());
    controller.notificationsList.assignAll([
      AppNotificationModel(
        id: 1,
        title: 'KYC Approved',
        message: 'Your KYC has been approved successfully',
        timeAgo: '4 day ago',
        isRead: false,
      ),
      AppNotificationModel(
        id: 2,
        title: 'KYC Status Updated',
        message: 'Your KYC has been APPROVED.',
        timeAgo: '4 day ago',
        isRead: true,
      ),
    ]);
    controller.isLoading.value = false;

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: const SellerNotificationView(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('KYC Approved'), findsOneWidget);
    expect(find.text('Your KYC has been approved successfully'), findsOneWidget);
    expect(find.text('KYC Status Updated'), findsOneWidget);

    // Verify unread card does not use Colors.amber.shade50 in dark mode
    final containers = tester.widgetList<Container>(find.byType(Container));
    final hasAmber50 = containers.any((c) {
      final decoration = c.decoration;
      if (decoration is BoxDecoration) {
        return decoration.color == Colors.amber.shade50;
      }
      return false;
    });
    expect(hasAmber50, isFalse);
  });
}
