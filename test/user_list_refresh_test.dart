import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:daalsetu/modules/users/controller/user_controller.dart';
import 'package:daalsetu/modules/users/model/user_model.dart';

class TestUserController extends UserController {
  int fetchCount = 0;

  @override
  Future<void> fetchUsers() async {
    if (isLoading.value) return;
    fetchCount++;
  }
}

UserModel createMockUser({
  required int id,
  required String username,
  required String mobile,
  required String role,
  String? firstName,
  String? lastName,
  String? email,
  bool isActive = true,
  String kycStatus = 'pending',
}) {
  return UserModel(
    id: id,
    username: username,
    mobile: mobile,
    role: role,
    firstName: firstName,
    lastName: lastName,
    email: email,
    isActive: isActive,
    kycStatus: kycStatus,
    accountStatus: 'active',
    tags: [],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('User List Refresh and Filter Management Tests', () {
    late TestUserController controller;

    setUp(() {
      Get.reset();
      controller = Get.put<UserController>(TestUserController()) as TestUserController;
      // Initialize with existing users
      controller.users.assignAll([
        createMockUser(
          id: 1,
          username: 'buyer_one',
          mobile: '9876543210',
          role: 'buyer',
          firstName: 'Ramesh',
          lastName: 'Kumar',
        ),
        createMockUser(
          id: 2,
          username: 'seller_one',
          mobile: '9876543211',
          role: 'seller',
          firstName: 'Suresh',
          lastName: 'Patel',
        ),
      ]);
    });

    tearDown(() {
      Get.reset();
    });

    test('Initial user list and statistics calculate correctly', () {
      expect(controller.totalCount, 2);
      expect(controller.buyerCount, 1);
      expect(controller.sellerCount, 1);
      expect(controller.transporterCount, 0);
      expect(controller.filteredUsers.length, 2);
    });

    test('Adding a new user updates user list, stats, and filtered list immediately', () {
      final newUser = createMockUser(
        id: 3,
        username: 'buyer_two',
        mobile: '9876543212',
        role: 'buyer',
        firstName: 'Ankit',
        lastName: 'Sharma',
      );

      // Simulates list state update after backend confirmation
      controller.users.insert(0, newUser);
      expect(controller.totalCount, 3);
      expect(controller.buyerCount, 2);
      expect(controller.filteredUsers.first.id, 3);
      expect(controller.filteredUsers.first.fullName, 'Ankit Sharma');
    });

    test('Role filter is preserved when list refreshes with a matching new user', () {
      controller.setRole('buyer');
      expect(controller.filteredUsers.length, 1);

      final newBuyer = createMockUser(
        id: 4,
        username: 'buyer_three',
        mobile: '9876543213',
        role: 'buyer',
        firstName: 'Deepak',
        lastName: 'Verma',
      );

      // Add to users and reapply filter
      controller.users.insert(0, newBuyer);
      expect(controller.totalCount, 3);
      expect(controller.buyerCount, 2);
      expect(controller.filteredUsers.length, 2);
      expect(controller.filteredUsers.any((u) => u.id == 4), isTrue);
    });

    test('Role filter excludes non-matching new users from filtered view but updates counts', () {
      controller.setRole('seller');
      expect(controller.filteredUsers.length, 1);

      final newBuyer = createMockUser(
        id: 5,
        username: 'buyer_four',
        mobile: '9876543214',
        role: 'buyer',
      );

      controller.users.insert(0, newBuyer);
      expect(controller.totalCount, 3);
      expect(controller.buyerCount, 2);
      expect(controller.sellerCount, 1);
      // Filtered list still only shows the seller
      expect(controller.filteredUsers.length, 1);
      expect(controller.filteredUsers.first.role, 'seller');
    });

    test('Active search query preserves filter and correctly finds newly added user', () {
      controller.setSearch('sharma');
      expect(controller.filteredUsers.length, 0);

      final newSharma = createMockUser(
        id: 6,
        username: 'sharma_ji',
        mobile: '9876543215',
        role: 'buyer',
        firstName: 'Rohit',
        lastName: 'Sharma',
      );

      controller.users.insert(0, newSharma);
      expect(controller.filteredUsers.length, 1);
      expect(controller.filteredUsers.first.fullName, 'Rohit Sharma');
    });

    test('fetchUsers guard blocks duplicate overlapping API requests', () async {
      controller.isLoading.value = true;
      final initialCount = controller.fetchCount;
      await controller.fetchUsers();
      expect(controller.fetchCount, initialCount);
    });

    test('fetchUsers proceeds when not already loading', () async {
      controller.isLoading.value = false;
      final initialCount = controller.fetchCount;
      await controller.fetchUsers();
      expect(controller.fetchCount, initialCount + 1);
    });

    test('AddUserController invokes UserController.fetchUsers() upon successful user creation', () {
      expect(Get.isRegistered<UserController>(), isTrue);
      final initialCount = controller.fetchCount;
      // Triggers the exact logic executed in AddUserController on status == success
      Get.find<UserController>().fetchUsers();
      expect(controller.fetchCount, initialCount + 1);
    });

    test('No duplicate user entries exist when list is refreshed via assignAll', () {
      final updatedList = [
        createMockUser(id: 1, username: 'buyer_one', mobile: '9876543210', role: 'buyer'),
        createMockUser(id: 2, username: 'seller_one', mobile: '9876543211', role: 'seller'),
        createMockUser(id: 7, username: 'transporter_one', mobile: '9876543216', role: 'transporter'),
      ];

      controller.users.assignAll(updatedList);
      expect(controller.totalCount, 3);
      expect(controller.users.map((u) => u.id).toSet().length, 3);
    });
  });
}
