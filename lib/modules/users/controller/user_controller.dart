import 'package:agro_broker/modules/users/model/user_model.dart';
import 'package:agro_broker/services/users_services.dart';
import 'package:get/get.dart';

class UserController extends GetxController {
  // ── State ─────────────────────────────────────────────────────────────────
  var isLoading = false.obs;
  var isDeleting = false.obs;

  var users = <UserModel>[].obs;
  var filteredUsers = <UserModel>[].obs;

  var searchQuery = ''.obs;
  var selectedRole = 'all'.obs;

  // ── Stats (computed from users list) ──────────────────────────────────────
  int get totalCount => users.length;
  int get buyerCount =>
      users.where((u) => u.role.toLowerCase() == 'buyer').length;
  int get sellerCount =>
      users.where((u) => u.role.toLowerCase() == 'seller').length;
  int get transporterCount =>
      users.where((u) => u.role.toLowerCase() == 'transporter').length;
  int get kycApprovedCount =>
      users.where((u) => u.kycStatus.toLowerCase() == 'approved').length;
  int get kycPendingCount =>
      users.where((u) => u.kycStatus.toLowerCase() == 'pending').length;
  int get activeCount => users.where((u) => u.isActive).length;

  static const roleFilters = [
    'all',
    'buyer',
    'seller',
    'transporter',
    'admin',
    'salesman',
  ];

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    fetchUsers();
    // React to search/filter changes without wrapping entire screen in Obx
    ever(searchQuery, (_) => _applyFilter());
    ever(selectedRole, (_) => _applyFilter());
  }

  // ── Fetch ─────────────────────────────────────────────────────────────────
  Future<void> fetchUsers() async {
    try {
      isLoading.value = true;
      final data = await UserService.getUsers();
      users.assignAll(data);
      _applyFilter();
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ── Filter ────────────────────────────────────────────────────────────────
  void _applyFilter() {
    var result = users.toList();

    if (selectedRole.value != 'all') {
      result = result
          .where((u) =>
              u.role.toLowerCase() == selectedRole.value.toLowerCase())
          .toList();
    }

    final q = searchQuery.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((u) {
        return u.fullName.toLowerCase().contains(q) ||
            u.mobile.contains(q) ||
            u.username.toLowerCase().contains(q) ||
            (u.email?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    filteredUsers.assignAll(result);
  }

  void setRole(String role) => selectedRole.value = role;
  void setSearch(String query) => searchQuery.value = query;
  void clearSearch() => searchQuery.value = '';

  // ── Delete ────────────────────────────────────────────────────────────────
  Future<void> deleteUser(int userId) async {
    try {
      isDeleting.value = true;
      await UserService.deleteUser(userId);
      users.removeWhere((u) => u.id == userId);
      _applyFilter();
      Get.snackbar(
        'Deleted',
        'User deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isDeleting.value = false;
    }
  }

  // ── Update Status ─────────────────────────────────────────────────────────
  Future<void> updateUserStatus(
      int userId, String status, String reason) async {
    try {
      await UserService.updateUserStatus(userId, status, reason);
      await fetchUsers(); // refresh list
      Get.snackbar(
        'Updated',
        'User status updated to $status',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
