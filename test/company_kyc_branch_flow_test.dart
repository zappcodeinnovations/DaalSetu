import 'package:daalsetu/modules/profile/controller/profile_controller.dart';
import 'package:daalsetu/modules/profile/model/profile_model.dart';
import 'package:daalsetu/utils/company_location.dart';
import 'package:daalsetu/widgets/branch_join_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// A profile controller that never calls the server.
class _OfflineProfile extends ProfileController {
  @override
  void onInit() {}

  @override
  Future<void> fetchProfile({bool showError = false, bool silent = false}) async {}
}

ProfileModel _profile(Map<String, dynamic> extra) => ProfileModel.fromJson({
      'id': 7,
      'username': '7999840592',
      'role': 'seller',
      'kyc_status': 'approved',
      ...extra,
    });

Future<void> _pumpGate(WidgetTester tester, ProfileModel profile) async {
  final controller = Get.put<ProfileController>(_OfflineProfile());
  controller.profile.value = profile;
  await tester.pumpWidget(GetMaterialApp(
    home: Scaffold(body: BranchJoinGate(child: const Center(child: Text('dashboard')))),
  ));
  await tester.pumpAndSettle();
}

void main() {
  tearDown(Get.reset);

  test('the profile carries the branch state and the trading permission from the server', () {
    final profile = _profile({
      'can_perform_actions': false,
      'action_block_message': 'Your request to join branch AMA462M was rejected. Reason: Wrong branch.',
      'needs_branch_code': true,
      'branch_message': 'Your request to join branch AMA462M was rejected. Reason: Wrong branch.',
      'branch_membership': {'status': 'rejected', 'branch_code': 'AMA462M', 'review_note': 'Wrong branch'},
    });
    expect(profile.canPerformActions, isFalse);
    expect(profile.needsBranchCode, isTrue);
    expect(profile.branchStatus, 'rejected');
    expect(profile.branchReviewNote, 'Wrong branch');
    // Old servers send none of it: nothing is blocked by the app.
    final old = _profile({});
    expect(old.canPerformActions, isTrue);
    expect(old.needsBranchCode, isFalse);
    expect(old.branchMessage, isNull);
  });

  test('company address rules follow the country', () {
    expect(CompanyLocation.isIndia(''), isTrue);
    expect(CompanyLocation.isIndia('India'), isTrue);
    expect(CompanyLocation.isIndia('Nepal'), isFalse);
    expect(CompanyLocation.postalCodeError('India', '440001'), isNull);
    expect(CompanyLocation.postalCodeError('India', '4400'), isNotNull);
    expect(CompanyLocation.postalCodeError('United Kingdom', 'SW1A 1AA'), isNull);
    expect(CompanyLocation.postalCodeError('Nepal', '!'), isNotNull);
    expect(CompanyLocation.postalCodeLabel('Nepal'), 'Postal Code');
  });

  testWidgets('KYC approved without a branch: the Branch Code popup and the banner', (tester) async {
    await _pumpGate(tester, _profile({
      'can_perform_actions': false,
      'needs_branch_code': true,
      'branch_message': 'Your KYC is approved. Enter your branch code to join a branch and start trading.',
      'branch_membership': {'status': 'none'},
    }));
    expect(find.byKey(const Key('branch-code-dialog')), findsOneWidget);
    await tester.tap(find.text('Later'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('branch-join-banner')), findsOneWidget);
    expect(find.text('Enter code'), findsOneWidget);
    expect(find.text('dashboard'), findsOneWidget);
  });

  testWidgets('a pending branch request shows its status and no popup', (tester) async {
    await _pumpGate(tester, _profile({
      'can_perform_actions': false,
      'needs_branch_code': false,
      'branch_message': 'Your request to join branch AMA462M is waiting for admin approval.',
      'branch_membership': {'status': 'pending', 'branch_code': 'AMA462M'},
    }));
    expect(find.byKey(const Key('branch-code-dialog')), findsNothing);
    expect(find.text('Your request to join branch AMA462M is waiting for admin approval.'), findsOneWidget);
  });

  testWidgets('a rejected request shows the admin remark in the popup', (tester) async {
    await _pumpGate(tester, _profile({
      'can_perform_actions': false,
      'needs_branch_code': true,
      'branch_message': 'Your request to join branch AMA462M was rejected. Reason: Wrong branch.',
      'branch_membership': {'status': 'rejected', 'branch_code': 'AMA462M', 'review_note': 'Wrong branch'},
    }));
    expect(find.textContaining('was rejected: Wrong branch'), findsOneWidget);
  });

  testWidgets('pending KYC shows the server reason and an approved branch shows nothing', (tester) async {
    await _pumpGate(tester, _profile({
      'kyc_status': 'pending',
      'can_perform_actions': false,
      'action_block_message': 'Waiting for KYC approval by admin.',
    }));
    expect(find.text('Waiting for KYC approval by admin.'), findsOneWidget);
    expect(find.byKey(const Key('branch-code-dialog')), findsNothing);

    Get.find<ProfileController>().profile.value = _profile({
      'can_perform_actions': true,
      'branch_membership': {'status': 'approved', 'branch_code': 'AMA462M'},
    });
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('branch-join-banner')), findsNothing);
  });
}
