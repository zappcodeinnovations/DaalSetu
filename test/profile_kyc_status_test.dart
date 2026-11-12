import 'package:daalsetu/modules/profile/model/profile_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pending KYC shows submitted status without a re-approval action', () {
    final user = ProfileModel.fromJson({'kyc_status': 'pending'});
    expect(user.isKycAwaitingApproval, isTrue);
    expect(user.canRequestKycApproval, isFalse);
  });
  test('rejected KYC may be resubmitted until a request is pending', () {
    final user = ProfileModel.fromJson({'kyc_status': 'rejected'});
    expect(user.canRequestKycApproval, isTrue);
    final submitted = user.copyWith(hasPendingKycRequest: true);
    expect(submitted.isKycAwaitingApproval, isTrue);
    expect(submitted.canRequestKycApproval, isFalse);
    expect(submitted.kycStatus, 'rejected');
  });
  test('pending re-approval survives profile reload', () {
    final user = ProfileModel.fromJson({
      'body': {'kyc_status': 'rejected', 'has_pending_kyc_request': true},
    });
    expect(user.isKycAwaitingApproval, isTrue);
    expect(user.canRequestKycApproval, isFalse);
    expect(user.copyWith(firstName: 'Updated').hasPendingKycRequest, isTrue);
  });
  test('a later rejection enables resubmission', () {
    final user = ProfileModel.fromJson({
      'kyc_status': 'rejected',
      'has_pending_kyc_request': false,
    });
    expect(user.isKycAwaitingApproval, isFalse);
    expect(user.canRequestKycApproval, isTrue);
  });
  test('approved users do not see pending status or submit action', () {
    for (final status in ['approved', 'verified', ' Approved ']) {
      final user = ProfileModel.fromJson({
        'kyc_status': status,
        'has_pending_kyc_request': true,
      });
      expect(user.isKycApproved, isTrue);
      expect(user.isKycAwaitingApproval, isFalse);
      expect(user.canRequestKycApproval, isFalse);
    }
  });
}
