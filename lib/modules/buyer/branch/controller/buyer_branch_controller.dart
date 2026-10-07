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

  Future<void> fetchBranches({bool clearLeftCache = false}) async {
    if (clearLeftCache) {
      _leftBranchIds.clear();
    }
    try {
      isLoading.value = true;
      final res = await SellerServices.getSellerBranches();
      if (res['data'] is Map<String, dynamic>) {
        final data = res['data'] as Map<String, dynamic>;

        // 1. Parse Pending Requests first
        final rawPending = data['pending_requests'] is List ? (data['pending_requests'] as List) : [];
        final parsedPending = rawPending
            .map((e) => SellerBranchModel.fromJson(e as Map<String, dynamic>))
            .toList();
        pendingRequests.value = parsedPending;

        final pendingBranchIds = <int>{};
        final pendingCodes = <String>{};

        for (final p in rawPending) {
          if (p is Map<String, dynamic>) {
            if (p['branch_id'] is int) pendingBranchIds.add(p['branch_id'] as int);
            if (p['id'] is int) pendingBranchIds.add(p['id'] as int);
            final code = (p['branch_code'] ?? p['code'])?.toString().trim().toUpperCase();
            if (code != null && code.isNotEmpty) pendingCodes.add(code);
          }
        }

        // 2. Parse Primary Branch
        if (data['primary_branch'] is Map<String, dynamic>) {
          final pb = SellerBranchModel.fromJson(data['primary_branch']);
          final code = pb.branchCode?.trim().toUpperCase();
          final isLeft = pb.id != null && _leftBranchIds.contains(pb.id);
          final isPending = (pb.id != null && pendingBranchIds.contains(pb.id)) ||
              (code != null && pendingCodes.contains(code));
          if (!isLeft && !isPending) {
            primaryBranch.value = pb;
          } else {
            primaryBranch.value = null;
          }
        } else {
          primaryBranch.value = null;
        }

        // 3. Parse My Branches (exclude any branch that is pending or has been left)
        if (data['my_branches'] is List) {
          myBranches.value = (data['my_branches'] as List)
              .map((e) => SellerBranchModel.fromJson(e as Map<String, dynamic>))
              .where((b) {
                if (b.id == null) return false;
                if (_leftBranchIds.contains(b.id)) return false;
                if (pendingBranchIds.contains(b.id)) return false;
                final code = b.branchCode?.trim().toUpperCase();
                if (code != null && pendingCodes.contains(code)) return false;
                return true;
              })
              .toList();
        } else {
          myBranches.clear();
        }
      }
    } catch (e) {
      AppSnackbar.showError(title: "Error", message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> joinBranchByCode(String code) async {
    final cleanCode = code.trim();
    if (cleanCode.isEmpty) return false;
    try {
      final res = await SellerServices.requestBranchByCode(cleanCode);
      _leftBranchIds.clear(); // Reset left filter so newly joined or approved branch shows immediately
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

  Future<void> cancelRequest(int branchOrReqId, {int? branchId}) async {
    try {
      final targetId = branchId ?? branchOrReqId;
      final res = await SellerServices.cancelBranchRequest(targetId);
      _leftBranchIds.add(targetId);
      if (branchId != null) _leftBranchIds.add(branchOrReqId);

      pendingRequests.removeWhere((r) =>
          r.id == branchOrReqId ||
          r.id == targetId ||
          (r.branchId != null && r.branchId == targetId));
      await fetchBranches();
      pendingRequests.removeWhere((r) =>
          r.id == branchOrReqId ||
          r.id == targetId ||
          (r.branchId != null && r.branchId == targetId));
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
