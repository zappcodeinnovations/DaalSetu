import 'package:get/get.dart';
import '../../../../services/seller_services.dart';
import '../../../../utils/app_snackbar.dart';
import '../../../seller/branches/model/seller_branch_model.dart';

class BuyerBranchController extends GetxController {
  var isLoading = false.obs;
  var primaryBranch = Rxn<SellerBranchModel>();
  var myBranches = <SellerBranchModel>[].obs;
  var pendingRequests = <SellerBranchModel>[].obs;

  final Set<int> _leftBranchIds = {};

  @override
  void onInit() {
    super.onInit();
    fetchBranches();
  }

  Future<void> fetchBranches() async {
    try {
      isLoading.value = true;
      final res = await SellerServices.getSellerBranches();
      if (res['data'] is Map<String, dynamic>) {
        final data = res['data'] as Map<String, dynamic>;
        if (data['primary_branch'] is Map<String, dynamic>) {
          final pb = SellerBranchModel.fromJson(data['primary_branch']);
          if (!_leftBranchIds.contains(pb.id)) {
            primaryBranch.value = pb;
          } else {
            primaryBranch.value = null;
          }
        } else {
          primaryBranch.value = null;
        }
        if (data['my_branches'] is List) {
          myBranches.value = (data['my_branches'] as List)
              .map((e) => SellerBranchModel.fromJson(e as Map<String, dynamic>))
              .where((b) => b.id != null && !_leftBranchIds.contains(b.id))
              .toList();
        } else {
          myBranches.clear();
        }
        if (data['pending_requests'] is List) {
          pendingRequests.value = (data['pending_requests'] as List)
              .map((e) => SellerBranchModel.fromJson(e as Map<String, dynamic>))
              .toList();
        } else {
          pendingRequests.clear();
        }
      }
    } catch (e) {
      AppSnackbar.showError(title: "Error", message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> joinBranchByCode(String code) async {
    if (code.trim().isEmpty) return false;
    try {
      final res = await SellerServices.requestBranchByCode(code.trim());
      _leftBranchIds.clear(); // Reset cache filter when joining
      await fetchBranches();

      final msg = res['message']?.toString() ?? "Branch request submitted successfully";
      if (msg.toLowerCase().contains("already")) {
        AppSnackbar.showInfo(
          title: "Branch Notice",
          message: msg,
          duration: const Duration(seconds: 4),
        );
      } else {
        AppSnackbar.showSuccess(
          title: "Success",
          message: msg,
          duration: const Duration(seconds: 4),
        );
      }
      return true;
    } catch (e) {
      AppSnackbar.showError(
        title: "Error",
        message: e.toString(),
        duration: const Duration(seconds: 4),
      );
      return false;
    }
  }

  Future<void> cancelRequest(int branchId) async {
    try {
      final res = await SellerServices.cancelBranchRequest(branchId);
      pendingRequests.removeWhere((r) => r.id == branchId);
      await fetchBranches();
      pendingRequests.removeWhere((r) => r.id == branchId);
      AppSnackbar.showSuccess(
        title: "Success",
        message: res['message'] ?? "Request cancelled successfully",
      );
    } catch (e) {
      AppSnackbar.showError(
        title: "Error",
        message: e.toString(),
      );
    }
  }

  Future<void> leaveBranch(int branchId) async {
    try {
      _leftBranchIds.add(branchId);
      myBranches.removeWhere((b) => b.id == branchId);
      if (primaryBranch.value?.id == branchId) {
        primaryBranch.value = null;
      }
      final res = await SellerServices.leaveBranch(branchId);
      await fetchBranches();
      myBranches.removeWhere((b) => b.id == branchId);
      if (primaryBranch.value?.id == branchId) {
        primaryBranch.value = null;
      }
      AppSnackbar.showSuccess(
        title: "Success",
        message: res['message'] ?? "Left branch successfully",
      );
    } catch (e) {
      final err = e.toString();
      if (err.toLowerCase().contains("not added")) {
        _leftBranchIds.add(branchId);
        myBranches.removeWhere((b) => b.id == branchId);
        if (primaryBranch.value?.id == branchId) {
          primaryBranch.value = null;
        }
        AppSnackbar.showInfo(
          title: "Branch Notice",
          message: "You are not added to this branch.",
        );
      } else {
        _leftBranchIds.remove(branchId);
        await fetchBranches();
        AppSnackbar.showError(
          title: "Error",
          message: err,
        );
      }
    }
  }
}
