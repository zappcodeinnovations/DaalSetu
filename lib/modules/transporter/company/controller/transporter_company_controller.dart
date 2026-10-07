import '../../../../comman/api_url.dart';
import '../model/company_model.dart';
import '../../../../network/api_client.dart';
import 'package:get/get.dart';

class TransporterCompanyController extends GetxController {
  var companies = <CompanyModel>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCompanies();
  }

  Future<void> fetchCompanies() async {
    try {
      isLoading(true);
      final response = await ApiClient.get(
        endpoint: ApiUrls.company,
        requireAuth: true,
      );

      final List<dynamic> data;
      if (response is List) {
        data = response;
      } else if (response is Map && response['results'] is List) {
        data = response['results'] as List;
      } else if (response is Map && response['data'] is List) {
        data = response['data'] as List;
      } else {
        data = const [];
      }
      companies.value = data
          .whereType<Map>()
          .map((json) => CompanyModel.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load companies: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading(false);
    }
  }

  Future<CompanyModel?> fetchCompanyDetails(int id) async {
    try {
      final response = await ApiClient.get(
        endpoint: ApiUrls.companyDetails(id),
        requireAuth: true,
      );

      if (response['id'] != null) {
        return CompanyModel.fromJson(response);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load company details: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
    return null;
  }

  Future<bool> createCompany(Map<String, dynamic> data) async {
    try {
      final response = await ApiClient.post(
        endpoint: ApiUrls.company,
        body: data,
        requireAuth: true,
      );

      if (response['id'] != null) {
        Get.snackbar(
          'Success',
          'Company created successfully',
          snackPosition: SnackPosition.BOTTOM,
        );
        await fetchCompanies();
        return true;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to create company: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
    return false;
  }

  Future<bool> updateCompany(int id, Map<String, dynamic> data) async {
    try {
      // Assuming patch method is available or using post with specific headers if not
      final response = await ApiClient.patch(
        endpoint: ApiUrls.companyDetails(id),
        data: data,
        requireAuth: true,
      );

      if (response['id'] != null) {
        Get.snackbar(
          'Success',
          'Company updated successfully',
          snackPosition: SnackPosition.BOTTOM,
        );
        await fetchCompanies();
        return true;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update company: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
    return false;
  }

  Future<void> deleteCompany(int id) async {
    try {
      await ApiClient.delete(
        endpoint: ApiUrls.companyDetails(id),
        requireAuth: true,
      );

      Get.snackbar(
        'Success',
        'Company deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
      await fetchCompanies();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete company: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> setPrimaryCompany(int id) async {
    try {
      await ApiClient.post(
        endpoint: ApiUrls.setPrimaryCompany(id),
        body: {},
        requireAuth: true,
      );

      Get.snackbar(
        'Success',
        'Primary company updated',
        snackPosition: SnackPosition.BOTTOM,
      );
      await fetchCompanies();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to set primary company: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
