import 'package:get/get.dart';
import '../../../../services/seller_services.dart';
import '../../../../utils/app_snackbar.dart';
import '../../../seller/branches/model/seller_branch_model.dart';

class BuyerBranchController extends GetxController {
  var isLoading = false.obs;
  var primaryBranch = Rxn<SellerBranchModel>();
  var myBranches = <SellerBranchModel>[].obs;
  var pendingRequests = <SellerBranchModel>[].obs;

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
          primaryBranch.value = SellerBranchModel.fromJson(data['primary_branch']);
        } else {
          primaryBranch.value = null;
        }
        if (data['my_branches'] is List) {
          myBranches.value = (data['my_branches'] as List)
              .map((e) => SellerBranchModel.fromJson(e as Map<String, dynamic>))
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
      await fetchBranches();
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
      final res = await SellerServices.leaveBranch(branchId);
      await fetchBranches();
      AppSnackbar.showSuccess(
        title: "Success",
        message: res['message'] ?? "Left branch successfully",
      );
    } catch (e) {
      AppSnackbar.showError(
        title: "Error",
        message: e.toString(),
      );
    }
  }
}
