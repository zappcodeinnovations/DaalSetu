import 'package:flutter_test/flutter_test.dart';
import 'package:daalsetu/modules/kyc_users/model/kyc_user_model.dart';
import 'package:daalsetu/modules/kyc_users/controller/kyc_user_controller.dart';
import 'package:get/get.dart';

void main() {
  group('KycUserModel & Search/Filter Tests', () {
    test('parses name from username/first_last when name key is null', () {
      final json1 = {
        'id': 101,
        'username': 'ram_kumar',
        'first_name': 'Ram',
        'last_name': 'Kumar',
        'mobile': '9876543210',
        'email': 'ram@test.com',
        'role': 'buyer',
        'kyc_status': 'pending',
      };
      final user = KycUserModel.fromJson(json1);
      expect(user.id, 101);
      expect(user.name, 'ram_kumar');
      expect(user.mobile, '9876543210');
      expect(user.role, 'buyer');
      expect(user.kycStatus, 'pending');
    });

    test('extracts from nested user map if present', () {
      final json2 = {
        'id': 202,
        'user': {
          'username': 'shyam_trader',
          'first_name': 'Shyam',
          'last_name': 'Singh',
          'mobile': '9123456789',
          'email': 'shyam@test.com',
          'role': 'seller',
        },
        'pan_number': 'ABCDE1234F',
        'kyc_status': 'approved',
      };
      final user = KycUserModel.fromJson(json2);
      expect(user.id, 202);
      expect(user.name, 'shyam_trader');
      expect(user.mobile, '9123456789');
      expect(user.panNumber, 'ABCDE1234F');
      expect(user.role, 'seller');
      expect(user.kycStatus, 'approved');
    });

    test('KycController filters by query (name, pan, role, status)', () {
      final controller = KycController();
      controller.kycUsers.assignAll([
        KycUserModel(
          id: 1,
          name: 'Ramesh Patel',
          mobile: '9876543210',
          email: 'ramesh@daal.com',
          role: 'buyer',
          panNumber: 'RAMES1234K',
          gstNumber: '27RAMES1234K1Z5',
          kycStatus: 'pending',
          kycSubmittedAt: null,
          kycApprovedAt: null,
          kycRejectedAt: null,
          kycRejectionReason: null,
          accountStatus: 'active',
        ),
        KycUserModel(
          id: 2,
          name: 'Suresh Kumar',
          mobile: '9123456780',
          email: 'suresh@daal.com',
          role: 'seller',
          panNumber: 'SURES5678P',
          gstNumber: '27SURES5678P1Z9',
          kycStatus: 'approved',
          kycSubmittedAt: null,
          kycApprovedAt: null,
          kycRejectedAt: null,
          kycRejectionReason: null,
          accountStatus: 'active',
        ),
      ]);

      // Filter by role
      controller.selectedRole.value = 'buyer';
      expect(controller.filteredUsers.length, 1);
      expect(controller.filteredUsers.first.name, 'Ramesh Patel');

      // Reset role, filter by status
      controller.selectedRole.value = 'all';
      controller.selectedFilter.value = 'approved';
      expect(controller.filteredUsers.length, 1);
      expect(controller.filteredUsers.first.name, 'Suresh Kumar');

      // Search by PAN
      controller.selectedFilter.value = 'all';
      controller.searchQuery.value = 'RAMES1234';
      expect(controller.filteredUsers.length, 1);
      expect(controller.filteredUsers.first.name, 'Ramesh Patel');
    });
  });
}
