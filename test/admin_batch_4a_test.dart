import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:daalsetu/modules/dashboard/view/dashboard_page.dart';
import 'package:daalsetu/modules/dashboard/controller/dashboard_controller.dart';
import 'package:daalsetu/modules/dashboard/model/dashboard_model.dart';
import 'package:daalsetu/modules/admin_notifications/view/admin_notification_view.dart';
import 'package:daalsetu/modules/admin_notifications/controller/admin_notification_controller.dart';
import 'package:daalsetu/modules/admin_notifications/model/admin_notification_model.dart';
import 'package:daalsetu/modules/profile/controller/profile_controller.dart';
import 'package:daalsetu/modules/profile/model/profile_model.dart';
import 'package:daalsetu/widgets/hero_header.dart';

class _OfflineDashboardController extends DashboardController {
  @override
  Future<void> fetchDashboard() async {}
}

class _OfflineProfileController extends ProfileController {
  @override
  Future<void> fetchProfile({bool showError = false, bool silent = false}) async {}
}

class _OfflineAdminNotificationController extends AdminNotificationController {
  @override
  Future<void> fetchNotifications({bool isRefresh = false}) async {}
  @override
  Future<void> fetchUnreadCount() async {}
}

void main() {
  setUp(() {
    Get.testMode = true;
    FlutterSecureStorage.setMockInitialValues({
      'user_role': 'admin',
    });
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('AdminDashboardScreen renders HeroHeader with app logo and KPI section', (tester) async {
    final dashCtrl = Get.put<DashboardController>(_OfflineDashboardController());
    dashCtrl.isLoading.value = false;
    dashCtrl.dashboardData.value = DashboardModel.fromJson({});

    final profCtrl = Get.put<ProfileController>(_OfflineProfileController());
    profCtrl.profile.value = ProfileModel.fromJson({
      'id': 1,
      'username': 'admin_user',
      'first_name': 'Admin',
      'last_name': 'User',
      'email': 'admin@daalsetu.com',
      'mobile': '9876543210',
      'role': 'super_admin',
      'is_active': true,
      'kyc_status': 'approved',
    });

    Get.put<AdminNotificationController>(_OfflineAdminNotificationController());

    tester.view.physicalSize = const Size(450, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(GetMaterialApp(home: AdminDashboardScreen()));
    await tester.pump();

    // Verify Header
    expect(find.byType(HeroHeader), findsOneWidget);
    expect(find.byTooltip('Open navigation menu'), findsOneWidget);

    // Verify Hero greeting
    expect(find.text('Hello, '), findsOneWidget);
    expect(find.text('Admin User'), findsOneWidget);
    expect(find.text('Super Admin Access'), findsOneWidget);

    // Verify Dashboard KPIs section
    expect(find.text('Dashboard KPIs'), findsOneWidget);
  });

  testWidgets('AdminNotificationView renders HeroHeader, search, filters, and notification cards', (tester) async {
    final notifCtrl = Get.put<AdminNotificationController>(_OfflineAdminNotificationController());
    notifCtrl.isLoading.value = false;
    notifCtrl.unreadCount.value = 3;
    notifCtrl.notifications.assignAll([
      AdminNotificationModel(
        id: 101,
        title: "Deal Approved",
        message: "Trade agreement #901 approved by Super Admin",
        type: "contract",
        isRead: false,
        timeAgo: "10m ago",
      ),
    ]);
    notifCtrl.filteredNotifications.assignAll(notifCtrl.notifications);

    tester.view.physicalSize = const Size(450, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(GetMaterialApp(home: const AdminNotificationView()));
    await tester.pump();

    // Verify Header
    expect(find.byType(HeroHeader), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Platform alerts & operational notices'), findsOneWidget);

    // Verify Search and Filters
    expect(find.text('Search notifications...'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Unread'), findsOneWidget);
    expect(find.text('Trades'), findsOneWidget);
    expect(find.text('System'), findsOneWidget);

    // Verify Notification Card
    expect(find.text('Deal Approved'), findsOneWidget);
    expect(find.text('Trade agreement #901 approved by Super Admin'), findsOneWidget);
    expect(find.text('CONTRACT'), findsOneWidget);
  });
}
