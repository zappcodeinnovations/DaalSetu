import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../services/seller_services.dart';
import '../../../../utils/app_snackbar.dart';
import '../../../seller/branches/model/seller_branch_model.dart';

class BuyerBranchController extends GetxController {
  var isLoading = false.obs;
  var primaryBranch = Rxn<SellerBranchModel>();
  var myBranches = <SellerBranchModel>[].obs;
  var pendingRequests = <SellerBranchModel>[].obs;

  static const String _leftBranchIdsKey = "buyer_left_branch_ids";
  static const String _leftBranchCodesKey = "buyer_left_branch_codes";

  final Set<int> _leftBranchIds = {};
  final Set<String> _leftBranchCodes = {};

  @override
  void onInit() {
    super.onInit();
    _initController();
  }

  Future<void> _initController() async {
    await _loadLeftBranches();
    await fetchBranches();
  }

  Future<void> _loadLeftBranches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList(_leftBranchIdsKey) ?? [];
      _leftBranchIds.addAll(ids.map((e) => int.tryParse(e)).whereType<int>());
      final codes = prefs.getStringList(_leftBranchCodesKey) ?? [];
      _leftBranchCodes.addAll(codes.map((e) => e.toUpperCase()));
    } catch (_) {}
  }

  Future<void> _saveLeftBranches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _leftBranchIdsKey,
        _leftBranchIds.map((e) => e.toString()).toList(),
      );
      await prefs.setStringList(
        _leftBranchCodesKey,
        _leftBranchCodes.toList(),
      );
    } catch (_) {}
  }

  Future<void> fetchBranches() async {
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
          final isLeft = (pb.id != null && _leftBranchIds.contains(pb.id)) ||
              (code != null && _leftBranchCodes.contains(code));
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
                final code = b.branchCode?.trim().toUpperCase();
                if (_leftBranchIds.contains(b.id)) return false;
                if (code != null && _leftBranchCodes.contains(code)) return false;
                if (pendingBranchIds.contains(b.id)) return false;
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
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) return false;
    try {
      // User explicitly requests this branch, so remove from left sets
      _leftBranchCodes.remove(cleanCode);
      for (final b in myBranches) {
        if (b.branchCode?.trim().toUpperCase() == cleanCode && b.id != null) {
          _leftBranchIds.remove(b.id);
        }
      }
      for (final p in pendingRequests) {
        if (p.branchCode?.trim().toUpperCase() == cleanCode) {
          if (p.id != null) _leftBranchIds.remove(p.id);
          if (p.branchId != null) _leftBranchIds.remove(p.branchId);
        }
      }
      await _saveLeftBranches();

      final res = await SellerServices.requestBranchByCode(cleanCode);
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

  Future<void> cancelRequest(int branchOrReqId, {int? branchId, String? branchCode}) async {
    try {
      final targetId = branchId ?? branchOrReqId;
      final res = await SellerServices.cancelBranchRequest(targetId);
      _leftBranchIds.add(targetId);
      if (branchId != null) _leftBranchIds.add(branchOrReqId);
      if (branchCode != null && branchCode.isNotEmpty) {
        _leftBranchCodes.add(branchCode.trim().toUpperCase());
      }
      await _saveLeftBranches();

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

  Future<void> leaveBranch(int branchId, {String? branchCode}) async {
    try {
      _leftBranchIds.add(branchId);
      if (branchCode != null && branchCode.isNotEmpty) {
        _leftBranchCodes.add(branchCode.trim().toUpperCase());
      }
      await _saveLeftBranches();

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
        if (branchCode != null && branchCode.isNotEmpty) {
          _leftBranchCodes.add(branchCode.trim().toUpperCase());
        }
        await _saveLeftBranches();
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
        if (branchCode != null && branchCode.isNotEmpty) {
          _leftBranchCodes.remove(branchCode.trim().toUpperCase());
        }
        await _saveLeftBranches();
        await fetchBranches();
        AppSnackbar.showError(
          title: "Error",
          message: err,
        );
      }
    }
  }
}
