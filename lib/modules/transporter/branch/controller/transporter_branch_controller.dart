import '../../../../comman/api_url.dart';
import '../../../../network/api_client.dart';
import '../model/branch_model.dart';
import 'package:get/get.dart';
import '../../../../utils/app_snackbar.dart';

class TransporterBranchController extends GetxController {
  
  var branches = <BranchModel>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchBranches();
  }

  Future<void> fetchBranches() async {
    try {
      isLoading(true);
      final response = await ApiClient.get(
        endpoint: ApiUrls.publicBranches,
        requireAuth: true,
      );

      if (response != null) {
        List<dynamic> dataList = [];
        if (response is List) {
          dataList = response;
        } else if (response is Map && response.containsKey('data')) {
          dataList = response['data'];
        } else if (response is Map && response.containsKey('body')) {
          dataList = response['body'];
        }

        branches.value = dataList.map((json) => BranchModel.fromJson(json)).toList();
      }
    } catch (e) {
      AppSnackbar.snackbar('Error', 'Failed to load branches: $e', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading(false);
    }
  }

  Future<bool> requestBranchByCode(String code) async {
    if (code.trim().isEmpty) return false;
    
    try {
      final response = await ApiClient.post(
        endpoint: ApiUrls.requestBranchByCode,
        body: {'branch_code': code.trim()},
        requireAuth: true,
      );

      if (response != null) {
        AppSnackbar.snackbar('Success', 'Branch request sent to Super Admin!', snackPosition: SnackPosition.BOTTOM);
        await fetchBranches();
        return true;
      }
    } catch (e) {
      AppSnackbar.snackbar('Error', 'Failed to request branch: $e', snackPosition: SnackPosition.BOTTOM);
    }
    return false;
  }
}
