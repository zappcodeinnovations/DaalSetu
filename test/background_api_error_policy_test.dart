import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'profile background loads suppress global API errors and raw toasts',
    () {
      final service = File(
        'lib/services/profile_services.dart',
      ).readAsStringSync();
      final controller = File(
        'lib/modules/profile/controller/profile_controller.dart',
      ).readAsStringSync();

      expect(service, contains('getProfile({bool silent = true})'));
      expect(service, contains('suppressErrorDialog: silent'));
      final fetchProfileBlock = controller.substring(
        controller.indexOf('Future<void> fetchProfile'),
        controller.indexOf('Future<bool> updateProfile'),
      );
      expect(fetchProfileBlock, contains('getProfile(silent: !showError)'));
      expect(
        fetchProfileBlock,
        isNot(contains('Get.snackbar("Error", e.toString())')),
      );
    },
  );

  test('buyer branch silent refresh reaches the API client', () {
    final service = File(
      'lib/services/seller_services.dart',
    ).readAsStringSync();
    final controller = File(
      'lib/modules/buyer/branch/controller/buyer_branch_controller.dart',
    ).readAsStringSync();

    expect(service, contains('getSellerBranches({'));
    expect(service, contains('suppressErrorDialog: silent'));
    expect(controller, contains('getSellerBranches(silent: silent)'));
  });
}
