import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:daalsetu/modules/buyer/branch/controller/buyer_branch_controller.dart';
import 'package:daalsetu/modules/seller/branches/model/seller_branch_model.dart';
import 'package:daalsetu/modules/seller/notifications/model/notification_model.dart';
import 'package:daalsetu/services/realtime_notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Buyer Branch Approval Real-time Refresh Tests', () {
    late BuyerBranchController controller;

    setUp(() {
      Get.reset();
      controller = BuyerBranchController();
    });

    tearDown(() {
      controller.onClose();
      Get.reset();
    });

    test('RealtimeNotificationService detects branch approval notification correctly', () {
      final notif = AppNotificationModel(
        id: 101,
        title: "Branch Request Approved",
        message: "Branch request for NAG821M was approved by Pradeep H Jhawar.",
        type: "branch",
        isRead: false,
      );

      expect(RealtimeNotificationService.isBranchNotification(notif), true);
    });

    test('handleBranchNotification immediately clears NAG821M from pendingRequests and moves to myBranches', () {
      // Seed pending request for NAG821M
      final testBranch = SellerBranchModel(
        id: 42,
        branchId: 42,
        branchCode: "NAG821M",
        locationName: "Test Branch",
        city: "Nagpur",
        state: "Maharashtra",
        status: "pending",
      );

      controller.pendingRequests.add(testBranch);
      expect(controller.pendingRequests.length, 1);
      expect(controller.pendingRequests.first.branchCode, "NAG821M");
      expect(controller.myBranches.any((b) => b.branchCode == "NAG821M"), false);

      // Simulate receiving in-app notification banner for approval
      final notif = AppNotificationModel(
        id: 999,
        title: "Branch Request Approved",
        message: "Branch request for NAG821M was approved by Pradeep H Jhawar.",
        type: "branch",
        isRead: false,
      );

      controller.handleBranchNotification(notif);

      // Verify NAG821M was cleared from pendingRequests immediately without app reload
      expect(controller.pendingRequests.any((r) => r.branchCode == "NAG821M"), false);
      expect(controller.pendingRequests.isEmpty, true);

      // Verify NAG821M is now in myBranches
      expect(controller.myBranches.any((b) => b.branchCode == "NAG821M"), true);
      final activeBranch = controller.myBranches.firstWhere((b) => b.branchCode == "NAG821M");
      expect(activeBranch.locationName, "Test Branch");
      expect(activeBranch.status, "active");
    });
  });
}
