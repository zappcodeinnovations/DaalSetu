import 'package:get/get.dart';
import 'package:daalsetu/network/api_client.dart';

class BranchModel {
  final int id;
  final String branchCode;
  final String locationName;
  final String city;
  final String state;
  final bool isPrimary;

  BranchModel({
    required this.id,
    required this.branchCode,
    required this.locationName,
    required this.city,
    required this.state,
    required this.isPrimary,
  });

  factory BranchModel.fromJson(Map<String, dynamic> json) {
    return BranchModel(
      id: json['id'] as int? ?? 0,
      branchCode: json['branch_code'] as String? ?? '',
      locationName: json['location_name'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      isPrimary: json['is_primary'] as bool? ?? false,
    );
  }
}

class BranchController extends GetxController {
  var isLoading = false.obs;
  var myBranches = <BranchModel>[].obs;
  var primaryBranch = Rxn<BranchModel>();

  @override
  void onInit() {
    super.onInit();
    fetchBranches();
  }

  Future<void> fetchBranches() async {
    isLoading(true);
    try {
      final response = await ApiClient.get(
        endpoint: '/api/seller/branches/',
        requireAuth: true,
      );

      if (response is Map && response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>?;
        if (data != null) {
          if (data['primary_branch'] != null) {
            primaryBranch.value = BranchModel.fromJson(data['primary_branch'] as Map<String, dynamic>);
          }
          final list = data['my_branches'] as List? ?? [];
          myBranches.assignAll(list.map((e) => BranchModel.fromJson(e as Map<String, dynamic>)).toList());
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load branches');
    } finally {
      isLoading(false);
    }
  }
}
